# Publicación, validación y solución de problemas

Lecciones del tablero Aranda construido para un cliente (Aerocivil), con Claude conectado al computador del usuario. Úsalas en la Fase 6 y siempre que el usuario reporte un problema.

## 1. Lista de chequeo antes de publicar

### Filtros entre páginas (sincronizar segmentaciones)
Por defecto cada página tiene sus propios filtros. Si el cliente pide que se mantengan al navegar:
1. `Vista > Sincronizar segmentaciones`.
2. Seleccionar el segmentador (ej.: Proyecto).
3. En el panel, marcar todas las páginas en las dos columnas: **sincronizar** y **visible** (ojo).
4. Repetir con cada filtro global (Periodo de registro, Tipo de caso, Sede, Grupo responsable…).
> Si el agente edita el PBIP, configura el mismo `syncGroup` en el `visual.json` de cada segmentador.

### Botones de filtros y "Limpiar filtros"
Los segmentadores en lista, el rango de fechas, los botones de campo (Tipo de caso / Categoría / Servicio / Proyecto) y de periodo (Semanal / Mensual / Trimestral / Anual) y el botón **Limpiar filtros** funcionan igual al publicar. En Power BI Desktop los botones se activan con **Ctrl + clic**; ya publicado basta un clic. Explícaselo al usuario para que no piense que está dañado.

### Seguridad por roles (RLS / OLS)
- Si un rol **no puede ver columnas** (ej.: rol *Consulta* sin solicitante, asunto ni descripción), cualquier visual o filtro que use esas columnas **muestra error** para ese rol; Power BI no quita solo la columna.
- Solución: crear páginas o visuales por perfil (ej.: `Detalle de casos (Consulta)` sin los campos ocultos) y ocultar a cada rol la página que no le corresponde. Revisar también los segmentadores (ej.: filtro Solicitante).
- Probar cada rol en `Modelado > Ver como` antes de publicar y, ya publicado, asignar personas o grupos a los roles en la configuración del modelo semántico.

### Mapas (Azure Maps / mapa)
El mapa sale en blanco si falta alguno de estos tres puntos. Revisarlos en orden:
1. **Power BI Desktop:** `Archivo > Opciones y configuración > Opciones > GLOBAL > Seguridad` → marcar *Usar objetos visuales de mapa y de mapa coroplético* → Aceptar → cerrar y volver a abrir.
2. **Internet en el equipo/servidor:** el fondo del mapa se descarga de Azure. Probar abriendo `https://atlas.microsoft.com` en un navegador del servidor. Que Power BI no pida correo es normal si ya hay una sesión iniciada.
3. **Servicio publicado:** el administrador de Power BI activa en `Portal de administración > Configuración de inquilinos`: *Los usuarios pueden usar el objeto visual de Azure Maps* y, si la política lo permite, *Los datos enviados a Azure Maps se pueden procesar fuera de la región geográfica…*.
4. **Si el visual no reconoció los campos** (lo más común cuando el agente lo creó por archivo): borrar el visual y rehacerlo a mano con el ícono *Mapa de Azure*: `Sedes[sede]` → Ubicación, `Sedes[latitud]` → Latitud, `Sedes[longitud]` → Longitud, medida `Casos registrados` → Tamaño. Repetir en cada página que tenga mapa.
5. **Plan B sin internet o con la política bloqueada:** reemplazar por un mapa de formas (Colombia por departamentos) incluido en el archivo.
> Para mapas, incluir en el modelo una tabla `Sedes` con `sede`, `ciudad`, `departamento`, `latitud`, `longitud` (tipos de dato: categoría de datos Latitud/Longitud).

## 2. Validar que el tablero muestra datos reales (no de prueba)

Es común empezar con un CSV de muestra y luego cambiar a la base. Para confirmar que ya lee de producción:
1. **Contar contra SSMS:** quitar filtros y abrir el periodo a todas las fechas. La tarjeta *Casos registrados* debe dar el mismo número que un `SELECT COUNT(*)` con los mismos filtros en SQL Server Management Studio. Si no coincide, `Inicio > Actualizar`.
2. **Fecha de última actualización:** el encabezado debe mostrar la fecha y hora de la última actualización. Crear la medida:
   ```dax
   Ultima Actualizacion = "Última actualización: " & FORMAT ( MAX ( Actualizacion[FechaHora] ), "dd/MM/yyyy HH:mm" )
   ```
   con una consulta `Actualizacion = DateTime.LocalNow()` en Power Query.
3. **Origen de la consulta:** `Inicio > Transformar datos` → consulta de casos → paso **Origen**. Debe decir `Sql.Database("<servidor>,<puerto>", "<base>", …)`. Si dice `Csv.Document(...)`, sigue leyendo el archivo de prueba. Cerrar sin aplicar cambios.

Si los tres coinciden (conteo, fecha de hoy y `Sql.Database`), son datos reales.

### Cambiar de CSV a la base sin rehacer el tablero
En `Transformar datos`, en la consulta, reemplazar solo el paso `Origen` por `Sql.Database(...)` con la query, y mantener **los mismos nombres de columna** que tenía el CSV. Así no se dañan los visuales ni las medidas.

## 3. Publicación
1. `Inicio > Publicar` → elegir el workspace (requiere licencia Pro/PPU o capacidad Fabric).
2. Si la base está en un servidor interno, configurar el **gateway de datos local** y las credenciales del origen en la configuración del modelo semántico. Después programar la actualización.
3. Asignar los roles RLS.
4. Crear la **App** del workspace para distribuirlo a los usuarios finales.

## 4. Cuando el agente no puede verificar
Si el tablero vive en un servidor al que Claude no tiene acceso (ej.: un servidor del cliente) o se cae la conexión con el computador del usuario, no inventes resultados: dale al usuario los pasos para comprobarlo (sección 2) y pídele una captura o el valor que ve.
