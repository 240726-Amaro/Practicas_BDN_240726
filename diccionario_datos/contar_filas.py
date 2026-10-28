"""Cuenta tuplas de INSERT en streaming; solo persiste totales por tabla."""
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "Practica03" / "backups" / "BD15.sql"
OUT = ROOT / "diccionario_datos" / "estructura.json"
counts = {}
table = None
in_insert = False
values_started = False
quote = None
escaped = False
depth = 0
DELIMITER = re.compile(r"""['"`();\\]""")

def take_header(line):
    match = re.match(r"\s*INSERT\s+INTO\s+`([\w$]+)`", line, re.I)
    return match.group(1) if match else None

with SOURCE.open("r", encoding="utf-8", errors="replace") as source:
    for line in source:
        prefix = line.lstrip()[:500]
        if not in_insert and prefix.startswith(("CREATE", "/*!")) and re.search(r"\bVIEW\b", prefix, re.I):
            # In mysqldump, view/trigger/routine DDL follows the table data section.
            break
        if not in_insert:
            if not line.lstrip().upper().startswith("INSERT INTO `"):
                continue
            table = take_header(line)
            if table is None:
                continue
            counts.setdefault(table, 0)
            in_insert = True
            values_started = False
            quote = None
            escaped = False
            depth = 0
        start = 0
        if not values_started:
            marker = re.search(r"\bVALUES\b", line, re.I)
            if not marker: continue
            values_started = True
            start = marker.end()
        # The regex engine locates only SQL delimiters; data text stays opaque.
        escaped_at = None
        skip_quote = False
        for token_match in DELIMITER.finditer(line, start):
            pos = token_match.start(); token = token_match.group(0)
            if escaped_at is not None:
                if pos == escaped_at+1: escaped_at = None; continue
                escaped_at = None
            if quote:
                if token == "\\": escaped_at = pos
                elif token == quote:
                    if skip_quote: skip_quote = False
                    elif pos+1 < len(line) and line[pos+1] == quote: skip_quote = True
                    else: quote = None
                continue
            if token in ("'", '"', '`'):
                quote = token; continue
            if token == "(":
                if depth == 0: counts[table] += 1
                depth += 1
            elif token == ")" and depth: depth -= 1
            elif token == ";" and depth == 0:
                in_insert = False; table = None; values_started = False; break

data = json.loads(OUT.read_text(encoding="utf-8"))
for obj in data.get("objects", []):
    if obj.get("kind") == "table": counts.setdefault(obj["name"], 0)
data["row_counts"] = counts
data["row_count_source"] = "Conteo streaming de tuplas VALUES en BD15.sql; valores de fila descartados; 2026-10-27"
OUT.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
total = sum(counts.values())
print(json.dumps({"tablas_con_insert": len(counts), "total_filas": total,
                  "tablas_vacias_o_sin_insert": sum(value == 0 for value in counts.values())}, ensure_ascii=False))
