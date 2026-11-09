# Conexión Power BI ↔ Claude

> Nota para el agente: los nombres de paquetes y menús cambian con el tiempo. Si algún paso falla, pide al usuario revisar el README oficial: https://github.com/microsoft/powerbi-modeling-mcp

## 1. Recursos necesarios

| Recurso | Para qué | Obligatorio |
|---|---|---|
| **Windows 10/11** | Power BI Desktop y el MCP local solo corren en Windows | Sí |
| **Power BI Desktop** (versión reciente) | Donde vive el modelo y el reporte | Sí |
| **Claude Desktop** o **Claude Code** (plan Pro, Max, Team o Enterprise) | El cliente que usa el MCP | Sí |
| **Node.js LTS** (incluye `npx`) | Ejecutar el servidor MCP | Sí (si se instala vía npx) |
| **Power BI Modeling MCP** (Microsoft) | Puente que deja a Claude leer y modificar el modelo semántico | Sí |
| Acceso/credenciales a la **base de datos** (SQL Server, MySQL, PostgreSQL, Excel, SharePoint…) y su **driver/conector** | Cargar los datos | Sí |
| Licencia **Power BI Pro / PPU / Fabric** | Publicar y compartir en el servicio, usar el MCP remoto | Solo para publicar |
| **On-premises data gateway** | Actualizar en el servicio datos que están en servidores locales | Solo si se publica con datos locales |
| VS Code (opcional) | Alternativa para instalar el MCP como extensión | No |

## 2. Formas de conexión

1. **Power BI Modeling MCP (local)** — la principal. Claude se conecta a la instancia abierta de Power BI Desktop (o a una carpeta PBIP, o a un modelo en un workspace de Fabric) y puede: listar tablas/columnas, crear y editar relaciones, medidas DAX, columnas calculadas, tablas calculadas, jerarquías, ejecutar consultas DAX, revisar buenas prácticas, renombrar en bloque, traducir, etc.
2. **Claude conectado al computador del usuario (Remote Control)**: la forma que se usó en el tablero de Aerocivil. Una sesión de Claude Code (en la nube o en el app) trabaja directamente sobre una carpeta del computador del usuario donde está Power BI. Desde ahí Claude lee y edita el proyecto PBIP, los CSV y las queries, y puede usar el MCP local. Pasos:
   1. Instalar el **app de escritorio de Claude** en el computador donde está Power BI.
   2. En el app: `Configuración > Claude Code > Remote Control` → agregar la carpeta de trabajo (ej.: la carpeta del proyecto PBIP). No sirven la carpeta personal completa ni carpetas ocultas.
   3. Dejar el app abierto y el computador encendido mientras Claude trabaja. Si se cierra o se suspende, la conexión se cae ("se acaba de caer la conexión").
   4. En la sesión de Claude, pedir: *"Conéctate a mi computador"*. Claude muestra la carpeta y el usuario aprueba la conexión en el app. Arriba aparece el equipo como "Conectado".
   5. Limitación: Claude solo ve **ese** computador. Si el tablero final está en un servidor (ej.: un servidor del cliente), Claude no lo ve; ahí el usuario valida con los pasos de `publicacion-y-soporte.md`.
   > Esta función no está disponible en todas las cuentas. Si la carpeta no aparece en la lista, usar Claude Code instalado directamente en ese computador.
3. **Power BI MCP remoto (opcional)** — endpoint de Microsoft Fabric (`https://api.fabric.microsoft.com/v1/mcp/powerbi`) para **consultar** modelos ya publicados en el servicio con lenguaje natural/DAX. Requiere que el administrador del tenant habilite la opción correspondiente y autenticación con la cuenta corporativa (Entra ID). No crea reportes.

### Qué NO hace el MCP
- No escribe usuario/contraseña de la base de datos: **el usuario conecta el origen** en Power BI Desktop.
- No dibuja visuales directamente: las páginas y visuales se construyen editando el proyecto en formato **PBIP / PBIR** (archivos JSON), ver `construccion-reporte.md`.

## 3. Instalación y configuración

### Paso 1 — Instalar Node.js
Descargar la versión LTS de https://nodejs.org e instalar. Verificar en PowerShell:
```powershell
node -v
npx -v
```

