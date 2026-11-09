-- Origen: SQL Server | Base: Aranda Service Management (ASMS 9.5.57)
-- Tabla en Power BI: Casos_Especialista
-- Descripción: Tablero por especialista (estado de SLA, vencidos, campos adicionales de compañía)
-- Filtros fijos: nombre del proyecto y fecha de corte (reemplazar <PROYECTO> y <FECHA_CORTE> en cada cliente)
-- NOTA: las fechas de esta query están en UTC (no restan 5 horas como las demás).
WITH ADICIONALES_TC AS (
    SELECT
        ASMS_FIELDS_DATA.string_value AS VALOR_STRING,
        ASMS_FIELDS_DATA.item_id AS ID_COMPANY,
        ASMS_FIELDS.NAME AS NOMBRE
    FROM ASMS_FIELDS_DATA
    LEFT OUTER JOIN ASMS_FIELDS ON ASMS_FIELDS.id = ASMS_FIELDS_DATA.field_id
    UNION ALL
    SELECT
        ASMS_FIELDS_DATA_CLOSED.string_value AS VALOR_STRING,
        ASMS_FIELDS_DATA_CLOSED.item_id AS ID_COMPANY,
        ASMS_FIELDS.NAME AS NOMBRE
    FROM ASMS_FIELDS_DATA_CLOSED
    LEFT OUTER JOIN ASMS_FIELDS ON ASMS_FIELDS.id = ASMS_FIELDS_DATA_CLOSED.field_id
)
SELECT
    "ASDK_ITEM_DW_LAST"."id_by_project" AS "NRO. TICKET",
    "ASDK_ITEM_DW_LAST"."subject" AS "ASUNTO",
    "TIPO DE CASO"."name" AS "TIPO DE CASO",
    "ESTADO"."stat_name" AS "ESTADO",
    "ASMS_PROJECTS"."proj_name" AS "PROYECTO",
    "ASMS_STATUS_REASON"."reas_description" AS "RAZON",
    "ASDK_CATEGORY"."ctg_caption" AS "CATEGORIA",
    "ASDK_SERVICE"."name" AS "SERVICIO",
    "IMPACTO"."code_value" AS "IMPACTO",
    "URGENCIA"."code_value" AS "URGENCIA",
    "PRIORIDAD"."code_value" AS "PRIORIDAD",
    "TIPO DE REGISTRO"."code_value" AS "TIPO DE REGISTRO",
    "ASDK_ITEM_DW_LAST"."description_nohtml" AS "DESCRIPCION",
    "AFW_GROUPS"."grou_name" AS "GRUPO ESPECIALISTA",
    "ESPECIALISTA"."user_name" AS "ESPECIALISTA",
    "CLIENTE FINAL"."user_name" AS "CLIENTE FINAL",
    "AUTOR DE TICKET"."user_name" AS "AUTOR DE TICKET",
    "COMPANIA"."Name" AS "COMPANIA",
    "CMDB_CI"."name" AS "CI ASOCIADO",
    "ULT. ESPECIALISTA MODIFICADOR"."user_name" AS "ULT. ESPECIALISTA MODIFICADOR",
    "1ER ESPECIALISTA ASIGNADO"."user_name" AS "1ER ESPECIALISTA ASIGNADO",
    "ASDK_ITEM_DW_LAST"."opened_date" AS "FECHA REGISTRO",
    "ASDK_ITEM_DW_LAST"."closed_date" AS "FECHA CIERRE",
    "ASDK_ITEM_DW_LAST"."modified_date" AS "FECHA DE MODIFICACION",
    "ASDK_ITEM_DW_LAST"."created_date" AS "FECHA DE CORREO",
    "ASDK_ITEM_DW_LAST"."commentary_nohtml" AS "SOLUCION",
    "ASDK_ITEM_DW_LAST"."cause_nohtml" AS "CAUSA",
    "ASMS_CALENDAR"."CALENDAR_NAME" AS "SLA CALENDARIO",
    "MODELO"."name" AS "MODELO",
    "SLA"."NAME" AS "SLA",
    "ADTC"."VALOR_STRING" AS "Código Municipio",
    "ADTC1"."VALOR_STRING" AS "Tipo Entidad",
    "ASDK_ITEM_DW_LAST"."current_progress",
    "ASDK_ITEM_DW_LAST"."current_time",
    CASE
       -- WHEN "ASDK_ITEM_DW_LAST"."current_progress" >= 101 THEN 'VENCIDOS'
        WHEN "ASDK_ITEM_DW_LAST"."current_progress" <= 80 THEN 'Dentro de SLA'
        WHEN "ASDK_ITEM_DW_LAST"."current_progress" BETWEEN 81 AND 100 AND "ESTADO"."stat_name" NOT IN ('Cerrado', 'Resuelto') THEN 'POR VENCER'
    END AS "PROGRESO",
    CASE
        WHEN "ASDK_ITEM_DW_LAST"."current_progress" >= 101 AND "ESTADO"."stat_name" = 'Cerrado'
        THEN 'VENCIDOS CERRADOS'
        ELSE NULL
    END AS "VENCIDOS CERRADOS",
    CASE
        WHEN "ASDK_ITEM_DW_LAST"."current_progress" >= 101 AND "ESTADO"."stat_name" IN ('Registrado', 'Asignado', 'Resuelto')
        THEN 'VENCIDOS ABIERTOS'
        ELSE NULL
    END AS "VENCIDOS ABIERTOS"
