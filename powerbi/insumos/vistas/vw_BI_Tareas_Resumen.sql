-- Vista para Power BI: vw_BI_Tareas_Resumen
-- Resumen general de tareas con su caso padre
-- Generada a partir de powerbi/insumos/queries/Tareas_Resumen.sql
-- Cambios frente a la query original: se quitan los filtros @proyecto/@fechaini/@fechafin; se agregan caso_id (relación con Casos_Resumen[id]) y proyecto_id.
-- ⚠ Usa dbo.ASDK_ITEM_DW_LAST, que Aranda marca como OBSOLETA: migrar a adw.FACT_ASDK_ITEM + adw.DIM_ASDK_ITEM_TEXT (ver manual, sección 1).
-- Ejecutar en SSMS sobre la base de Aranda con un usuario que tenga permiso CREATE VIEW (DBA).
CREATE OR ALTER VIEW bi.vw_BI_Tareas_Resumen
AS
WITH tareas AS (

    SELECT
        it.id                         AS tarea_id,
        it.id_by_project              AS num_tarea,
        it.subject                    AS nombre_tarea,
        it.state_name                 AS estado_tarea,
        it.responsible_name           AS especialista_tarea,
        it.group_name                 AS grupo_tarea,
        DATEADD(HOUR,-5, it.opened_date) AS fecha_registro_tarea,
        CASE
            WHEN it.current_progress > 100 THEN 'No Cumple'
            ELSE 'Si Cumple'
        END                           AS cumplimiento_tarea,
        ir.source_id                  AS caso_id,
        ROW_NUMBER() OVER (
            PARTITION BY it.id
            ORDER BY it.closed_date DESC
        ) AS rn
    FROM ASDK_ITEM_RELATION ir
    INNER JOIN ASDK_ITEM_DW_LAST it
        ON it.id = ir.target_id
    WHERE
        it.type_id NOT IN (1,4)

    UNION ALL

    SELECT
        it.id,
        it.id_by_project,
        it.subject,
        it.state_name,
        it.responsible_name,
        it.group_name,
        DATEADD(HOUR,-5, it.opened_date),
        CASE
            WHEN it.current_progress > 100 THEN 'No Cumple'
            ELSE 'Si Cumple'
        END,
        ir.source_id,
        ROW_NUMBER() OVER (
            PARTITION BY it.id
            ORDER BY it.closed_date DESC
        )
    FROM ASDK_ITEM_RELATION_CLOSED ir
    INNER JOIN ASDK_ITEM_DW_LAST it
        ON it.id = ir.target_id
    WHERE
        it.type_id NOT IN (1,4)
)

SELECT
     CASE i.type_id
        WHEN 1 THEN 'Incidente'
        WHEN 4 THEN 'Requerimiento'
        WHEN 3 THEN 'Cambio'
        WHEN 2 THEN 'problema'
        ELSE 'Otro'
    END                               AS tipo_caso,
    i.id                              AS caso_id,
    i.project_id                      AS proyecto_id,
    i.id_by_project                   AS num_caso,
    i.state_name                      AS estado_caso,
    i.group_name                      AS grupo_caso,
    i.responsible_name                AS especialista_caso,
    i.customer_name                   AS cliente,
    t.num_tarea,
    t.nombre_tarea,
    t.estado_tarea,
    t.fecha_registro_tarea,
    t.grupo_tarea,
    t.especialista_tarea,
    t.cumplimiento_tarea
FROM tareas t
INNER JOIN ASDK_ITEM_DW_LAST i
    ON i.id = t.caso_id
WHERE
    t.rn = 1
GO
