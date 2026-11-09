-- Vista para Power BI: vw_BI_Casos_Especialista
-- Tablero por especialista (ANS, vencidos, campos adicionales de compañía)
-- Basada en powerbi/insumos/queries/Casos_Especialista.sql, migrada a la tabla principal adw.FACT_ASDK_ITEM
-- (ASDK_ITEM_DW_LAST está obsoleta según Aranda).
-- Cambios frente a la query original:
--   * Origen: adw.FACT_ASDK_ITEM (+ adw.DIM_ASDK_ITEM_TEXT para asunto, descripción, solución y causa).
--   * Se quitan los filtros fijos de proyecto y fecha de corte (se filtra en Power BI por PROYECTO y periodo).
--   * FECHA REGISTRO / CIERRE / MODIFICACION / CORREO en hora Colombia (-5 h).
--   * Semáforo ANS calculado con los cronómetros (no con current_progress, que queda congelado):
--       PCT_ANS = tiempo real / tiempo estimado del cronómetro 'Solution' × 100
--       SEMAFORO_ANS = No aplica | Dentro de SLA (≤ 80 %) | Por vencer (81–100 %, abierto) | Vencido abierto | Vencido cerrado
--     Reemplaza las columnas PROGRESO, VENCIDOS CERRADOS y VENCIDOS ABIERTOS.
--   * Tiempos en minutos (minutos hábiles del cronómetro). La conversión a horas/días se hace en Power BI.
--   * "Abierto/cerrado" se toma de state_final (1 = estado final), no de nombres de estado.
-- Verificar al ejecutar: si dt.cause_nohtml no existe en DIM_ASDK_ITEM_TEXT de esta versión, borrar esa línea.
-- Ejecutar en SSMS sobre la base de Aranda (ASMS) con un usuario que tenga permiso CREATE VIEW (DBA).
CREATE OR ALTER VIEW bi.vw_BI_Casos_Especialista
AS
WITH ADICIONALES_TC AS (
    SELECT fd.string_value AS VALOR_STRING, fd.item_id AS ID_COMPANY, f.name AS NOMBRE
    FROM ASMS_FIELDS_DATA fd
    LEFT JOIN ASMS_FIELDS f ON f.id = fd.field_id
    UNION ALL
    SELECT fd.string_value, fd.item_id, f.name
    FROM ASMS_FIELDS_DATA_CLOSED fd
    LEFT JOIN ASMS_FIELDS f ON f.id = fd.field_id
),
CRON_BASE AS (
    SELECT td.item_id, t.name, td.sdb_current_time, td.estimated_time, td.end_date,
           ROW_NUMBER() OVER (PARTITION BY td.item_id, t.name ORDER BY td.sdb_current_time DESC) AS rn
    FROM (
        SELECT item_id, time_id, sdb_current_time, estimated_time, end_date FROM ASMS_TIMES_DATA
        UNION ALL
        SELECT item_id, time_id, sdb_current_time, estimated_time, end_date FROM ASMS_TIMES_DATA_CLOSED
    ) td
    JOIN ASMS_TIMES t ON t.id = td.time_id
    WHERE t.name IN ('Attention', 'Solution')
),
CRON AS (
    SELECT item_id,
           MAX(CASE WHEN name = 'Attention' THEN estimated_time END)    AS at_est_min,
           MAX(CASE WHEN name = 'Attention' THEN sdb_current_time END)  AS at_real_min,
           MAX(CASE WHEN name = 'Attention' THEN end_date END)          AS at_fin,
           MAX(CASE WHEN name = 'Solution'  THEN estimated_time END)    AS sol_est_min,
           MAX(CASE WHEN name = 'Solution'  THEN sdb_current_time END)  AS sol_real_min,
           MAX(CASE WHEN name = 'Solution'  THEN end_date END)          AS sol_fin
    FROM CRON_BASE
    WHERE rn = 1
    GROUP BY item_id
),
BASE AS (
    SELECT
        caso.*,
        c.at_est_min, c.at_real_min, c.at_fin, c.sol_est_min, c.sol_real_min, c.sol_fin,
        CASE WHEN c.sol_est_min > 0 THEN c.sol_real_min * 100.0 / c.sol_est_min END AS pct_ans
    FROM adw.FACT_ASDK_ITEM caso
    LEFT JOIN CRON c ON c.item_id = caso.id
)
SELECT
    caso.id                                        AS "ID",
    caso.id_by_project                             AS "NRO. TICKET",
    dt.subject                                     AS "ASUNTO",
    ty.name                                        AS "TIPO DE CASO",
    st.stat_name                                   AS "ESTADO",
    p.proj_name                                    AS "PROYECTO",
    rs.reas_description                            AS "RAZON",
    ctg.ctg_caption                                AS "CATEGORIA",
    sv.name                                        AS "SERVICIO",
    imp.code_value                                 AS "IMPACTO",
    urg.code_value                                 AS "URGENCIA",
    pri.code_value                                 AS "PRIORIDAD",
    reg.code_value                                 AS "TIPO DE REGISTRO",
    dt.description_nohtml                          AS "DESCRIPCION",
    g.grou_name                                    AS "GRUPO ESPECIALISTA",
    esp.user_name                                  AS "ESPECIALISTA",
    cli.user_name                                  AS "CLIENTE FINAL",
    aut.user_name                                  AS "AUTOR DE TICKET",
    comp.Name                                      AS "COMPANIA",
    ci.name                                        AS "CI ASOCIADO",
    modi.user_name                                 AS "ULT. ESPECIALISTA MODIFICADOR",
    rec.user_name                                  AS "1ER ESPECIALISTA ASIGNADO",
    DATEADD(HOUR, -5, caso.opened_date)            AS "FECHA REGISTRO",
    DATEADD(HOUR, -5, caso.closed_date)            AS "FECHA CIERRE",
    DATEADD(HOUR, -5, caso.modified_date)          AS "FECHA DE MODIFICACION",
    DATEADD(HOUR, -5, caso.created_date)           AS "FECHA DE CORREO",
    dt.commentary_nohtml                           AS "SOLUCION",
    dt.cause_nohtml                                AS "CAUSA",
    cal.CALENDAR_NAME                              AS "SLA CALENDARIO",
    mo.name                                        AS "MODELO",
    sla.NAME                                       AS "SLA",
    adtc.VALOR_STRING                              AS "Código Municipio",
    adtc1.VALOR_STRING                             AS "Tipo Entidad",
    caso.state_final                               AS "ESTADO FINAL",          -- 1 = cerrado/final
    ROUND(caso.at_est_min, 2)                      AS "TIEMPO ATENCION ESTIMADO MIN",
    ROUND(caso.at_real_min, 2)                     AS "TIEMPO ATENCION REAL MIN",
    DATEADD(HOUR, -5, caso.at_fin)                 AS "FECHA ATENCION REAL",
    ROUND(caso.sol_est_min, 2)                     AS "TIEMPO SOLUCION ESTIMADO MIN",
    ROUND(caso.sol_real_min, 2)                    AS "TIEMPO SOLUCION REAL MIN",
    DATEADD(HOUR, -5, caso.sol_fin)                AS "FECHA SOLUCION REAL",
    ROUND(caso.pct_ans, 2)                         AS "PCT_ANS",
    CASE
        WHEN caso.pct_ans IS NULL
          OR (ISNULL(caso.sol_real_min, 0) = 0 AND caso.state_final = 1) THEN 'No aplica'
        WHEN caso.pct_ans > 100 AND caso.state_final = 1                   THEN 'Vencido cerrado'
        WHEN caso.pct_ans > 100                                            THEN 'Vencido abierto'
        WHEN caso.pct_ans > 80  AND ISNULL(caso.state_final, 0) = 0        THEN 'Por vencer'
        ELSE 'Dentro de SLA'
    END                                            AS "SEMAFORO_ANS",
    CASE
        WHEN caso.pct_ans IS NULL
          OR (ISNULL(caso.sol_real_min, 0) = 0 AND caso.state_final = 1) THEN 'No aplica'
        WHEN caso.pct_ans > 100                                            THEN 'No cumple'
        ELSE 'Cumple'
    END                                            AS "CUMPLE_ANS"
