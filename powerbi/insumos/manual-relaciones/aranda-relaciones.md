# Manual de relaciones — Aranda (ASMS / ADM) 9.5.57

**Manual oficial del modelo de datos:** https://docs.arandasoft.com/database/9.5.57
> Para el agente: consulta este link (WebFetch) cuando necesites confirmar columnas, tipos o relaciones que no aparecen aquí. Si el link no carga desde tu sesión, pide al usuario que habilite el dominio `docs.arandasoft.com` o que pegue la página de la tabla. Lo de abajo se armó a partir de los JOIN de las queries de `powerbi/insumos/queries/` y está **pendiente de validar contra el manual**.

## 1. Conceptos clave de la base Aranda

- **Casos abiertos vs. cerrados en tablas separadas.** Varias tablas tienen una versión `_CLOSED` (ej.: `ASMS_FIELDS_DATA` / `ASMS_FIELDS_DATA_CLOSED`, `ASMS_TIMES_DATA` / `ASMS_TIMES_DATA_CLOSED`, `ASDK_ITEM_RELATION` / `ASDK_ITEM_RELATION_CLOSED`). Siempre se unen con `UNION ALL` para tener la historia completa.
- **Dos fuentes de casos:**
  - `adw.FACT_ASDK_ITEM`: tabla de hechos del data warehouse de Aranda. Las llaves terminan en `_sk` (`project_sk`, `status_sk`…). El texto (asunto, descripción, solución) está en `adw.DIM_ASDK_ITEM_TEXT` (`is_current = 1`).
  - `dbo.ASDK_ITEM_DW_LAST`: vista plana con el último estado del caso. Las llaves terminan en `_id` y ya trae algunos nombres (`state_name`, `group_name`, `responsible_name`, `customer_name`).
- **Tipos de caso (`item_type_sk` / `type_id`):** 1 = Incidente, 2 = Problema, 3 = Cambio, 4 = Requerimiento. Los demás tipos son tareas y otros ítems.
- **Hora:** la base guarda en UTC. Las queries restan 5 horas (`DATEADD(HH,-5, …)`) para la hora de Colombia.
- **Tiempos ANS:** `ASMS_TIMES` tiene el catálogo de tiempos (`'Attention'` = atención, `'Solution'` = solución) y `ASMS_TIMES_DATA(_CLOSED)` tiene, por caso, `estimated_date`, `end_date`, `estimated_time` y `sdb_current_time`.
- **Progreso del ANS:** `current_progress` es el % del tiempo consumido. ≤ 80 = dentro del ANS, 81–100 = por vencer, > 100 = vencido.
- **Catálogos:** `AFW_CATALOG` (por `cata_name`: `IMPACT`, `URGENCY`, `PRIORITY`, `REGISTRY_TYPE`) → `AFW_CATALOG_CODE` (`code_id`, `code_value`, `code_key`).

## 2. Relaciones en la base de datos (las que usan las queries)

### Casos — `adw.FACT_ASDK_ITEM` (alias `caso`)
| Columna en caso | Tabla destino | Columna destino | Significado |
|---|---|---|---|
| project_sk | ASMS_PROJECTS | proj_id | Proyecto |
| item_type_sk | ASMS_TYPES | id | Tipo de caso |
| category_sk | ASDK_CATEGORY | ctg_index | Categoría (`fl_str_hierarchy` = jerarquía) |
| id | adw.DIM_ASDK_ITEM_TEXT | item_sk (+ `is_current = 1`) | Asunto, descripción, solución |
| service_sk | ASDK_SERVICE | id | Servicio |
| author_user_sk | AFW_USERS | user_id | Autor |
| customer_user_sk | AFW_USERS | user_id | Cliente |
| specialist_user_sk | AFW_USERS | user_id | Responsable |
| modifier_user_sk | AFW_USERS | user_id | Último modificador |
| specialist_group_sk | AFW_GROUPS | grou_id | Grupo responsable |
| status_sk | ASMS_STATUS | stat_id | Estado |
| reason_sk | ASMS_STATUS_REASON | reas_id | Razón |
| registry_type_sk / impact_sk / urgency_sk / priority_sk | AFW_CATALOG_CODE | code_id | Tipo de registro, impacto, urgencia, prioridad |
| sla_sk | ASDK_SLA | SLA_ID | ANS |
| ci_sk | CMDB_CI | id | CI asociado |
| id | ASMS_TIMES_DATA(_CLOSED) | item_id | Tiempos de atención/solución |
| id | ASMS_FIELDS_DATA(_CLOSED) | item_id | Campos adicionales (`ASMS_FIELDS.id = field_id`) |
| id | ASDK_ITEM_RELATION(_CLOSED) | target_id (`source_id` = caso relacionado) | Casos relacionados |

