# Agente Power BI ↔ Claude

Carpeta de trabajo del agente `power-bi-agent` (definido en `.claude/skills/power-bi-agent/`).

## Cómo usarlo
1. Abre Claude Code en la raíz del repositorio y escribe `/power-bi-agent` (o simplemente "quiero armar un tablero de Power BI").
2. El agente avanza por fases:
   1. Explica los recursos y cómo conectar Power BI con Claude (MCP).
   2. Lee el manual de relaciones y las queries de `insumos/`.
   3. Te hace preguntas para diseñar el tablero (puedes enviarle imágenes de referencia).
   4. Verifica que Claude esté conectado a tu Power BI Desktop y te guía para conectar la base de datos.
   5. Crea relaciones, medidas DAX y las páginas del reporte.

## Dónde dejar cada cosa
| Carpeta | Qué va |
|---|---|
| `insumos/manual-relaciones/` | Manual de relaciones (PDF, Word, Excel o la plantilla `.md`) |
| `insumos/queries/` | Queries SQL, Power Query (M) o DAX — un archivo por tabla |
| `insumos/imagenes-referencia/` | Capturas o bocetos de cómo quieres ver el tablero |
| `insumos/datos/` | Archivos Excel/CSV de origen (no subir datos sensibles al repositorio) |
| `insumos/requerimientos-cliente.md` | Formulario: qué quiere ver el cliente (filtros, KPIs, páginas, campos) |
| `conexion.ejemplo.json` | Copiar como `conexion.json` con servidor/base/usuario (sin contraseña) |
| `herramientas/generar_conexion.py` | Genera las consultas de Power BI desde las queries |
| `proyecto/` | El archivo Power BI guardado como proyecto `.pbip` |
| `salidas/` | Documentos que genera el agente |

`mcp.example.json` es un ejemplo de configuración del MCP para Claude Code (renómbralo a `.mcp.json` en la raíz si quieres usarlo).