FROM BASE caso
LEFT JOIN adw.DIM_ASDK_ITEM_TEXT dt  ON dt.item_sk = caso.id AND dt.is_current = 1
LEFT JOIN ASMS_TYPES ty              ON ty.id = caso.item_type_sk
LEFT JOIN ASMS_STATUS st             ON st.stat_id = caso.status_sk
LEFT JOIN ASMS_PROJECTS p            ON p.proj_id = caso.project_sk
LEFT JOIN ASMS_STATUS_REASON rs      ON rs.reas_id = caso.reason_sk
LEFT JOIN ASDK_CATEGORY ctg          ON ctg.ctg_index = caso.category_sk
LEFT JOIN ASDK_SERVICE sv            ON sv.id = caso.service_sk
LEFT JOIN AFW_CATALOG_CODE imp       ON imp.code_id = caso.impact_sk
LEFT JOIN AFW_CATALOG_CODE urg       ON urg.code_id = caso.urgency_sk
LEFT JOIN AFW_CATALOG_CODE pri       ON pri.code_id = caso.priority_sk
LEFT JOIN AFW_CATALOG_CODE reg       ON reg.code_id = caso.registry_type_sk
LEFT JOIN AFW_GROUPS g               ON g.grou_id = caso.specialist_group_sk
LEFT JOIN AFW_USERS esp              ON esp.user_id = caso.specialist_user_sk
LEFT JOIN AFW_USERS cli              ON cli.user_id = caso.customer_user_sk
LEFT JOIN AFW_USERS aut              ON aut.user_id = caso.author_user_sk
LEFT JOIN AFW_USERS modi             ON modi.user_id = caso.modifier_user_sk
LEFT JOIN AFW_USERS rec              ON rec.user_id = caso.receptor_user_sk
LEFT JOIN ASMS_COMPANY comp          ON comp.Id = caso.company_sk
LEFT JOIN CMDB_CI ci                 ON ci.id = caso.ci_sk
LEFT JOIN ASMS_CALENDAR cal          ON cal.CALENDAR_ID = caso.calendar_sla_sk
LEFT JOIN ASMS_MODEL mo              ON mo.id = caso.model_sk
LEFT JOIN ASDK_SLA sla               ON sla.SLA_ID = caso.sla_sk
LEFT JOIN ADICIONALES_TC adtc        ON adtc.ID_COMPANY = caso.company_sk AND adtc.NOMBRE = 'Código Municipio'
LEFT JOIN ADICIONALES_TC adtc1       ON adtc1.ID_COMPANY = caso.company_sk AND adtc1.NOMBRE = 'Tipo Entidad'
-- WHERE caso.opened_date >= '<FECHA_CORTE>'   -- opcional: fecha de corte (UTC) si el cliente no quiere historia antigua
--   AND caso.item_type_sk IN (1, 2, 3, 4)     -- opcional: descomentar si aparecen tareas u otros ítems que no son casos
GO
