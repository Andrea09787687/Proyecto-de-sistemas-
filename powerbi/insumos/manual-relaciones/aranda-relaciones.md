# Manual de relaciones – Aranda Database 9.5.57 (tablero GACEL / LÍNEA 3000)

Fuente oficial: https://docs.arandasoft.com/database/9.5.57
Contenido extraído de la documentación oficial el 08/11/2026, más las reglas validadas contra la base de producción del cliente (servidor del cliente, base `ASMS`).

> **Para el agente:** este archivo reemplaza la consulta directa a docs.arandasoft.com. El sitio se arma con JavaScript, así que si no tienes navegador puedes leerlo vacío. Usa este contenido como referencia.

---

## 1. Reglas validadas en producción (prevalecen sobre la documentación)

| Tema | Documentación | Realidad en la base del cliente |
|---|---|---|
| `FACT_ASDK_ITEM.current_time` | En **segundos** | Está en **minutos**. No usarlo para tiempos: se reemplaza por los cronómetros (`ASMS_TIMES_DATA`). |
| Cronómetros `sdb_current_time` / `estimated_time` | "Representación en valor entero del tiempo transcurrido" | **Minutos hábiles**. El calendario es de lunes a viernes con días de 24 h: 14.400 min = 10 días hábiles. Ejemplo: GACEL-14550 tiene 16.311 min reales contra 14.400 estimados, es decir 113 %. |
| `current_progress` | % de avance al guardar el caso | Es `real / estimado × 100`. Queda congelado al último guardado, así que se usa el calculado con los cronómetros. |
| Fechas | Sin zona horaria | Están en **UTC**. Para hora Colombia se aplica `DATEADD(HH, -5, fecha)`. |
| Cronómetro en 0 en casos cerrados | — | El cronómetro **nunca corrió**, así que el ANS es "No aplica" y el caso no entra al % de cumplimiento. |
| Fechas de atención y solución en FACT | `attention_date`, `solution_date` | Vienen NULL o congeladas. Se toman de `end_date` del cronómetro (`Attention` / `Solution`). |
| Fecha de asignación | — | **No existe** en `FACT_ASDK_ITEM`. Habría que sacarla del historial del caso (pendiente, fase 2). |
| Departamento y edificio del solicitante | `AFW_USERS.user_department_code` / `user_building_id` | Siempre NULL en este cliente. Sede sí: `AFW_USERS.user_site_id` → `AFW_CATALOG_CODE.code_key`. |
| Proyectos | — | 1 = GACEL (solo ServiceCall), 2 = LÍNEA 3000, 4 = RISTI |
| `ASDK_ITEM_DW_LAST` | Vista obsoleta | **No usar.** La documentación indica consultar `adw.FACT_ASDK_ITEM`, `adw.FACT_ASDK_ITEM_FIELDS_REVISION`, `adw.DIM_ASDK_ITEM_TEXT` y `adw.DIM_ITEM_NOTES`. |

---

## 2. Mapa de relaciones usado en la vista `dbo.VW_TABLERO_CASOS_ARANDA`

Tabla base: `adw.FACT_ASDK_ITEM` (alias `caso`), filtrada a `item_type_sk IN (1,2,3,4)`.

| Dato del tablero | Unión |
|---|---|
| Proyecto | `ASMS_PROJECTS p ON p.proj_id = caso.project_sk` |
| Tipo de caso | `ASMS_TYPES ty ON ty.id = caso.item_type_sk` |
| Modelo (tipología) | `ASMS_MODEL mo ON mo.id = caso.model_sk` (columna `name`) |
| Categoría | `ASDK_CATEGORY ctg ON ctg.ctg_index = caso.category_sk` |
| Servicio | `ASDK_SERVICE sv ON sv.id = caso.service_sk` |
| Asunto, descripción, comentario | `adw.DIM_ASDK_ITEM_TEXT dt ON dt.item_sk = caso.id AND dt.is_current = 1` |
| Autor / solicitante / responsable | `AFW_USERS` sobre `author_user_sk` / `customer_user_sk` / `specialist_user_sk` (`user_id`) |
| Grupo responsable | `AFW_GROUPS g ON g.grou_id = caso.specialist_group_sk` |
| Estado / razón | `ASMS_STATUS st ON st.stat_id = caso.status_sk`; `ASMS_STATUS_REASON rs ON rs.reas_id = caso.reason_sk` |
| Sede | `AFW_CATALOG_CODE sede ON sede.code_id = cli.user_site_id` (cli = solicitante) |
| Tipo de registro, impacto, urgencia, prioridad | `AFW_CATALOG` + `AFW_CATALOG_CODE` (`code_cata_id = cata_id`) con `cata_name` = `REGISTRY_TYPE` / `IMPACT` / `URGENCY` / `PRIORITY`, unido por `code_id` a `registry_type_sk` / `impact_sk` / `urgency_sk` / `priority_sk` |
| ANS | `ASDK_SLA sla ON sla.sla_id = caso.sla_sk` |
| Cronómetros | `ASMS_TIMES_DATA` **UNION ALL** `ASMS_TIMES_DATA_CLOSED`, unido con `ASMS_TIMES t ON t.id = time_id` y filtrado a `t.name IN ('Attention','Solution')`, por `item_id = caso.id`. Si hay varias filas, se toma la de mayor `sdb_current_time`. |

