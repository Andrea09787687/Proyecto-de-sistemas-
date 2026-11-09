# Queries

Un archivo por tabla, con el **mismo nombre que tendrá la tabla en Power BI**:
- `Ventas.sql` → consulta SQL
- `Clientes.m` → código Power Query (M)
- `Medidas.dax` → medidas DAX existentes (opcional)

Al inicio de cada archivo agrega un comentario con el origen, por ejemplo:
```sql
-- Origen: SQL Server  | Servidor: SRV-BI01 | Base: Comercial
-- Tabla en Power BI: Ventas
SELECT ...
```
No incluyas usuarios ni contraseñas.
