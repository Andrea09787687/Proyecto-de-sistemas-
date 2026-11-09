# Vistas en la base de datos (paso previo a la conexión)

## Por qué una vista
Power BI no debe leer las tablas de Aranda directamente:
- Con decenas de tablas, `_CLOSED`, catálogos y cronómetros, el modelo se vuelve inmanejable.
- La vista entrega **solo las columnas que pide el tablero**, ya unidas y con nombres claros, en hora Colombia.
- Power BI se conecta a **una vista por tabla** (`bi.vw_BI_<Tabla>`) y el modelo queda simple.
- El usuario de Power BI solo necesita permiso de lectura sobre el esquema `bi`, no sobre las tablas de Aranda.
- Si Aranda cambia una tabla en una actualización, se ajusta la vista y el tablero no se toca.

## Reglas para escribir la vista (SQL Server)
1. **Sin variables `@`** ni `DECLARE`: los filtros de proyecto, grupo y periodo se quitan de la vista y se aplican en Power BI (parámetros `pFechaIni`/`pFechaFin` y segmentadores). Deja en la vista las columnas para filtrar (ej.: `49_Id_Proyecto`, `50_Id_Grupo`, fecha de registro).
2. **Sin `ORDER BY`** (no se permite en una vista sin `TOP`) y sin `;` final.
3. Los CTE (`WITH ... AS`) sí se permiten.
4. Cada columna debe tener un nombre único.
5. Las fechas se pasan a hora Colombia con `DATEADD(HH, -5, …)`.
6. Usa `adw.FACT_ASDK_ITEM` + `adw.DIM_ASDK_ITEM_TEXT`. **No uses `ASDK_ITEM_DW_LAST`**, que está obsoleta (ver el manual de relaciones, sección 1).
7. Los tiempos y el % del ANS se calculan con los cronómetros (`ASMS_TIMES_DATA` UNION ALL `_CLOSED`), no con `current_time` ni `current_progress`.
8. Se crea con `CREATE OR ALTER VIEW bi.vw_BI_<Tabla>`, en un esquema propio `bi`, para no mezclarla con los objetos de Aranda.
9. Puede tardar si tiene subconsultas por fila (como los PIVOT de cronómetros en `Casos_Resumen`). Si al abrirla tarda más de unos minutos, mueve los cronómetros a una vista aparte (`vw_BI_Tiempos_ANS`, una fila por caso) y relaciónala por `id`.

## Cómo el agente arma la vista
1. Parte de la query que entregó el usuario (`powerbi/insumos/queries/<Tabla>.sql`) o de los campos que pidió el cliente.
2. Aplica las reglas de arriba y guarda el script en `powerbi/insumos/vistas/vw_BI_<Tabla>.sql`, con un encabezado que diga qué cambió frente a la query original.
3. Muestra al usuario las columnas resultantes y los cambios, y pide aprobación.
4. Entrega las instrucciones de ejecución (abajo) y **espera a que el usuario diga "listo"** antes de conectarse a Power BI.

## Cómo ejecutarla (instrucciones para el usuario)
Requiere un usuario con permiso para crear vistas (normalmente el **DBA**: `db_owner` o `db_ddladmin`).
1. Abrir **SQL Server Management Studio (SSMS)** y conectarse al servidor de Aranda.
2. En el **Explorador de objetos**, clic derecho sobre la base (`ASMS`) → **Nueva consulta**. Verificar arriba, en la lista desplegable, que esté seleccionada la base correcta.
3. Abrir y ejecutar (**F5**) `powerbi/insumos/vistas/00_esquema_y_permisos.sql`. Antes, cambiar `usuario_lectura_bi` por el usuario que usará Power BI. Se hace una sola vez por base.
4. Abrir cada `vw_BI_*.sql` y ejecutarlo con **F5**. Debe decir *"Comandos completados correctamente"*.
   - `vw_BI_Inventario_ADM.sql` va en la base de **ADM**, no en ASMS. Ejecuta también ahí el paso 3.
5. Probar cada vista:
   ```sql
   SELECT TOP 10 * FROM bi.vw_BI_Casos_Resumen;
   SELECT COUNT(*) FROM bi.vw_BI_Casos_Resumen;   -- este número se usa luego para validar el tablero
   ```
6. Si sale un error, copiarlo completo al agente: casi siempre es una columna que no existe en esa versión o un problema de permisos.
7. Responder **"listo"** al agente con:
   - Servidor y puerto (ej.: `SERVIDOR,1433`).
   - Base o bases (ASMS y, si aplica, ADM).
   - Tipo de autenticación (Windows o SQL) y usuario.
   - Periodo inicial que quiere ver (fecha desde / hasta).
   - **La contraseña no**: Power BI la pide en su propia ventana.

## Si el usuario no tiene un DBA o permiso para crear vistas
Usa el modo `query` de `powerbi/herramientas/generar_conexion.py`: Power BI ejecuta la query completa y los `@` se resuelven con `DECLARE`. Funciona igual, pero el modelo depende de queries largas dentro del archivo y el usuario necesita permiso de lectura sobre las tablas de Aranda.