---

## 3. Tablas de la documentación oficial

### 3.1 `dbo.ASDK_ITEM_DW_LAST` (vista, obsoleta)
Retorna un listado con la información de los ítems de ASDK. **Obsoleto:** vista de compatibilidad que se eliminará en una versión futura; consultar directamente `adw.FACT_ASDK_ITEM`, `adw.FACT_ASDK_ITEM_FIELDS_REVISION`, `adw.DIM_ASDK_ITEM_TEXT` y `adw.DIM_ITEM_NOTES`.
https://docs.arandasoft.com/database/9.5.57/pages/dbo/asdk_item_dw_last.html

### 3.2 `adw.FACT_ASDK_ITEM`
Contiene información de las últimas versiones sobre los casos en la suite de ASMS (DataWareHouse). Llave primaria: `PK_FACT_ASDK_ITEM (id)`.
https://docs.arandasoft.com/database/9.5.57/pages/adw/fact_asdk_item.html

| Campo | Tipo | Descripción |
|---|---|---|
| applicant_sk | INT | Identificador del solicitante del caso |
| attention_date | DATETIME | Fecha de atención del caso |
| attention_date_key | INT | Identificador de la dimensión de fecha de atención del caso |
| author_email | NVARCHAR (1020) | Correo del autor |
| author_user_sk | INT | Identificador del usuario que creó el caso |
| available_cost | BIT | Costo disponible al momento de crearse el caso |
| available_count | BIT | Cantidad de casos disponible al crearse el caso según la cuota de casos por servicio |
| available_effort | BIT | Cantidad de esfuerzo disponible al momento de crearse el caso |
| available_price | BIT | Precio disponible al momento de crearse el caso |
| calendar_ola_sk | INT | Identificador del calendario OLA |
| calendar_sla_sk | INT | Identificador del calendario SLA |
| calendar_uc_sk | INT | Identificador del calendario UC |
| category_sk | INT | Identificador de la categoría del caso |
| ci_sk | INT | Identificador del elemento de configuración (CI) asociado al caso |
| close_date_sk | INT | Identificador de la dimensión de fecha de cierre del caso |
| closed_date | DATETIME | Fecha de cierre del caso |
| company_sk | INT | Identificador de la compañía para el caso |
| contract_sk | INT | Identificador del contrato asociado |
| cost | FLOAT | Valor acumulado del costo del caso |
| cost_center_sk | INT | Identificador del centro de costos para el caso |
| cost_model_sk | INT | Identificador del modelo de costo para el caso |
| created_date | DATETIME | Fecha de creación del caso |
| created_date_sk | INT | Identificador de la dimensión de fecha de creación del caso |
| current_progress | FLOAT | Progreso porcentual en el momento de guardar el caso |
| current_time | FLOAT | Tiempo transcurrido en segundos del tiempo por defecto al guardar el caso (**en el cliente: minutos**, ver sección 1) |
| customer_user_sk | INT | Identificador del cliente asignado al caso |
| default_time_real_date | DATETIME | Fecha para el cronómetro predeterminado del caso |
| default_time_real_date_sk | INT | Identificador de la dimensión de fecha para el cronómetro predeterminado |
| effort | FLOAT | Esfuerzo acumulado registrado para atender el caso |
| estimated_date | DATETIME | Fecha estimada para el cronómetro predeterminado del caso |
| estimated_date_sk | INT | Identificador de la dimensión de fecha estimada |
| id* | INT | Identificador del caso |
| id_by_project* | NVARCHAR (512) | Identificador del caso por proyecto (número de caso) |
| impact_sk | INT | Identificador del impacto para el caso |
| integration_sk | INT | Identificador del sistema externo al que pertenece el caso |
| interface_sk | NVARCHAR (200) | Identificador del sistema de origen asociado al caso (integración) |
| item_type_sk* | INT | Identificador del tipo de caso |
| location_sk | INT | Identificador de la ubicación asociada |
| model_sk | INT | Identificador del modelo para el caso |
| modified_date* | DATETIME2 | Fecha en la que se modificó el caso |
| modifier_user_sk | INT | Identificador del especialista que modificó el caso |
| ola_sk | INT | Identificador del OLA para el caso |
| open_date_sk | INT | Identificador de la dimensión de fecha de apertura del caso |
| opened_date | DATETIME | Fecha de apertura del caso |
| previous_specialist_group_sk | INT | Grupo de especialistas anterior asignado al caso |
| previous_specialist_user_sk | INT | Especialista anterior asignado al caso |
| previous_status_sk | INT | Identificador del estado anterior del caso |
| price | FLOAT | Valor acumulado del precio del caso |
| priority_sk | INT | Identificador de la prioridad del caso |
| profit_center_sk | INT | Identificador del centro de ingresos para el caso |
| project_sk | INT | Identificador del proyecto asociado |
| provider_sk | INT | Identificador del proveedor para el caso |
| reason_sk | INT | Identificador de la razón del caso |
| receptor_user_sk | INT | Identificador del primer especialista asignado al caso |
| recipient_emails | NVARCHAR (MAX) | Correos de destinatarios adicionales |
| registry_type_sk | INT | Identificador del tipo de registro para el caso |
| rev | INT | Número consecutivo que identifica la versión actual del registro |
| service_sk | INT | Identificador del servicio para el caso |
| sla_sk | INT | Identificador del SLA para el caso |
| solution_date | DATETIME | Fecha de solución del caso |
| solution_date_key | INT | Identificador de la dimensión de fecha de solución |
| specialist_group_sk | INT | Identificador del grupo para el caso |
| specialist_user_sk | INT | Identificador del especialista responsable del caso |
| state_final | INT | Identifica si el estado es final (1 = final) |
| state_initial | INT | Identifica si el estado es inicial (1 = inicial) |
| status_sk | INT | Identificador del estado para el caso |
| time | FLOAT | Tiempo calendario entre la modificación anterior y la actual |
| uc_sk | INT | Identificador del UC para el caso |
| unit_sk | INT | Identificador del área interna asociada al caso |
| urgency_sk | INT | Identificador de la urgencia del caso |

