# Construcción del modelo y del reporte

## A. Modelo semántico (con el Power BI Modeling MCP)

Orden recomendado:
1. **Revisar tipos de dato** de llaves y fechas (las dos columnas de una relación deben tener el mismo tipo).
2. **Tabla calendario** si no existe:
   ```dax
   Calendario =
   ADDCOLUMNS (
       CALENDARAUTO (),
       "Año", YEAR ( [Date] ),
       "Mes Num", MONTH ( [Date] ),
       "Mes", FORMAT ( [Date], "MMMM" ),
       "Año-Mes", FORMAT ( [Date], "YYYY-MM" ),
       "Trimestre", "T" & QUARTER ( [Date] )
   )
   ```
   Marcarla como tabla de fechas y ordenar `Mes` por `Mes Num`.
3. **Relaciones** exactamente como en `powerbi/salidas/modelo-datos.md`: preferir 1:* con filtro en una dirección; usar bidireccional solo si el manual lo pide y no genera ambigüedad. Las relaciones secundarias (ej.: Fecha de entrega) quedan inactivas y se usan con `USERELATIONSHIP`.
4. **Ocultar** llaves técnicas y columnas que no se usan en visuales.
5. **Medidas** en una tabla de medidas (`_Medidas`), con carpetas de visualización, formato (moneda, %, entero) y descripción. Patrones comunes:
   ```dax
   Ventas Totales = SUM ( Ventas[Valor] )
   Ventas Mes Anterior = CALCULATE ( [Ventas Totales], DATEADD ( Calendario[Date], -1, MONTH ) )
   Var % vs Mes Anterior = DIVIDE ( [Ventas Totales] - [Ventas Mes Anterior], [Ventas Mes Anterior] )
   Ventas Acumuladas Año = TOTALYTD ( [Ventas Totales], Calendario[Date] )
   % Cumplimiento = DIVIDE ( [Ventas Totales], [Meta] )
   ```
6. **Validar** cada medida con una consulta DAX y mostrar el resultado:
   ```dax
   EVALUATE SUMMARIZECOLUMNS ( Calendario[Año-Mes], "Ventas", [Ventas Totales] )
   ```
7. Ejecutar la revisión de buenas prácticas del MCP (si está disponible) y reportar hallazgos.
8. RLS si se pidió: crear el rol con su filtro DAX y explicar al usuario cómo probarlo (`Modelado > Ver como`).

## A2. Tiempos (minutos → formato pedido)

Regla: en la vista y en el modelo los tiempos quedan **en minutos** (columnas `*_Min`). La conversión se hace solo con medidas, y **solo en el formato que el usuario pida** (Fase 3). Medidas base:
```dax
Tiempo Solucion Prom (min) = AVERAGE ( Casos_Resumen[35_Tiempo_Solucion_Real_Min] )
Tiempo Atencion Prom (min) = AVERAGE ( Casos_Resumen[33_Tiempo_Atencion_Real_Min] )
```
Conversiones (crear solo las que se pidan). `MinutosPorDia` = 1440 (día de 24 h) o 480 (día de 8 h hábiles), según lo que confirme el usuario:
```dax
Tiempo Solucion Prom (h) = DIVIDE ( [Tiempo Solucion Prom (min)], 60 )
Tiempo Solucion Prom (días) = DIVIDE ( [Tiempo Solucion Prom (min)], 1440 )   -- o 480

Tiempo Solucion Prom (d h m) =
VAR m = [Tiempo Solucion Prom (min)]
VAR MinDia = 1440                                  -- o 480
VAR d = INT ( m / MinDia )
VAR h = INT ( MOD ( m, MinDia ) / 60 )
VAR mi = ROUND ( MOD ( m, 60 ), 0 )
RETURN IF ( ISBLANK ( m ), BLANK (), d & " d " & FORMAT ( h, "00" ) & " h " & FORMAT ( mi, "00" ) & " m" )
```
El formato `d h m` es texto: sirve para tarjetas y tablas, **no** para gráficos (ahí usar minutos, horas o días numéricos).

