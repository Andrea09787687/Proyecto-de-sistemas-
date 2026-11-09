"""
Genera la conexión de Power BI (parámetros + una consulta Power Query por tabla).

Dos modos (campo "modo" en conexion.json):
  "vista" (recomendado)  Power BI lee las vistas <esquema>.vw_BI_<Tabla> creadas en la base
                         (scripts en powerbi/insumos/vistas/) y filtra por fecha con parámetros.
  "query"                Power BI ejecuta la query completa de powerbi/insumos/queries/<Tabla>.sql
                         con los parámetros @ resueltos con DECLARE.

Lee powerbi/conexion.json (servidor, base, usuario; NUNCA la contraseña).
Escribe en powerbi/salidas/conexion/: 00_Parametros.m, <Tabla>.m e INSTRUCCIONES.md

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
VISTAS = RAIZ / "insumos" / "vistas"
SALIDA = RAIZ / "salidas" / "conexion"

VARIABLE = re.compile(r"@([A-Za-z_][A-Za-z0-9_]*)")
NUMERICOS = ("INT", "BIGINT", "SMALLINT", "DECIMAL", "NUMERIC", "FLOAT")


# ---------- utilidades ----------
def nombre_parametro(var: str) -> str:
    return "p" + var[:1].upper() + var[1:].lower()


def literal_m(tipo_sql: str, valor) -> tuple[str, str]:
    """Devuelve (literal M, tipo de parámetro M)."""
    t = tipo_sql.upper()
    if t.startswith(NUMERICOS):
        return str(valor), "Number"
    if t.startswith(("DATE", "DATETIME")):
        d = date.fromisoformat(str(valor)[:10])
        return f"#date({d.year}, {d.month}, {d.day})", "Date"
    return '"' + str(valor).replace('"', '""') + '"', "Text"


def texto_declare(var: str, tipo_sql: str) -> str:
    """Expresión M que produce:  DECLARE @var TIPO = valor;"""
    p = nombre_parametro(var)
    t = tipo_sql.upper()
    if t.startswith(NUMERICOS):
        valor = f"Number.ToText({p})"
    elif t.startswith(("DATE", "DATETIME")):
        valor = f"\"'\" & Date.ToText({p}, \"yyyy-MM-dd\") & \"'\""
    else:
        valor = f"\"'\" & Text.Replace({p}, \"'\", \"''\") & \"'\""
    return f"\"DECLARE @{var} {tipo_sql} = \" & {valor} & \";#(lf)\""


def sql_a_cadena_m(sql: str) -> str:
    lineas = sql.replace("\r\n", "\n").rstrip().rstrip(";").split("\n")
    return " &\n        ".join('"' + l.replace('"', '""') + '#(lf)"' for l in lineas)


def nombre_param_base(b: str) -> str:
    return "pBase_" + re.sub(r"\W", "_", b)


def base_de(tabla: str, overrides: dict, extra: set) -> str:
    b = overrides.get(tabla, {}).get("base_datos")
    if not b:
        return "pBaseDatos"
    extra.add(b)
    return nombre_param_base(b)


class Parametros:
    def __init__(self):
        self.lineas = ["// Crear cada bloque como parámetro: Transformar datos > Administrar parámetros > Nuevo",
                       "// (o con el MCP: expresión con nombre y meta IsParameterQuery = true).", ""]

    def agregar(self, nombre: str, literal: str, tipo: str):
        self.lineas += [f"// {nombre}",
                        f'{literal} meta [IsParameterQuery = true, Type = "{tipo}", IsParameterQueryRequired = true]', ""]

    def guardar(self):
        (SALIDA / "00_Parametros.m").write_text("\n".join(self.lineas), encoding="utf-8")


def escribir_instrucciones(cfg: dict, tablas: list[str], vistas: bool):
    auth = cfg.get("autenticacion", "sql").lower()
    paso_cred = (
        "Power BI usará tu usuario de Windows; si pide credenciales elige **Windows > Usar mis credenciales actuales**."
        if auth == "windows" else
        f"Cuando Power BI pida credenciales elige **Base de datos** y escribe el usuario `{cfg.get('usuario', '<usuario>')}` "
        "y tu contraseña. Solo se pide una vez por equipo."
    )
    previo = ("## Paso 0 — Crear las vistas (DBA, en SSMS)\n"
              "Ejecutar `insumos/vistas/00_esquema_y_permisos.sql` y luego cada `vw_BI_*.sql` "
              "(la de ADM en la base de ADM). Verificar con `SELECT TOP 10 * FROM bi.vw_BI_Casos_Resumen`.\n\n") if vistas else ""
    nativa = "" if vistas else "5. Si aparece *\"Se requiere permiso para ejecutar esta consulta nativa\"*, dale **Ejecutar**.\n"
    lista = "\n".join(f"   - `{t}` ← `salidas/conexion/{t}.m`" for t in tablas)
    (SALIDA / "INSTRUCCIONES.md").write_text(
        f"""# Conexión generada

