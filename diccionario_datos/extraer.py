"""Extrae solo definiciones DDL de BD15.sql; los bloques INSERT se descartan."""
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "Practica03" / "backups" / "BD15.sql"
OUT = ROOT / "diccionario_datos"

objects = []
active = None
kind = None

def begin_kind(line):
    s = line.strip()
    if re.search(r"\bCREATE\s+TABLE\b", s, re.I): return "table"
    if re.search(r"\bCREATE\s+VIEW\b", s, re.I): return "view"
    if re.search(r"\bCREATE\b.*?\bTRIGGER\b", s, re.I): return "trigger"
    if re.search(r"\bCREATE\b.*?\bPROCEDURE\b", s, re.I): return "procedure"
    if re.search(r"\bCREATE\b.*?\bFUNCTION\b", s, re.I): return "function"
    return None

def is_complete(k, text, stripped):
    if k == "table": return stripped.endswith(";")
    if k in ("procedure", "function", "trigger"):
        return bool(re.search(r"END\s*(?:\*/)?\s*;;?\s*$", text, re.I))
    return stripped.endswith(";") or stripped.endswith("*/;") or stripped.endswith("*/;;")

def add_object(k, text):
    patterns = {
        "table": r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?`([^`]+)",
        "view": r"VIEW\s+`([^`]+)",
        "trigger": r"TRIGGER\s+`([^`]+)",
        "procedure": r"PROCEDURE\s+`([^`]+)",
        "function": r"FUNCTION\s+`([^`]+)",
    }
    match = re.search(patterns[k], text, re.I)
    if match:
        objects.append({"kind": k, "name": match.group(1), "sql": text})

with SRC.open("r", encoding="utf-8", errors="replace") as source:
    for line in source:
        # INSERT lines are deliberately discarded before any buffering or parsing.
        if active is None:
            if line.lstrip().upper().startswith("INSERT INTO "):
                continue
            candidate = begin_kind(line)
            if candidate is None:
                continue
            active, kind = [line], candidate
        else:
            active.append(line)
        blob = "".join(active)
        if is_complete(kind, blob, line.strip()):
            add_object(kind, blob)
            active, kind = None, None

counts = {k: sum(item["kind"] == k for item in objects)
          for k in ("table", "view", "trigger", "procedure", "function")}
payload = {
    "database": "db_test",
    "mysql_version": "8.0.36",
    "source": "Practica03/backups/BD15.sql",
    "source_date": "2026-10-27",
    "extraction_scope": "Solo CREATE TABLE/VIEW/TRIGGER/PROCEDURE/FUNCTION. INSERT INTO se descarta antes de acumular contenido.",
    "counts": counts,
    "objects": objects,
}
(OUT / "estructura.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(counts, ensure_ascii=False))
