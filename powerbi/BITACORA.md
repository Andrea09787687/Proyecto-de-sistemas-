# Bitácora del proyecto — Agente Power BI ↔ Claude

> El agente lee este archivo al empezar para saber en qué va el proyecto. Al terminar una sesión de trabajo, agrega una entrada arriba (fecha, qué se hizo, qué quedó pendiente).

## Estado actual

| Pieza | Estado |
|---|---|
| Agente (`.claude/skills/power-bi-agent/`) con 7 fases | ✅ Listo |
| Manual de relaciones Aranda 9.5.57 (oficial + reglas validadas en producción) | ✅ Listo |
| Queries originales (Casos, Tareas, Especialista, Inventario ADM) | ✅ Guardadas |
| Vistas `bi.vw_BI_*` (las 4) | 🟡 Escritas y revisadas de sintaxis; **sin ejecutar en SSMS** |
| Generador de conexión (`herramientas/generar_conexion.py`) | ✅ Probado con datos de ejemplo |
| Primer tablero con el agente | ⏳ Pendiente: ejecutar vistas → "listo" → conexión |

## Pendientes
- [ ] Ejecutar las vistas en SSMS y corregir errores (revisar `dt.cause_nohtml` en Especialista).
- [ ] Decidir filtro de tipos en Tareas (`NOT IN (1,4)` vs. `NOT IN (1,2,3,4)`) y en Especialista (solo casos).
- [ ] `vw_BI_Casos_Resumen`: agregar semáforo ANS y calcular cronómetros una sola vez (rendimiento).
- [ ] Fecha de asignación (no existe en FACT; sacarla de `adw.FACT_ASDK_ITEM_REVISION`).
- [ ] Probar el MCP de Power BI en el equipo real (nombre del paquete y menús).
- [ ] Llenar `insumos/requerimientos-cliente.md` del próximo cliente.

## Historial
### 2026-11-09
- Se crea el agente con fases: recursos/conexión → manual y queries → preguntas → vistas → "listo" y conexión → construcción → validación/publicación.
- Se integran el manual oficial de Aranda y las lecciones del tablero GACEL / LÍNEA 3000 (sincronizar filtros, roles, mapas, validar datos reales).
- Vistas de Tareas y Especialista migradas a `adw.FACT_ASDK_ITEM`; semáforo ANS por cronómetros; tiempos en minutos (formato solo en Power BI y según lo pida el usuario).