Servidor: `{cfg['servidor']}` · Base: `{cfg['base_datos']}` · Autenticación: `{auth}` · Modo: `{'vista' if vistas else 'query'}`

{previo}## Opción A — La crea el agente (MCP de Power BI conectado)
El agente crea los parámetros de `00_Parametros.m` y una tabla por cada archivo `.m`, y pide actualizar.
Tú solo haces el paso de credenciales.

## Opción B — A mano (5 minutos)
1. Power BI Desktop > **Transformar datos**.
2. **Administrar parámetros > Nuevo** por cada bloque de `00_Parametros.m` (nombre, tipo y valor actual).
3. Por cada tabla: **Nueva fuente > Consulta en blanco > Editor avanzado**, pega el contenido del `.m` y renombra la consulta:
{lista}
4. {paso_cred}
{nativa}6. **Cerrar y aplicar**.

Para cambiar el periodo u otros parámetros después: **Inicio > Transformar datos > Editar parámetros**.
""", encoding="utf-8")


# ---------- modos ----------
def modo_vista(cfg: dict, overrides: dict) -> int:
    esquema = cfg.get("esquema_vistas", "bi")
    archivos = sorted(VISTAS.glob("vw_BI_*.sql"))
    if not archivos:
        print(f"No hay vistas vw_BI_*.sql en {VISTAS}")
        return 1
    extra: set[str] = set()
    usa_fechas = False
    tablas = []
    for a in archivos:
        vista = a.stem
        tabla = vista[len("vw_BI_"):]
        tablas.append(tabla)
        col = overrides.get(tabla, {}).get("columna_fecha")
        base = base_de(tabla, overrides, extra)
        pasos = [
            f"    Origen = Sql.Database(pServidor, {base}, [CommandTimeout = #duration(0, 0, 30, 0)])",
            f'    Vista = Origen{{[Schema = "{esquema}", Item = "{vista}"]}}[Data]',
        ]
        ultimo = "Vista"
        if col:
            usa_fechas = True
            c = '[#"' + col.replace('"', '""') + '"]'
            pasos.append(f"    Filtrado = Table.SelectRows(Vista, each {c} >= DateTime.From(pFechaIni) "
                         f"and {c} < DateTime.From(Date.AddDays(pFechaFin, 1)))")
            ultimo = "Filtrado"
        m = (f"// Tabla: {tabla}  (lee {esquema}.{vista}; script en insumos/vistas/{a.name})\n"
             "let\n" + ",\n".join(pasos) + f"\nin\n    {ultimo}\n")
        (SALIDA / f"{tabla}.m").write_text(m, encoding="utf-8")
        print(f"  ✓ {tabla}.m  ← {esquema}.{vista}" + (f"  (filtro de fecha: {col})" if col else ""))

    p = Parametros()
    p.agregar("pServidor", literal_m("VARCHAR", cfg["servidor"])[0], "Text")
    p.agregar("pBaseDatos", literal_m("VARCHAR", cfg["base_datos"])[0], "Text")
    for b in sorted(extra):
        p.agregar(nombre_param_base(b), literal_m("VARCHAR", b)[0], "Text")
    if usa_fechas:
        f = cfg.get("fechas", {})
        p.agregar("pFechaIni", literal_m("DATE", f.get("inicio", "2024-01-01"))[0], "Date")
        p.agregar("pFechaFin", literal_m("DATE", f.get("fin", date.today().isoformat()))[0], "Date")
    p.guardar()
    escribir_instrucciones(cfg, tablas, vistas=True)
    print(f"\nListo. Archivos en {SALIDA}")
    return 0


def modo_query(cfg: dict, overrides: dict) -> int:
    params_cfg = {k.lower(): v for k, v in
                  (cfg.get("parametros") or cfg.get("_parametros_solo_modo_query") or {}).items()}
    archivos = sorted(QUERIES.glob("*.sql"))
    if not archivos:
        print(f"No hay queries .sql en {QUERIES}")
        return 1
    usados: dict[str, str] = {}
    extra: set[str] = set()
    faltantes: set[str] = set()
    for a in archivos:
        tabla = a.stem
        sql = a.read_text(encoding="utf-8-sig")
        variables: list[str] = []
        for v in VARIABLE.findall(re.sub(r"--[^\n]*", "", sql)):
            if v.lower() not in (x.lower() for x in variables):
                variables.append(v)
        declares = []
        for v in variables:
            pc = params_cfg.get(v.lower())
            if pc is None:
                faltantes.add(v)
                continue
            usados[v.lower()] = pc["tipo"]
            declares.append(texto_declare(v.lower(), pc["tipo"]))
        base = base_de(tabla, overrides, extra)
        encabezado = " &\n        ".join(declares) if declares else '""'
        m = (f"// Tabla: {tabla}  (generado desde insumos/queries/{a.name})\n"
             "let\n"
             f"    Encabezado =\n        {encabezado},\n"
             f"    Consulta =\n        {sql_a_cadena_m(sql)},\n"
             f"    Origen = Sql.Database(pServidor, {base}, [Query = Encabezado & Consulta, "
             "CommandTimeout = #duration(0, 0, 30, 0)])\n"
             "in\n    Origen\n")
        (SALIDA / f"{tabla}.m").write_text(m, encoding="utf-8")
        print(f"  ✓ {tabla}.m  (parámetros: {', '.join(variables) or 'ninguno'})")

    p = Parametros()
    p.agregar("pServidor", literal_m("VARCHAR", cfg["servidor"])[0], "Text")
    p.agregar("pBaseDatos", literal_m("VARCHAR", cfg["base_datos"])[0], "Text")
    for b in sorted(extra):
        p.agregar(nombre_param_base(b), literal_m("VARCHAR", b)[0], "Text")
    for v, tipo in usados.items():
        lit, tipo_m = literal_m(tipo, params_cfg[v]["valor"])
        p.agregar(nombre_parametro(v), lit, tipo_m)
    p.guardar()
    escribir_instrucciones(cfg, [a.stem for a in archivos], vistas=False)
    if faltantes:
        print(f"\n⚠ Variables sin valor en conexion.json > parametros: {', '.join(sorted(faltantes))}")
        return 2
    print(f"\nListo. Archivos en {SALIDA}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", default=str(RAIZ / "conexion.json"))
    args = ap.parse_args()

    cfg_path = Path(args.config)
    if not cfg_path.exists():
        print(f"No existe {cfg_path}. Copia powerbi/conexion.ejemplo.json a powerbi/conexion.json y llénalo.")
        return 1
    cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
    if any(k.lower() in ("password", "pwd", "contrasena", "contraseña", "clave") for k in cfg):
        print("conexion.json no debe tener contraseña. Bórrala: Power BI la pide una sola vez al actualizar.")
        return 1
    SALIDA.mkdir(parents=True, exist_ok=True)
    overrides = cfg.get("tablas", {})
    if cfg.get("modo", "vista").lower() == "vista":
        return modo_vista(cfg, overrides)
    return modo_query(cfg, overrides)


if __name__ == "__main__":
    sys.exit(main())
