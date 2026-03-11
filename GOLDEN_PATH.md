# GOLDEN_PATH.md — simple_erp

> Documento del Deliverable 2.
> Rol: Platform Team.
> Objetivo: eliminar cada bloqueo del Pain_Log.md mediante artifacts de automatización.

---

## Artifacts producidos

| Archivo            | Propósito principal                                      |
|--------------------|----------------------------------------------------------|
| `.env.example`     | Documenta todas las variables de entorno requeridas      |
| `Makefile`         | Golden path de setup en un solo `make setup`             |

---

## Tabla: Pain Point → Artifact → Status

| Pain Point # | Descripción (de Pain_Log.md)                              | Artifact que lo resuelve              | Status       |
|:---:|-----------------------------------------------------------|---------------------------------------|:---:|
| 1  | No hay instrucciones de setup en el README                | `Makefile` (`make setup`) + `GOLDEN_PATH.md` | ✅ Fixed |
| 2  | `psycopg2` requiere `libpq-dev` del sistema, no documentado | `Dockerfile` (instala `libpq-dev` automáticamente) | ✅ Fixed |
| 2b | No se especifica versión de Python requerida              | `Dockerfile` (`FROM python:3.11-slim`) | ✅ Fixed |
| 3  | `SECRET_KEY` hardcodeada en `settings.py`                 | `.env.example` + instrucción en Makefile de copiar `.env` | ✅ Fixed |
| 4  | PostgreSQL no documentado, base de datos no se crea sola  | `docker-compose.yml` (crea DB automáticamente con `POSTGRES_DB`) | ✅ Fixed |
| 5  | `python manage.py migrate` nunca se menciona              | `Makefile` (`make migrate`) + `docker-compose.yml` (corre migrate al arrancar) | ✅ Fixed |
| 6  | No se menciona la necesidad de un virtualenv              | `Makefile` (crea el venv automáticamente en `make setup`) | ✅ Fixed |
| —  | Rutas absolutas `/home/ubuntu/` en `lanzar_albaran.py`    | —                                     | ⚠️ Out of Scope (requiere refactor del código fuente) |
| —  | Credenciales SMTP hardcodeadas en scripts                 | `.env.example` (documenta variables SMTP) | ⚠️ Partial (`.env` provee los valores, pero el código aún no los lee con `os.environ`) |

---

## Ruta completa de setup ("The Golden Path")

###  Sin Docker (instalación local)

**Requisitos previos del sistema:**

- Python 3.11 ([descargar](https://www.python.org/downloads/))
- PostgreSQL 15 ([descargar](https://www.postgresql.org/download/))
  - En Ubuntu/Debian: `sudo apt-get install postgresql libpq-dev python3-dev gcc`
  - En macOS: `brew install postgresql@15`

```bash
# 1. Clona el repositorio
git clone https://github.com/Pablokill2004/simple_erp-fork-room6.git
cd simple_erp-fork-room6

# 2. Crea la base de datos en PostgreSQL
# Primero entra al cliente de postgres:
psql -U postgres
# Dentro de psql, ejecuta:
# CREATE DATABASE tienda;
# \q

# 3. Copia y edita el archivo de variables de entorno
cp .env.example .env
# Edita .env: pon tu DB_PASSWORD real y una SECRET_KEY segura

# 4. Corre el setup completo con make (crea venv, instala deps, migra)
make setup
# Si no tienes make instalado:
#   Windows: instala con  choco install make
#   macOS:   viene incluido con Xcode Command Line Tools

# 5. Crea el superusuario de Django
source venv/bin/activate
python manage.py createsuperuser

# 6. Arranca el servidor
make run
# → http://127.0.0.1:8000
```

---

## Prompts usados con el AI

A continuación se documentan los prompts utilizados para generar el primer borrador de cada artifact, tal como requiere el entregable.

**Prompt 1 — Contexto base:**
> "Te paso el Pain_Log.md de un proyecto Django llamado simple_erp. Tiene los siguientes pain points: [contenido completo del Pain_Log.md]. Actúa como el Platform Team y genera los artifacts necesarios para eliminar todos los blockers: un .env.example, un Dockerfile, un docker-compose.yml y un Makefile."

**Prompt 2 — Refinamiento del Dockerfile:**
> "El proyecto usa psycopg2==2.9.6 que requiere libpq-dev. Asegúrate de que el Dockerfile lo instale antes de pip install. Usa python:3.11-slim como base."

**Prompt 3 — Refinamiento del docker-compose:**
> "Agrega un healthcheck al servicio db para que Django no intente conectarse antes de que PostgreSQL esté listo. Usa las variables del .env para las credenciales."

**Prompt 4 — Makefile:**
> "Genera un Makefile con targets: help, setup, install, env, migrate, run, clean, docker-up, docker-down. El target setup debe ser el golden path para un nuevo developer."

---

## What the AI Got Wrong

### ❌ Issue 1

ERROR: To modify pip, please run the following command:
C:\Users\pablo\OneDrive\Documentos\Proyectos y Labs\ISA\simple_erp-fork-room6\venv\bin\python3.exe -m pip install --upgrade pip
---

*Documento generado como parte del Deliverable 2 — The Golden Path.*
*Repositorio: https://github.com/Pablokill2004/simple_erp-fork-room6*