**Selector de unidad (si lo piden):** tabla desconectada y `SWITCH`:
```dax
Unidad Tiempo = DATATABLE ( "Unidad", STRING, "Orden", INTEGER, { { "Minutos", 1 }, { "Horas", 2 }, { "Días", 3 } } )

Tiempo Solucion Prom = 
SWITCH ( SELECTEDVALUE ( 'Unidad Tiempo'[Unidad], "Minutos" ),
    "Horas", [Tiempo Solucion Prom (h)],
    "Días",  [Tiempo Solucion Prom (días)],
    [Tiempo Solucion Prom (min)] )
```
Agregar un segmentador de botones con `'Unidad Tiempo'[Unidad]` (ordenado por `Orden`) y un título dinámico: `"Tiempo promedio de solución (" & SELECTEDVALUE('Unidad Tiempo'[Unidad], "Minutos") & ")"`.

## B. Páginas y visuales (formato PBIP / PBIR)

Estructura del proyecto guardado en `powerbi/proyecto/`:
```
MiTablero.pbip
MiTablero.SemanticModel/        ← modelo (lo maneja el MCP)
MiTablero.Report/
  definition/
    report.json
    pages/
      pages.json                ← orden de páginas y página activa
      <idPagina>/
        page.json               ← nombre, tamaño (1280x720), fondo
        visuals/
          <idVisual>/
            visual.json         ← tipo, posición, campos, formato
```

Procedimiento:
1. Pedir al usuario **guardar y cerrar Power BI Desktop** antes de editar archivos del reporte (Desktop no recarga cambios externos en caliente).
2. Leer un `page.json` y un `visual.json` existentes para copiar el `$schema` y la versión exacta que usa su Desktop. Si el reporte está vacío, pedir al usuario crear una página con una tarjeta cualquiera, guardar y usar ese archivo como plantilla.
3. Crear una carpeta por página y por visual con IDs únicos (20 caracteres hex, sin espacios). Actualizar `pages.json`.
4. Ejemplo de `visual.json` (tarjeta) — ajustar `$schema` al de la plantilla:
   ```json
   {
     "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.0.0/schema.json",
     "name": "a1b2c3d4e5f6a7b8c9d0",
     "position": { "x": 20, "y": 20, "z": 0, "width": 280, "height": 120 },
     "visual": {
       "visualType": "card",
       "query": {
         "queryState": {
           "Values": {
             "projections": [
               { "field": { "Measure": { "Expression": { "SourceRef": { "Entity": "_Medidas" } }, "Property": "Ventas Totales" } },
                 "queryRef": "_Medidas.Ventas Totales" }
             ]
           }
         }
       }
     }
   }
   ```
   Roles (buckets) por tipo de visual: `card` → Values · `clusteredColumnChart`/`clusteredBarChart`/`lineChart` → Category, Y (y Series) · `tableEx` → Values · `pivotTable` → Rows, Columns, Values · `slicer` → Values · `donutChart` → Category, Y · `gauge` → Y, TargetValue.
5. Layout base para lienzo 1280×720: franja superior (y 0–80) título y segmentadores; fila de tarjetas KPI (y 90–210); dos o tres visuales principales (y 220–700). Margen de 20 px.
6. Tema: si hay colores corporativos, crear un tema JSON (`dataColors`, `background`, `foreground`, `tableAccent`) y explicar al usuario cómo aplicarlo (`Vista > Temas > Buscar temas`), o registrarlo en `StaticResources` del reporte.
7. Pedir al usuario abrir el `.pbip`, revisar y enviar captura. Si Desktop muestra error al abrir, leer el mensaje, corregir el JSON y repetir.

## C. Entregables en `powerbi/salidas/`
- `modelo-datos.md` — tablas, relaciones, hallazgos.
- `diseno-tablero.md` — diseño aprobado.
- `medidas.md` — nombre, fórmula DAX, formato, descripción.
- `bitacora.md` — fecha, cambio realizado, quién lo aprobó.
