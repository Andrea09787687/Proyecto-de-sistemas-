-- 1) Esquema propio para las vistas de BI (no se mezcla con las tablas de Aranda)
-- Ejecutar una vez en cada base (ASMS y ADM) con un usuario DBA.
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bi')
    EXEC('CREATE SCHEMA bi AUTHORIZATION dbo');
GO

-- 2) Usuario de solo lectura para Power BI (cambiar el nombre; la contraseña la define el DBA y NO se guarda en el repositorio)
-- CREATE LOGIN usuario_lectura_bi WITH PASSWORD = '<definir>';   -- en master, si no existe
-- CREATE USER  usuario_lectura_bi FOR LOGIN usuario_lectura_bi;  -- en esta base
GRANT SELECT ON SCHEMA::bi TO usuario_lectura_bi;
GO
-- Nota: la vista accede a tablas de dbo/adw. Por encadenamiento de propiedad (mismo dueño dbo),
-- el usuario NO necesita permisos sobre las tablas de Aranda, solo sobre el esquema bi.
