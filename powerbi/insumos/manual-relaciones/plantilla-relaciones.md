# Manual de relaciones — <nombre del proyecto>

## Tablas
| Tabla | Tipo (hecho/dimensión) | Llave principal | Query de origen | Descripción |
|---|---|---|---|---|
| Ventas | Hecho | IdVenta | ventas.sql | Una fila por venta |
| Clientes | Dimensión | IdCliente | clientes.sql | Maestro de clientes |

## Relaciones
| Tabla origen (muchos) | Columna | Tabla destino (uno) | Columna | Cardinalidad | Filtro | Activa |
|---|---|---|---|---|---|---|
| Ventas | IdCliente | Clientes | IdCliente | *:1 | Única | Sí |
| Ventas | FechaVenta | Calendario | Date | *:1 | Única | Sí |

## Reglas de negocio / observaciones
- 
