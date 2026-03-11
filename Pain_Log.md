# Onboarding Log - Django RealWorld

#Instructions
*A numbered list of every friction point encountered.*

*Tag each entry:*
- [MISSING_DOC] — Step not mentioned in README
- [IMPLICIT_DEP] — Tool/version assumed but not declared
- [ENV_GAP] — Environment variable or config file undocumented
- [BROKEN_CMD] — Command in README fails as written
- [SILENT_FAIL] — Process exits 0 but system doesn't work
- [VERSION_HELL] — Requires specific runtime version, not declared

1. **[MISSING_DOC]**

* La descripión sobre el proyecto y de que trata es muy baga; no hay muchos detalles acerca de cómo funciona el proyecto, y por lo tanto se debería mostrar de manera más amplia de qué se trata. Además hay información adicional que no aporta nada al setup del proyecto; está de más.

* Sin saber que hay que usar `pip install -r requirements.txt`, `python manage.py migrate`, ni `python manage.py runserver`, el proyecto está completamente bloqueado desde el inicio.

2. **[IMPLICIT_DEP]**

- El archivo requirements.txt incluye psycopg2==2.9.6.
Impacto: Esta librería requiere que las bibliotecas de desarrollo de PostgreSQL (como libpq-dev) estén instaladas en el sistema operativo antes de hacer el pip install. Esto no está documentado y causará errores de compilación en el setup inicial.


- Aunque se define Django==4.2.2, no se especifica la versión mínima de Python requerida.
Impacto: Incompatibilidades potenciales si se intenta ejecutar con versiones muy antiguas o demasiado recientes de Python.

-  psycopg2==2.9.6 es el driver binario que compila contra las cabeceras de PostgreSQL. En sistemas Linux/Mac requiere:

En Ubuntu/Debian

`sudo apt-get install libpq-dev python3-dev`

En macOS

`brew install postgresql`

Al hacer `pip install` recibimos

`Error: pg_config executable not found.`

3. **[ENV_GAP] SECRET_KEY expuesta y estática**

- La SECRET_KEY está escrita directamente en el código de configuración.
Impacto: Riesgo de seguridad y falta de flexibilidad para rotar claves en diferentes entornos de desarrollo/producción.

4. **[MISSING_DOC] — PostgreSQL: no se documenta que hay que instalarlo ni crear la base de datos manualmente**

Archivo: `gestor/settings.py` línea 81

El ENGINE es `django.db.backends.postgresql` y la base de datos se llama `tienda`. Sin embargo, en ningún lugar se documenta que:

`PostgreSQL` debe estar instalado y corriendo
La base de datos `tienda` debe crearse antes de migrar,

`CREATE DATABASE tienda;`

El usuario `postgres` debe existir con acceso

Impacto: `python manage.py migrate` falla con `FATAL: database "tienda" does not exist` — un error silencioso para quienes no conocen PostgreSQL.

5. **[MISSING_DOC] — No se documenta el paso python manage.py migrate**

Contexto: Los modelos definen ~8 tablas (Pedidos, Clientes, Productos, Facturas, Albaranes, etc.) todas en `tienda/models.py`. Sin `migrate`, cualquier operación en la app lanza `ProgrammingError: relation "tienda_pedidos" does not exist.`

Impacto: El servidor arranca `(exit 0)` pero la aplicación explota al primer request con datos.

6. **[MISSING_DOC] — No se menciona la necesidad de un `virtualenv`**

Sin instrucciones de entorno virtual, un desarrollador instala todo globalmente, generando conflictos de versiones con otros proyectos de Python en su máquina.

Severity Summary:
- Total friction points found:
  `10`
- How far you got before the first complete blocker:
  *Running the migration. We need to install postgress database and set the correct information for authentication*
- Estimated time lost for a new hire
 `2 hr`