### Paso 2 — Habilitar PBIP en Power BI Desktop
`Archivo > Opciones y configuración > Opciones > Características en versión preliminar` → activar **Guardar como proyecto de Power BI (.pbip)** y **Formato de informe mejorado de Power BI (PBIR)**. Reiniciar Power BI Desktop.
Luego `Archivo > Guardar como > Proyecto de Power BI (*.pbip)` dentro de `powerbi/proyecto/`.

### Paso 3A — Configurar en Claude Desktop
1. En Claude Desktop: `Configuración > Desarrollador > Editar configuración` (abre `%APPDATA%\Claude\claude_desktop_config.json`).
2. Agregar:
```json
{
  "mcpServers": {
    "powerbi-modeling-mcp": {
      "command": "npx",
      "args": ["-y", "@microsoft/powerbi-modeling-mcp@latest", "--start"]
    }
  }
}
```
3. Cerrar Claude Desktop por completo (también desde la bandeja del sistema) y abrirlo de nuevo. En el ícono de herramientas debe aparecer `powerbi-modeling-mcp`.

*Alternativa:* instalar en VS Code la extensión **Power BI Modeling MCP** y usar como `command` la ruta del ejecutable `powerbi-modeling-mcp.exe` que trae la extensión (carpeta `%USERPROFILE%\.vscode\extensions\analysis-services.powerbi-modeling-mcp-*\server\`), con `args: ["--start"]`.

### Paso 3B — Configurar en Claude Code
En PowerShell, dentro de la carpeta del proyecto:
```powershell
claude mcp add powerbi-modeling-mcp --scope project -- cmd /c npx -y @microsoft/powerbi-modeling-mcp@latest --start
```
(Esto crea/actualiza `.mcp.json`; hay un ejemplo en `powerbi/mcp.example.json`.) Verificar con `claude mcp list` o `/mcp` dentro de Claude Code.

### Paso 4 — Probar la conexión
1. Abrir el archivo en Power BI Desktop.
2. Pedir a Claude: *"Conéctate a mi Power BI Desktop abierto y lista las tablas del modelo."*
3. Claude listará las instancias locales y se conectará. La primera vez Claude pedirá permiso para usar la herramienta: aceptar.

### Paso 5 (opcional) — MCP remoto
Solo si el modelo ya está publicado y el administrador habilitó el MCP de Power BI en el portal de administración de Fabric. En Claude: `Configuración > Conectores > Agregar conector personalizado` con la URL `https://api.fabric.microsoft.com/v1/mcp/powerbi` e iniciar sesión con la cuenta corporativa. Si el tenant exige una aplicación de Entra ID, coordinar con TI.

## 4. Conectar la base de datos (lo hace el usuario)

Instrucciones que el agente debe dar, adaptadas al origen:

**SQL Server / Azure SQL**
1. `Inicio > Obtener datos > SQL Server`.
2. Servidor y base de datos. En **Opciones avanzadas > Instrucción SQL** pegar la query indicada por el agente (desde `powerbi/insumos/queries/`).
3. Modo: **Importar** (recomendado) o DirectQuery si los datos deben ser en tiempo real.
4. Autenticación: Windows o Base de datos (usuario/contraseña). → `Aceptar`.
5. En la vista previa, `Transformar datos` → renombrar la consulta con el nombre exacto que indicó el agente → `Cerrar y aplicar`.

**MySQL** (requiere instalar el *MySQL Connector/NET*): `Obtener datos > Base de datos MySQL` → servidor/base → instrucción SQL en opciones avanzadas → credenciales.

**PostgreSQL**: `Obtener datos > Base de datos PostgreSQL` → igual que arriba.

**Excel / CSV / carpeta**: `Obtener datos > Libro de Excel` (o `Texto/CSV`, `Carpeta`) → seleccionar hojas → `Transformar datos` → renombrar → `Cerrar y aplicar`.

**Query en Power Query (M)**: `Transformar datos > Nueva fuente > Consulta en blanco > Editor avanzado` → pegar el código M → renombrar la consulta.

Al terminar, el usuario guarda (`Ctrl+S`) y avisa al agente para que valide el modelo.