FROM
    "dbo"."ASDK_ITEM_DW_LAST" AS "ASDK_ITEM_DW_LAST"
LEFT JOIN "dbo"."ASMS_LOCATION" AS "ASMS_LOCATION" ON "ASMS_LOCATION"."id" = "ASDK_ITEM_DW_LAST"."location_id"
LEFT JOIN "ADICIONALES_TC" AS "ADTC" ON "ADTC"."ID_COMPANY" = "ASDK_ITEM_DW_LAST"."company_id" AND "ADTC"."NOMBRE" IN ('Código Municipio')
LEFT JOIN "ADICIONALES_TC" AS "ADTC1" ON "ADTC1"."ID_COMPANY" = "ASDK_ITEM_DW_LAST"."company_id" AND "ADTC1"."NOMBRE" IN ('Tipo Entidad')
LEFT JOIN "dbo"."ASMS_TYPES" AS "TIPO DE CASO" ON "TIPO DE CASO"."id" = "ASDK_ITEM_DW_LAST"."type_id"
LEFT JOIN "dbo"."ASMS_STATUS" AS "ESTADO" ON "ESTADO"."stat_id" = "ASDK_ITEM_DW_LAST"."state_id"
LEFT JOIN "dbo"."ASMS_PROJECTS" AS "ASMS_PROJECTS" ON "ASMS_PROJECTS"."proj_id" = "ASDK_ITEM_DW_LAST"."project_id"
LEFT JOIN "dbo"."ASMS_STATUS_REASON" AS "ASMS_STATUS_REASON" ON "ASMS_STATUS_REASON"."reas_id" = "ASDK_ITEM_DW_LAST"."reason_id"
LEFT JOIN "dbo"."ASDK_CATEGORY" AS "ASDK_CATEGORY" ON "ASDK_CATEGORY"."ctg_index" = "ASDK_ITEM_DW_LAST"."category_id"
LEFT JOIN "dbo"."ASDK_SERVICE" AS "ASDK_SERVICE" ON "ASDK_SERVICE"."id" = "ASDK_ITEM_DW_LAST"."service_id"
LEFT JOIN "dbo"."AFW_CATALOG_CODE" AS "IMPACTO" ON "IMPACTO"."code_id" = "ASDK_ITEM_DW_LAST"."impact_id"
LEFT JOIN "dbo"."AFW_CATALOG_CODE" AS "URGENCIA" ON "URGENCIA"."code_id" = "ASDK_ITEM_DW_LAST"."urgency_id"
LEFT JOIN "dbo"."AFW_CATALOG_CODE" AS "PRIORIDAD" ON "PRIORIDAD"."code_id" = "ASDK_ITEM_DW_LAST"."priority_id"
LEFT JOIN "dbo"."AFW_CATALOG_CODE" AS "TIPO DE REGISTRO" ON "TIPO DE REGISTRO"."code_id" = "ASDK_ITEM_DW_LAST"."registry_type_id"
LEFT JOIN "dbo"."AFW_GROUPS" AS "AFW_GROUPS" ON "AFW_GROUPS"."grou_id" = "ASDK_ITEM_DW_LAST"."group_id"
LEFT JOIN "dbo"."AFW_USERS" AS "ESPECIALISTA" ON "ESPECIALISTA"."user_id" = "ASDK_ITEM_DW_LAST"."responsible_id"
LEFT JOIN "dbo"."AFW_USERS" AS "CLIENTE FINAL" ON "CLIENTE FINAL"."user_id" = "ASDK_ITEM_DW_LAST"."customer_id"
LEFT JOIN "dbo"."AFW_USERS" AS "AUTOR DE TICKET" ON "AUTOR DE TICKET"."user_id" = "ASDK_ITEM_DW_LAST"."author_id"
LEFT JOIN "dbo"."ASMS_COMPANY" AS "COMPANIA" ON "COMPANIA"."Id" = "ASDK_ITEM_DW_LAST"."company_id"
LEFT JOIN "dbo"."CMDB_CI" AS "CMDB_CI" ON "CMDB_CI"."id" = "ASDK_ITEM_DW_LAST"."ci_id"
LEFT JOIN "dbo"."AFW_USERS" AS "ULT. ESPECIALISTA MODIFICADOR" ON "ULT. ESPECIALISTA MODIFICADOR"."user_id" = "ASDK_ITEM_DW_LAST"."modifier_id"
LEFT JOIN "dbo"."AFW_USERS" AS "1ER ESPECIALISTA ASIGNADO" ON "1ER ESPECIALISTA ASIGNADO"."user_id" = "ASDK_ITEM_DW_LAST"."receptor_id"
LEFT JOIN "dbo"."ASMS_CALENDAR" AS "ASMS_CALENDAR" ON "ASMS_CALENDAR"."CALENDAR_ID" = "ASDK_ITEM_DW_LAST"."calendar_sla_id"
LEFT JOIN "dbo"."ASMS_MODEL" AS "MODELO" ON "MODELO"."id" = "ASDK_ITEM_DW_LAST"."model_id"
LEFT JOIN "dbo"."ASDK_SLA" AS "SLA" ON "SLA"."SLA_ID" = "ASDK_ITEM_DW_LAST"."sla_id"
WHERE "ASMS_PROJECTS"."proj_name" = '<PROYECTO>'
AND "ASDK_ITEM_DW_LAST"."opened_date" >= '<FECHA_CORTE>';
