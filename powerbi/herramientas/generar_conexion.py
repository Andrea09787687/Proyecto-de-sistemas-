"""
Genera la conexión de Power BI a partir de las queries SQL y de los datos de conexión.

Lee:
  powerbi/conexion.json            datos del servidor (SIN contraseña) y valores de parámetros
  powerbi/insumos/queries/*.sql    una query por tabla (el nombre del archivo = nombre de la tabla)

Escribe en powerbi/salidas/conexion/:
  00_Parametros.m        parámetros de Power Query (servidor, base y los @ de las queries)
  <Tabla>.m              consulta Power Query lista para pegar o para crear con el MCP
  INSTRUCCIONES.md       pasos para el usuario

Uso:
  python powerbi/herramientas/generar_conexion.py
  python powerbi/herramientas/generar_conexion.py --config otra_conexion.json
"""
import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]          # carpeta powerbi/
QUERIES = RAIZ / "insumos" / "queries"
SALIDA = RAIZ / "salidas" / "conexion"

VARIABLE = re.compile(r"@([A-Za-z_][A-Za-z0-9_]*)")


def nombre_parametro(var: str) -> str:
    return "p" + var[:1].upper() + var[1:].lower()


def literal_m(tipo_sql: str, valor) -> tuple[str, str]:
    """Devuelve (literal M, tipo de parámetro M)."""
    t = tipo_sql.upper()
    if t.startswith(("INT", "BIGINT", "SMALLINT", "DECIMAL", "NUMERIC", "FLOAT")):
        return str(valor), "Number"
    if t.startswith(("DATE", "DATETIME")):
        d = date.fromisoformat(str(valor)[:10])
        return f"#date({d.year}, {d.month}, {d.day})", "Date"
    return '"' + str(valor).replace('"', '""') + '"', "Text"


def texto_declare(var: str, tipo_sql: str) -> str:
    """Expresión M que produce:  DECLARE @var TIPO = valor;"""
    p = nombre_parametro(var)
    t = tipo_sql.upper()
    if t.startswith(("INT", "BIGINT", "SMALLINT", "DECIMAL", "NUMERIC", "FLOAT")):
        valor = f"Number.ToText({p})"
    elif t.startswith(("DATE", "DATETIME")):
        valor = f"\"'\" & Date.ToText({p}, \"yyyy-MM-dd\") & \"'\""
    else:
        valor = f"\"'\" & Text.Replace({p}, \"'\", \"''\") & \"'\""
    return f"\"DECLARE @{var} {tipo_sql} = \" & {valor} & \";#(lf)\""


