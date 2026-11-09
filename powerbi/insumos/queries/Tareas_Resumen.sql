-- Origen: SQL Server | Base: Aranda Service Management (ASMS 9.5.57)
-- Tabla en Power BI: Tareas_Resumen
-- Descripción: Resumen general de tareas y el caso padre al que pertenecen
-- Parámetros: @proyecto, @fechaini, @fechafin
-- Llave hacia Casos: num_caso (= Casos_Resumen[03_Numero_de_Caso]) + tipo_caso
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
        and  project_id = @proyecto
        AND DATEADD(HOUR,-5, it.opened_date)
            BETWEEN @fechaini AND @fechafin

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
        and  project_id = @proyecto
        AND DATEADD(HOUR,-5, it.opened_date)
            BETWEEN @fechaini AND @fechafin
)

SELECT
     CASE i.type_id
        WHEN 1 THEN 'Incidente'
        WHEN 4 THEN 'Requerimiento'
        WHEN 3 THEN 'Cambio'
        WHEN 2 THEN 'problema'
        ELSE 'Otro'
    END                               AS tipo_caso,
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
    t.rn = 1;
