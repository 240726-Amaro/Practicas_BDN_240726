# Diccionario de datos de BD17

Entregables generados desde el DDL extraído de `Practica03/backups/BD17.sql`: `diccionario_datos.md`, `diccionario_datos.xlsx`, `estructura.json`, `diagrama_er.mmd`, `schema.dbml` y el sitio estático `/docs`. No se guardan valores de filas del volcado. `estructura.json` contiene solo CREATE y metadatos del esquema más conteos agregados por tabla.

## Regeneración segura

Desde la raíz del repositorio, con Python 3:

```powershell
python diccionario_datos\extraer.py
python diccionario_datos\contar_filas.py
python diccionario_datos\generar.py
python diccionario_datos\generar_modelos.py
python diccionario_datos\generar_sitio.py
python diccionario_datos\validar.py
python diccionario_datos\validar_sitio.py
```

`extraer.py` descarta INSERT y conserva exclusivamente CREATE TABLE/VIEW/TRIGGER/PROCEDURE/FUNCTION. `contar_filas.py` procesa las tuplas de INSERT en streaming y persiste únicamente conteos por tabla. No importa el volcado en `BD17`. El XLSX tiene filtros y encabezado congelado, e incluye volumen de datos, observaciones, dominios, convenciones e historial.