### 3.3 `dbo.ASMS_TIMES_DATA`
Contiene información sobre un temporizador (cronómetro) específico vinculado a un caso. Los casos cerrados tienen la misma estructura en `dbo.ASMS_TIMES_DATA_CLOSED`.
Llave primaria: `PK_ASMS_TIMES_DATA (item_id, time_id, item_type_id)`.
https://docs.arandasoft.com/database/9.5.57/pages/dbo/asms_times_data.html

| Campo | Tipo | Descripción |
|---|---|---|
| calendar_id | INT | Identificador del calendario seleccionado para el caso |
| complies | BIT | Determina si el tiempo de servicio es el esperado |
| end_date | DATETIME | Fecha final para la ejecución del caso |
| end_state_id | INT | Identificador del estado final para el temporizador |
| end_time | FLOAT | Valor del tiempo final para el caso |
| estimated_date | DATETIME | Fecha estimada para la ejecución del caso |
| estimated_time | FLOAT | Valor del tiempo estimado para el caso (**minutos hábiles**) |
| item_id* | INT | Identificador único del caso (= `FACT_ASDK_ITEM.id`) |
| item_type_id* | INT | Identificador del tipo de caso |
| next_active_date | DATETIME | Fecha de inicio para que comience a contar tiempo |
| next_inactive_date | DATETIME | Fecha final en la que se debe contar tiempo |
| recalculate_date* | BIT | Si el tiempo se recalcula al finalizar una pausa |
| sdb_current_paused | FLOAT | Tiempo transcurrido de pausa |
| sdb_current_progress | FLOAT | Valor del progreso actual |
| sdb_current_time | FLOAT | Tiempo transcurrido (**minutos hábiles**) |
| sdb_last_shot | DATETIME | Fecha de la última ejecución del temporizador |
| sdb_time | FLOAT | Tiempo transcurrido actual |
| sdb_total_paused | FLOAT | Tiempo total pausado |
| start_date | DATETIME | Fecha inicial del caso |
| start_state_id | INT | Identificador del estado inicial para el temporizador |
| status_type* | BIT | Estado del temporizador (0 = detenido, 1 = en ejecución) |
| time_id* | INT | Identificador del temporizador asociado al caso |
| time_type_id* | INT | Tipo de cálculo de tiempo (0 = por estado, 1 = por condición) |
| type_agree | INT | Tipo de acuerdo de servicio asociado |