Usuario cliente → ubicación: `AFW_USERS.user_department_code`, `user_site_id`, `user_building_id` → `AFW_CATALOG_CODE.code_id`.

### Casos — `dbo.ASDK_ITEM_DW_LAST`
`project_id`→ASMS_PROJECTS.proj_id · `type_id`→ASMS_TYPES.id · `state_id`→ASMS_STATUS.stat_id · `reason_id`→ASMS_STATUS_REASON.reas_id · `category_id`→ASDK_CATEGORY.ctg_index · `service_id`→ASDK_SERVICE.id · `impact_id`/`urgency_id`/`priority_id`/`registry_type_id`→AFW_CATALOG_CODE.code_id · `group_id`→AFW_GROUPS.grou_id · `responsible_id`/`customer_id`/`author_id`/`modifier_id`/`receptor_id`→AFW_USERS.user_id · `company_id`→ASMS_COMPANY.Id · `ci_id`→CMDB_CI.id · `calendar_sla_id`→ASMS_CALENDAR.CALENDAR_ID · `model_id`→ASMS_MODEL.id · `sla_id`→ASDK_SLA.SLA_ID · `location_id`→ASMS_LOCATION.id
Campos adicionales de compañía: `ASMS_FIELDS_DATA(_CLOSED).item_id = company_id` filtrando `ASMS_FIELDS.name` ('Código Municipio', 'Tipo Entidad').

### Tareas
`ASDK_ITEM_RELATION(_CLOSED).target_id` = tarea (`ASDK_ITEM_DW_LAST.id`) · `source_id` = caso padre (`ASDK_ITEM_DW_LAST.id`).

### Inventario ADM (Device Management)
`AAM_DEVICE.id` → `AAM_DEVICE_SOFTWARE.device_id` → `software_id` = `AAM_SOFTWARE_VERSION.id` → `product_id` = `AAM_SOFTWARE_PRODUCT.id` (`type`: 0 = SO, 1 = aplicación, 2 = actualización) → `manufacturer_id` = `AAM_MANUFACTURER.id`.
`AAM_DEVICE.type` → `AAM_DEVICE_TYPE.id` · `AAM_DEVICE.id` → `ADM_COMMUNICATION_NODE.device_id` (IP), `AAM_DEVICE_SETUP.device_id` (modelo), `AAM_DEVICE_CONFIGURATION.device_id` (agente), `AAM_GROUP_DEVICE.device_id` → `group_id` = `AFW_GROUPS.grou_id`. Sistema operativo: `AAM_DEVICE_SOFTWARE.id = AAM_DEVICE_OS.id`.

## 3. Tablas en Power BI (una por query)

| Tabla Power BI | Query | Tipo | Granularidad | Llave |
|---|---|---|---|---|
| Casos_Resumen | Casos_Resumen.sql | Hecho | 1 fila por caso (I/P/C/R) | id |
| Tareas_Resumen | Tareas_Resumen.sql | Hecho | 1 fila por tarea | num_tarea |
| Casos_Especialista | Casos_Especialista.sql | Hecho | 1 fila por caso | NRO. TICKET |
| Inventario_ADM | Inventario_ADM.sql | Hecho | dispositivo × aplicación (× IP × grupo) | Device_id + Software |
| Calendario | DAX (agente) | Dimensión | 1 fila por día | Date |

## 4. Relaciones propuestas en el modelo Power BI

| Origen (muchos) | Columna | Destino (uno) | Columna | Card. | Filtro | Activa |
|---|---|---|---|---|---|---|
| Casos_Resumen | Fecha Registro (solo fecha, de `18_Fecha_de_Registro`) | Calendario | Date | *:1 | Única | Sí |
| Casos_Resumen | Fecha Cierre (solo fecha, de `19_Fecha_de_Cierre`) | Calendario | Date | *:1 | Única | No (usar `USERELATIONSHIP`) |
| Tareas_Resumen | Fecha Registro Tarea (solo fecha) | Calendario | Date | *:1 | Única | Sí |
| Tareas_Resumen | Llave Caso (`tipo_caso` & "-" & `num_caso`) | Casos_Resumen | Llave Caso (`02_Tipo_de_Caso` & "-" & `03_Numero_de_Caso`) | *:1 | Única | Sí — **validar** |
| Casos_Especialista | Fecha Registro (solo fecha) | Calendario | Date | *:1 | Única | Sí |

