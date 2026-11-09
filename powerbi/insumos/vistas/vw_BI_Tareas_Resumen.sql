-- Vista para Power BI: vw_BI_Tareas_Resumen
-- Resumen general de tareas con su caso padre
-- Basada en powerbi/insumos/queries/Tareas_Resumen.sql, migrada a la tabla principal adw.FACT_ASDK_ITEM
-- (ASDK_ITEM_DW_LAST está obsoleta según Aranda).
-- Cambios frente a la query original:
--   * Origen: adw.FACT_ASDK_ITEM (tarea y caso padre) + ASMS_STATUS / AFW_GROUPS / AFW_USERS para los nombres
--     + adw.DIM_ASDK_ITEM_TEXT para el asunto de la tarea.
--   * Se quitan los filtros @proyecto / @fechaini / @fechafin (se filtra en Power BI).
--   * Se agregan caso_id (relación con Casos_Resumen[id]), tarea_id y proyecto.
--   * Cumplimiento con el cronómetro 'Solution' de la tarea (real > estimado = No Cumple). Si la tarea no tiene
--     cronómetro se usa current_progress como respaldo, igual que la query original.
--   * Tiempos de la tarea en minutos. Fechas en hora Colombia (-5 h).
--   * Se mantiene el filtro original item_type_sk NOT IN (1,4) (excluye incidentes y requerimientos como "tarea").
--     OJO: deja pasar problemas (2) y cambios (3); si solo se quieren tareas, cambiar a NOT IN (1,2,3,4).
-- Ejecutar en SSMS sobre la base de Aranda (ASMS) con un usuario que tenga permiso CREATE VIEW (DBA).
CREATE OR ALTER VIEW bi.vw_BI_Tareas_Resumen
AS
WITH REL AS (
    SELECT source_id, target_id FROM ASDK_ITEM_RELATION
    UNION ALL
    SELECT source_id, target_id FROM ASDK_ITEM_RELATION_CLOSED
),
CRON_BASE AS (
    SELECT td.item_id, td.sdb_current_time, td.estimated_time,
           ROW_NUMBER() OVER (PARTITION BY td.item_id ORDER BY td.sdb_current_time DESC) AS rn
    FROM (
        SELECT item_id, time_id, sdb_current_time, estimated_time FROM ASMS_TIMES_DATA
        UNION ALL
        SELECT item_id, time_id, sdb_current_time, estimated_time FROM ASMS_TIMES_DATA_CLOSED
    ) td
    JOIN ASMS_TIMES t ON t.id = td.time_id
    WHERE t.name = 'Solution'
),
TAREAS AS (
    SELECT
        ta.id                AS tarea_id,
        ta.id_by_project     AS num_tarea,
        ta.status_sk,
        ta.specialist_group_sk,
        ta.specialist_user_sk,
        ta.opened_date,
        ta.closed_date,
        ta.current_progress,
        cr.estimated_time    AS sol_est_min,
        cr.sdb_current_time  AS sol_real_min,
        r.source_id          AS caso_id,
        ROW_NUMBER() OVER (PARTITION BY ta.id ORDER BY ta.closed_date DESC) AS rn
    FROM REL r
    INNER JOIN adw.FACT_ASDK_ITEM ta ON ta.id = r.target_id
    LEFT JOIN CRON_BASE cr          ON cr.item_id = ta.id AND cr.rn = 1
    WHERE ta.item_type_sk NOT IN (1, 4)
)
SELECT
    CASE ca.item_type_sk
        WHEN 1 THEN 'Incidente'
        WHEN 2 THEN 'Problema'
        WHEN 3 THEN 'Cambio'
        WHEN 4 THEN 'Requerimiento'
        ELSE 'Otro'
    END                                       AS tipo_caso,
    ca.id                                     AS caso_id,
    ca.id_by_project                          AS num_caso,
    p.proj_name                               AS proyecto,
    stc.stat_name                             AS estado_caso,
    gc.grou_name                              AS grupo_caso,
    ec.user_name                              AS especialista_caso,
    cli.user_name                             AS cliente,
    t.tarea_id,
    t.num_tarea,
    dtt.subject                               AS nombre_tarea,
    stt.stat_name                             AS estado_tarea,
    DATEADD(HOUR, -5, t.opened_date)          AS fecha_registro_tarea,
    DATEADD(HOUR, -5, t.closed_date)          AS fecha_cierre_tarea,
    gt.grou_name                              AS grupo_tarea,
    et.user_name                              AS especialista_tarea,
    ROUND(t.sol_est_min, 2)                   AS tiempo_estimado_tarea_min,
    ROUND(t.sol_real_min, 2)                  AS tiempo_real_tarea_min,
    CASE
        WHEN t.sol_est_min > 0 THEN CASE WHEN t.sol_real_min > t.sol_est_min THEN 'No Cumple' ELSE 'Si Cumple' END
        WHEN t.current_progress > 100 THEN 'No Cumple'          -- respaldo: tarea sin cronómetro
        ELSE 'Si Cumple'
    END                                       AS cumplimiento_tarea
FROM TAREAS t
INNER JOIN adw.FACT_ASDK_ITEM ca      ON ca.id = t.caso_id
LEFT JOIN ASMS_PROJECTS p             ON p.proj_id = ca.project_sk
LEFT JOIN ASMS_STATUS stc             ON stc.stat_id = ca.status_sk
LEFT JOIN AFW_GROUPS gc               ON gc.grou_id = ca.specialist_group_sk
LEFT JOIN AFW_USERS ec                ON ec.user_id = ca.specialist_user_sk
LEFT JOIN AFW_USERS cli               ON cli.user_id = ca.customer_user_sk
LEFT JOIN adw.DIM_ASDK_ITEM_TEXT dtt  ON dtt.item_sk = t.tarea_id AND dtt.is_current = 1
LEFT JOIN ASMS_STATUS stt             ON stt.stat_id = t.status_sk
LEFT JOIN AFW_GROUPS gt               ON gt.grou_id = t.specialist_group_sk
LEFT JOIN AFW_USERS et                ON et.user_id = t.specialist_user_sk
WHERE t.rn = 1
GO
