# Agente Power BI ↔ Claude

Carpeta de trabajo del agente `power-bi-agent` (definido en `.claude/skills/power-bi-agent/`).

## Cómo usarlo
1. Abre Claude Code en la raíz del repositorio y escribe `/power-bi-agent` (o simplemente "quiero armar un tablero de Power BI").
2. El agente responde *"¿Qué quieres realizar?"* y avanza por fases, con una pausa ("listo") al final de cada una:
   1. Preguntas: cliente, objetivo, campos, filtros, páginas e imágenes de referencia.
   2. Instalación y conexión de Claude con Power BI.
   3. Diseño de las **vistas** SQL y cómo ejecutarlas en SSMS.
   4. Conexión de Power BI a la base con los datos que envías (sin contraseña).
   5. Diseño del tablero: modelo, medidas y páginas.
   6. Validar y publicar, cuando lo pidas.

## Dónde dejar cada cosa
| Carpeta | Qué va |
|---|---|
| `insumos/manual-relaciones/` | Manual de relaciones (PDF, Word, Excel o la plantilla `.md`) |
| `insumos/queries/` | Queries SQL, Power Query (M) o DAX — un archivo por tabla |
| `insumos/imagenes-referencia/` | Capturas o bocetos de cómo quieres ver el tablero |
| `insumos/datos/` | Archivos Excel/CSV de origen (no subir datos sensibles al repositorio) |
| `insumos/vistas/` | Scripts de las vistas `bi.vw_BI_*` (se ejecutan en SSMS antes de conectar) |
| `insumos/requerimientos-cliente.md` | Formulario: qué quiere ver el cliente (filtros, KPIs, páginas, campos) |
| `conexion.ejemplo.json` | Copiar como `conexion.json` con servidor/base/usuario (sin contraseña) |
| `herramientas/generar_conexion.py` | Genera las consultas de Power BI desde las queries |
| `proyecto/` | El archivo Power BI guardado como proyecto `.pbip` |
| `salidas/` | Documentos que genera el agente |

`mcp.example.json` es un ejemplo de configuración del MCP para Claude Code (renómbralo a `.mcp.json` en la raíz si quieres usarlo).

## Cómo alimentar el proyecto
Cada cosa nueva va en su carpeta y el agente la usa la próxima vez:

| Si tienes… | Déjalo en… | El agente… |
|---|---|---|
| Una query nueva | `insumos/queries/<NombreTabla>.sql` | La convierte en vista `bi.vw_BI_<NombreTabla>` |
| Un dato nuevo del manual o una regla validada en producción | `insumos/manual-relaciones/aranda-relaciones.md` (sección 1 si es regla validada) | La aplica en vistas y medidas; las reglas validadas prevalecen sobre la documentación |
| Lo que pide un cliente | `insumos/requerimientos-cliente.md` (o una copia por cliente) | Solo pregunta lo que falte |
| Imágenes de cómo lo quiere ver | `insumos/imagenes-referencia/` | Replica el diseño |
| Una lección aprendida (error, solución, truco de publicación) | `.claude/skills/power-bi-agent/referencias/publicacion-y-soporte.md` | La usa en soporte |
| Avance del desarrollo del agente | `BITACORA.md` | (uso interno del equipo; el agente no la muestra) |

Puedes pedírselo directamente: *"agrega esta query al proyecto"*, *"guarda esto como regla de Aranda"*, *"anota en la bitácora que…"*.

## Proyecto en Claude (claude.ai / app de escritorio)
El texto para "Instrucciones del proyecto" está en `proyecto-claude/INSTRUCCIONES_PROYECTO.md`. Como conocimiento del proyecto se suben: las guías de `.claude/skills/power-bi-agent/referencias/`, `insumos/manual-relaciones/aranda-relaciones.md`, `insumos/requerimientos-cliente.md`, las queries y las vistas (de ejemplo).