Referencias (llaves foráneas):

| Columna | Tabla referenciada | Columna | Nombre |
|---|---|---|---|
| time_id* | dbo.ASMS_TIMES | id | FK01_ASMS_TIMES_DATA |
| type_agree | dbo.ASMS_TYPES | id | FK02_ASMS_TIMES_DATA |

`ASMS_TIMES.name` identifica el cronómetro: `Attention` (atención) y `Solution` (solución).

### 3.4 `dbo.ASDK_ITEM_RELATION`
Contiene la relación entre dos casos (padre / hijo). Los casos cerrados están en `dbo.ASDK_ITEM_RELATION_CLOSED`, y existe `dbo.ASDK_ITEM_RELATION_DW` para el DataWareHouse.
Llave primaria: `PK_ASDK_ITEM_RELATION (source_id, target_id, relation_type_id)`.
https://docs.arandasoft.com/database/9.5.57/pages/dbo/asdk_item_relation.html

| Campo | Tipo | Descripción |
|---|---|---|
| author_id | INT | Identificador del usuario que creó la relación |
| created_date | DATETIME | Fecha en la que se creó la relación |
| relation_type_id* | INT | Identificador del tipo de relación |
| source_id* | INT | Identificador del caso padre asociado (= `FACT_ASDK_ITEM.id`) |
| target_id* | INT | Identificador del caso hijo asociado (= `FACT_ASDK_ITEM.id`) |

Referencias (llaves foráneas):

| Columna | Tabla referenciada | Columna | Nombre |
|---|---|---|---|
| author_id | dbo.AFW_USERS | user_id | FK01_ASDK_ITEM_RELATION |
| relation_type_id* | dbo.ASMS_RELATION_TYPE | id | FK02_ASDK_ITEM_RELATION |

> La vista actual del tablero **no usa** `ASDK_ITEM_RELATION`: el cliente no pidió casos relacionados. Si se agregan en fase 2, unir `source_id` / `target_id` con `FACT_ASDK_ITEM.id` y leer el tipo en `ASMS_RELATION_TYPE`.

---

## 4. Otras páginas útiles (misma versión)

- `adw.DIM_ASDK_ITEM_TEXT` (asunto, descripción, comentario): https://docs.arandasoft.com/database/9.5.57/pages/adw/dim_asdk_item_text.html
- `adw.V_FACT_ASDK_ITEM`: https://docs.arandasoft.com/database/9.5.57/pages/adw/v_fact_asdk_item.html
- `adw.FACT_ASDK_ITEM_REVISION` (historial; posible fuente de la fecha de asignación): https://docs.arandasoft.com/database/9.5.57/pages/adw/fact_asdk_item_revision.html
- `dbo.ASMS_TIMES`: https://docs.arandasoft.com/database/9.5.57/pages/dbo/asms_times.html
- `dbo.ASMS_TIMES_DATA_CLOSED`: https://docs.arandasoft.com/database/9.5.57/pages/dbo/asms_times_data_closed.html
- `dbo.AFW_CATALOG` / `dbo.AFW_CATALOG_CODE`: https://docs.arandasoft.com/database/9.5.57/pages/dbo/afw_catalog.html

---

# Anexo — Queries entregadas por el usuario (insumos/queries) y vistas

> Las reglas de la sección 1 prevalecen sobre lo que diga este anexo.

## A1. Relaciones que usan las queries entregadas

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

## A2. Tablas en Power BI (una por vista)

| Tabla Power BI | Vista | Tipo | Granularidad | Llave |
|---|---|---|---|---|
| Casos_Resumen | vistas/vw_BI_Casos_Resumen.sql | Hecho | 1 fila por caso (I/P/C/R) | id |
| Tareas_Resumen | vistas/vw_BI_Tareas_Resumen.sql | Hecho | 1 fila por tarea | num_tarea |
| Casos_Especialista | vistas/vw_BI_Casos_Especialista.sql | Hecho | 1 fila por caso | NRO. TICKET |
| Inventario_ADM | vistas/vw_BI_Inventario_ADM.sql | Hecho | dispositivo × aplicación (× IP × grupo) | Device_id + Software |
| Calendario | DAX (agente) | Dimensión | 1 fila por día | Date |