- `Inventario_ADM` es otro dominio (dispositivos); queda sin relación con casos salvo que se agregue el CI (`CMDB_CI`) en ambas queries.
- Las dimensiones (estado, grupo, especialista, prioridad…) ya vienen como texto dentro de cada query; no se crean tablas de dimensión aparte salvo que el usuario quiera filtrar varias tablas a la vez con un mismo segmentador (ahí se crea una dimensión común, p. ej. `Dim_Grupo`).

## 5. Hallazgos a revisar con el usuario

1. **Parámetros `@proyecto`, `@Grupo`, `@FECHAINI`, `@FECHAFIN`**: Power BI no los resuelve. Opciones: (a) reemplazar por valores fijos; (b) crear parámetros de Power Query y armar la instrucción con `DECLARE` (ver sección 6); (c) quitar los filtros de fecha y filtrar en Power BI (más simple, más datos).
2. **Llave Tareas → Casos**: `Tareas_Resumen` no trae el `id` interno del caso. Recomendado agregar `i.id AS caso_id` al SELECT final para relacionar con `Casos_Resumen[id]` sin ambigüedad. Hay que confirmar si `id_by_project` se repite entre tipos de caso.
3. **Zona horaria inconsistente**: `Casos_Especialista` usa fechas UTC (no resta 5 horas) y las demás sí.
4. **`Casos_Especialista` tiene filtros fijos** (`'Pasivocol'`, `>= '2024-08-12'`).
5. **Columna PROGRESO** queda vacía cuando `current_progress > 100` o cuando está entre 81 y 100 y el caso está Cerrado/Resuelto. Además "VENCIDOS ABIERTOS" incluye el estado 'Resuelto'. Conviene definir la semaforización como columna o medida en Power BI.
6. **Tareas**: el filtro `type_id NOT IN (1,4)` deja pasar problemas (2) y cambios (3); confirmar si la intención es solo tareas. `BETWEEN @fechaini AND @fechafin` excluye el último día después de las 00:00.
7. **CTE `campos` sin uso** en `Casos_Resumen` (se puede quitar o usar para campos adicionales).
8. **Rendimiento**: `Casos_Resumen` hace 8 subconsultas PIVOT por fila. Con muchos casos puede tardar; alternativa: una tabla `Tiempos_ANS` aparte relacionada por `id`.
9. **Inventario_ADM** puede duplicar filas si un equipo tiene varias IP o grupos; contar dispositivos con `DISTINCTCOUNT(Device_id)`.
10. Los usuarios o grupos que no tengan equivalencia salen vacíos por los LEFT JOIN; en Power BI se recomienda reemplazar los vacíos por "Sin asignar".

## 6. Plantilla de parámetros en Power Query (opción b)

Crear en Power BI Desktop (`Transformar datos > Administrar parámetros`): `pProyecto` (número), `pGrupos` (texto, ej. "12,15"), `pFechaIni` y `pFechaFin` (fecha). Luego, en el Editor avanzado de la consulta:
```m
let
    Encabezado = "DECLARE @proyecto INT = " & Number.ToText(pProyecto) & ";#(lf)" &
                 "DECLARE @Grupo VARCHAR(500) = '" & pGrupos & "';#(lf)" &
                 "DECLARE @FECHAINI DATE = '" & Date.ToText(pFechaIni, "yyyy-MM-dd") & "';#(lf)" &
                 "DECLARE @FECHAFIN DATE = '" & Date.ToText(pFechaFin, "yyyy-MM-dd") & "';#(lf)",
    Consulta   = "<pegar aquí el contenido de Casos_Resumen.sql sin los comentarios>",
    Origen     = Sql.Database("SERVIDOR", "BASE_ARANDA", [Query = Encabezado & Consulta])
in
    Origen
```
(En `Tareas_Resumen` las variables se llaman `@fechaini` y `@fechafin`, en minúscula; SQL Server normalmente no distingue mayúsculas, pero se pueden declarar igual.)