def sql_a_cadena_m(sql: str) -> str:
    lineas = sql.replace("\r\n", "\n").rstrip().rstrip(";").split("\n")
    partes = ['"' + l.replace('"', '""') + '#(lf)"' for l in lineas]
    return " &\n        ".join(partes)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", default=str(RAIZ / "conexion.json"))
    args = ap.parse_args()

    cfg_path = Path(args.config)
    if not cfg_path.exists():
        print(f"No existe {cfg_path}. Copia powerbi/conexion.ejemplo.json a powerbi/conexion.json y llénalo.")
        return 1
    cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
    if any(k.lower() in ("password", "contrasena", "contraseña", "clave") for k in cfg):
        print("conexion.json no debe tener contraseña. Bórrala: Power BI la pide una sola vez al actualizar.")
        return 1

    params_cfg = {k.lower(): v for k, v in cfg.get("parametros", {}).items()}
    overrides = cfg.get("tablas", {})
    SALIDA.mkdir(parents=True, exist_ok=True)

    archivos = sorted(QUERIES.glob("*.sql"))
    if not archivos:
        print(f"No hay queries .sql en {QUERIES}")
        return 1

    usados: dict[str, str] = {}          # var en minúscula -> tipo sql
    bases_extra: set[str] = set()
    faltantes: set[str] = set()

    for archivo in archivos:
        tabla = archivo.stem
        sql = archivo.read_text(encoding="utf-8-sig")
        variables = []
        for v in VARIABLE.findall(re.sub(r"--[^\n]*", "", sql)):
            if v.lower() not in [x.lower() for x in variables]:
                variables.append(v)

        declares = []
        for v in variables:
            pc = params_cfg.get(v.lower())
            if pc is None:
                faltantes.add(v)
                continue
            usados[v.lower()] = pc["tipo"]
            declares.append(texto_declare(v.lower(), pc["tipo"]))

        base = "pBaseDatos"
        if tabla in overrides and overrides[tabla].get("base_datos"):
            base = "pBase_" + re.sub(r"\W", "_", overrides[tabla]["base_datos"])
            bases_extra.add(overrides[tabla]["base_datos"])

        encabezado = " &\n        ".join(declares) if declares else '""'
        m = (
            f"// Tabla: {tabla}  (generado desde insumos/queries/{archivo.name})\n"
            "let\n"
            f"    Encabezado =\n        {encabezado},\n"
            f"    Consulta =\n        {sql_a_cadena_m(sql)},\n"
            f"    Origen = Sql.Database(pServidor, {base}, [Query = Encabezado & Consulta, CommandTimeout = #duration(0, 0, 30, 0)])\n"
            "in\n"
            "    Origen\n"
        )
        (SALIDA / f"{tabla}.m").write_text(m, encoding="utf-8")
        print(f"  ✓ {tabla}.m  (parámetros: {', '.join(variables) or 'ninguno'})")

    # Parámetros
    lineas = ["// Crear cada bloque como parámetro: Transformar datos > Administrar parámetros > Nuevo",
              "// o con el MCP (expresión con meta IsParameterQuery=true).", ""]

    def param(nombre, literal, tipo):
        lineas.append(f"// {nombre}")
        lineas.append(f'{literal} meta [IsParameterQuery = true, Type = "{tipo}", IsParameterQueryRequired = true]')
        lineas.append("")

    param("pServidor", literal_m("VARCHAR", cfg["servidor"])[0], "Text")
    param("pBaseDatos", literal_m("VARCHAR", cfg["base_datos"])[0], "Text")
    for b in sorted(bases_extra):
        param("pBase_" + re.sub(r"\W", "_", b), literal_m("VARCHAR", b)[0], "Text")
    for v, tipo in usados.items():
        lit, tipo_m = literal_m(tipo, params_cfg[v]["valor"])
        param(nombre_parametro(v), lit, tipo_m)
    (SALIDA / "00_Parametros.m").write_text("\n".join(lineas), encoding="utf-8")

    auth = cfg.get("autenticacion", "sql").lower()
    paso_cred = (
        "Power BI usará tu usuario de Windows; si pide credenciales elige **Windows > Usar mis credenciales actuales**."
        if auth == "windows" else
        f"Cuando Power BI pida credenciales elige **Base de datos** y escribe el usuario `{cfg.get('usuario', '<usuario>')}` y tu contraseña. Solo se pide una vez por equipo."
    )
    tablas_txt = "\n".join(f"   - `{a.stem}` ← `salidas/conexion/{a.stem}.m`" for a in archivos)
    (SALIDA / "INSTRUCCIONES.md").write_text(
        f"""# Conexión generada

Servidor: `{cfg['servidor']}` · Base: `{cfg['base_datos']}` · Autenticación: `{auth}`

## Opción A — La crea el agente (MCP de Power BI conectado)
El agente crea los parámetros de `00_Parametros.m` y una tabla por cada archivo `.m`, y pide actualizar.
Tú solo haces el paso de credenciales.

## Opción B — A mano (5 minutos)
1. Power BI Desktop > **Transformar datos**.
2. **Administrar parámetros > Nuevo** por cada bloque de `00_Parametros.m` (nombre, tipo y valor actual).
3. Por cada tabla: **Nueva fuente > Consulta en blanco > Editor avanzado**, pega el contenido del `.m` y renombra la consulta con el nombre de la tabla:
{tablas_txt}
4. {paso_cred}
5. Si aparece *"Se requiere permiso para ejecutar esta consulta nativa"*, dale **Ejecutar**.
6. **Cerrar y aplicar**.

Para cambiar proyecto, grupos o fechas después: **Inicio > Transformar datos > Editar parámetros**.
""",
        encoding="utf-8",
    )
    if faltantes:
        print(f"\n⚠ Variables sin valor en conexion.json > parametros: {', '.join(sorted(faltantes))}")
        return 2
    print(f"\nListo. Archivos en {SALIDA}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