## A3. Relaciones propuestas en el modelo Power BI

| Origen (muchos) | Columna | Destino (uno) | Columna | Card. | Filtro | Activa |
|---|---|---|---|---|---|---|
| Casos_Resumen | Fecha Registro (solo fecha, de `18_Fecha_de_Registro`) | Calendario | Date | *:1 | Única | Sí |
| Casos_Resumen | Fecha Cierre (solo fecha, de `19_Fecha_de_Cierre`) | Calendario | Date | *:1 | Única | No (usar `USERELATIONSHIP`) |
| Tareas_Resumen | Fecha Registro Tarea (solo fecha) | Calendario | Date | *:1 | Única | Sí |
| Tareas_Resumen | caso_id (agregado en la vista) | Casos_Resumen | id | *:1 | Única | Sí |
| Casos_Especialista | Fecha Registro (solo fecha) | Calendario | Date | *:1 | Única | Sí |

- `Inventario_ADM` es otro dominio (dispositivos); queda sin relación con casos salvo que se agregue el CI (`CMDB_CI`) en ambas queries.
- Las dimensiones (estado, grupo, especialista, prioridad…) ya vienen como texto dentro de cada query; no se crean tablas de dimensión aparte salvo que el usuario quiera filtrar varias tablas a la vez con un mismo segmentador (ahí se crea una dimensión común, p. ej. `Dim_Grupo`).

## A4. Hallazgos a revisar con el usuario

1. **Parámetros `@`**: resuelto con las vistas de `insumos/vistas/` (se quitan de la vista y se filtra en Power BI por proyecto, grupo y periodo). Alternativa sin vista: `herramientas/generar_conexion.py` en modo `query` arma los `DECLARE`.
2. **Llave Tareas → Casos**: resuelto en `vw_BI_Tareas_Resumen` con `caso_id` (= `Casos_Resumen[id]`).
3. **Zona horaria inconsistente**: `Casos_Especialista` usa fechas UTC (no resta 5 horas) y las demás sí.
4. **`Casos_Especialista` tiene filtros fijos** (`'Pasivocol'`, `>= '2024-08-12'`).
5. **Columna PROGRESO** queda vacía cuando `current_progress > 100` o cuando está entre 81 y 100 y el caso está Cerrado/Resuelto. Además "VENCIDOS ABIERTOS" incluye el estado 'Resuelto'. Conviene definir la semaforización como columna o medida en Power BI.
6. **Tareas**: el filtro `type_id NOT IN (1,4)` deja pasar problemas (2) y cambios (3); confirmar si la intención es solo tareas. `BETWEEN @fechaini AND @fechafin` excluye el último día después de las 00:00.
7. **CTE `campos` sin uso** en `Casos_Resumen` (se puede quitar o usar para campos adicionales).
8. **Rendimiento**: `Casos_Resumen` hace 8 subconsultas PIVOT por fila. Con muchos casos puede tardar; alternativa: una tabla `Tiempos_ANS` aparte relacionada por `id`.
9. **Inventario_ADM** puede duplicar filas si un equipo tiene varias IP o grupos; contar dispositivos con `DISTINCTCOUNT(Device_id)`.
10. Los usuarios o grupos que no tengan equivalencia salen vacíos por los LEFT JOIN; en Power BI se recomienda reemplazar los vacíos por "Sin asignar".
11. **`ASDK_ITEM_DW_LAST` es obsoleta** (sección 1 y 3.1): `Tareas_Resumen` y `Casos_Especialista` la usan. Funciona hoy, pero en una actualización de Aranda puede desaparecer. Plan: migrar esas vistas a `adw.FACT_ASDK_ITEM` + `adw.DIM_ASDK_ITEM_TEXT` (+ `ASDK_ITEM_RELATION` para tareas).
12. **`current_progress` y `current_time` no son confiables** (sección 1): la columna PROGRESO / VENCIDOS de `Casos_Especialista` y `30_Tiempo` / `31_Progreso_del_caso` de `Casos_Resumen` deben reemplazarse por el % calculado con cronómetros: `sdb_current_time / estimated_time × 100` del cronómetro `Solution` (y `Attention`). Cronómetro en 0 en caso cerrado = ANS "No aplica" (fuera del % de cumplimiento).
13. **Departamento y edificio** (`15_Departamento`, `17_Edificio`) vienen siempre NULL en este cliente; usar solo **Sede**.
14. Tiempos de cronómetro en **minutos hábiles** (L–V, días de 24 h): para mostrar días hábiles dividir entre 1.440.
