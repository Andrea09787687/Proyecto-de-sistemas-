# Cuestionario de diseño del tablero

Haz las preguntas por bloques (máx. 4–5 por mensaje). Salta las que ya se respondan con el manual, las queries o las imágenes. Ofrece opciones cuando ayude (ej.: "¿mensual, semanal o diaria?").

## Bloque 1 — Objetivo y audiencia
0. ¿Para qué cliente y qué proyecto(s) de Aranda es? ¿Qué tipos de caso entran (incidentes, requerimientos, problemas, cambios, tareas)?
1. ¿Para qué se va a usar el tablero? (seguimiento operativo, gerencial, análisis puntual)
2. ¿Quién lo va a ver? (gerencia, coordinadores, analistas, cliente externo)
3. ¿Qué decisiones se deben poder tomar con él?
4. ¿Cada cuánto se actualizan los datos? (diario, semanal, mensual, tiempo real)

## Bloque 2 — Indicadores (KPIs)
1. ¿Cuáles son los 3–6 indicadores principales? ¿Cómo se calcula cada uno?
2. ¿Hay metas/presupuesto contra el cual comparar? ¿Dónde están esos datos?
3. ¿Comparaciones de tiempo? (vs. mes anterior, vs. mismo periodo año anterior, acumulado del año)
4. ¿Umbrales de semáforo? (ej.: verde ≥ 95 %, amarillo 80–95 %, rojo < 80 %)

### Tiempos (siempre preguntar si el tablero tiene tiempos de atención/solución)
Los tiempos vienen de la base **en minutos**. Pregunta:
- ¿Los muestro en **minutos** o los convierto? Opciones: horas, días, formato `2 d 03 h 15 m`, o un **selector** para que el usuario elija la unidad en el tablero.
- Si son días: ¿un día = **24 h** (calendario del ANS configurado en Aranda) o = **8 h hábiles**?
- ¿Promedio, mediana o total? ¿Por caso, por especialista, por grupo?
No conviertas nada hasta que el usuario lo indique; si no responde, déjalo en minutos.

## Bloque 3 — Análisis y desgloses
0. ¿Qué campos necesita ver el cliente? (ej.: número de caso, asunto, estado, especialista, grupo, categoría, servicio, prioridad, fechas, ANS). Si tiene una lista o una imagen, que la envíe.
1. ¿Por qué dimensiones se quiere analizar? (fecha, región, sede, producto, cliente, responsable…)
2. ¿Qué filtros/segmentadores deben estar siempre visibles?
3. ¿Se necesita detalle a nivel de registro (tabla) o exportar a Excel?
4. ¿Navegación entre páginas, drill-through o tooltips con detalle?

## Bloque 4 — Estructura y diseño visual
1. ¿Cuántas páginas imaginas y qué va en cada una? (ej.: Resumen, Detalle, Tendencias)
2. **¿Tienes una imagen, boceto o tablero de ejemplo de lo que quieres ver?** Compártelo en el chat o en `powerbi/insumos/imagenes-referencia/`.
3. ¿Colores corporativos, logo o tema? (códigos HEX si los tienes)
4. ¿Se verá en computador, en pantalla grande o en celular?

## Bloque 5 — Seguridad y publicación
1. ¿Cada usuario debe ver solo su información? (seguridad por filas – RLS) ¿Con qué campo se filtra?
2. ¿Se publicará en el servicio de Power BI? ¿En qué workspace?
3. ¿Los datos están en un servidor local? (se necesitaría gateway para actualizar)

## Al analizar imágenes de referencia
Describe y confirma con el usuario:
- Número de páginas y orden.
- Por cada visual: tipo (tarjeta, barras, líneas, mapa, tabla, matriz, anillo, medidor…), posición aproximada (arriba-izquierda, etc.), tamaño relativo, campos que parece usar.
- Segmentadores y su ubicación.
- Colores, fuentes, fondo, encabezado/logo.
- Qué partes de la imagen no se pueden mapear a datos existentes (y qué datos faltarían).
