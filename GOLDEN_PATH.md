# GOLDEN_PATH.md — simple_erp

> Documento del Deliverable 2.
> Rol: Platform Team.
> Objetivo: eliminar cada bloqueo del Pain_Log.md mediante artifacts de automatización.

---

## Artifacts producidos

| Archivo            | Propósito principal                                      |
|--------------------|----------------------------------------------------------|
| `.env.example`     | Documenta todas las variables de entorno requeridas      |
| `Dockerfile`       | Fija Python 3.11 e instala dependencias del sistema      |
| `docker-compose.yml` | Levanta app + PostgreSQL con un solo comando           |
| `Makefile`         | Golden path de setup en un solo `make setup`             |           |

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

### 🐳 Con Docker (RECOMENDADO para desarrollo)

**Requisitos previos del sistema:**
- Docker Desktop ([descargar](https://www.docker.com/products/docker-desktop))

**Pasos:**

```powershell
# 1. Clona el repositorio
git clone https://github.com/Pablokill2004/simple_erp-fork-room6.git
cd simple_erp-fork-room6

# 2. Copia el archivo de variables de entorno
Copy-Item .env.example .env

# 3. Edita .env si es necesario (asegúrate de que DB_PASSWORD, DB_USER coinciden)
# Por defecto:
#   DB_USER=postgres
#   DB_PASSWORD=1593
#   DB_HOST=db (para Docker)

# 4. Limpia volúmenes antiguos de Docker (si es la primera vez, esto no es necesario)
docker compose down -v

# 5. Construye las imágenes y levanta los contenedores
docker compose build --no-cache
docker compose up -d

# 6. Espera 10 segundos a que la BD esté lista
Start-Sleep -Seconds 10

# 7. Corre las migraciones
docker compose exec web python manage.py migrate

# 8. Crea el superusuario
docker compose exec web python manage.py createsuperuser

# 9. Accede a la aplicación
# → http://localhost:8000
# → Admin: http://localhost:8000/admin
```

**Para detener:**
```powershell
docker compose down
```

**Para ver logs en tiempo real:**
```powershell
docker compose logs -f web
docker compose logs -f db
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

## Issues encontrados y corregidos

### ✅ Issue 1: psycopg2 compilation error

**Error:**
```
Building wheel for psycopg2 (setup.py): finished with status 'error'
error: subprocess-exited-with-error
```

**Causa:** `psycopg2==2.9.6` requiere compilación en tiempo de instalación, lo que falló en Windows y Docker.

**Solución:**
Cambiar en [requirements.txt](requirements.txt):
```diff
- psycopg2==2.9.6
+ psycopg2-binary==2.9.6
```

`psycopg2-binary` incluye wheels precompilados y no requiere `gcc` ni `libpq-dev`.

---

### ✅ Issue 2: Database connection refused (127.0.0.1 vs db)

**Error:**
```
django.db.utils.OperationalError: connection to server at "127.0.0.1", port 5432 failed
```

**Causa:** En Docker, los contenedores no pueden usar `127.0.0.1` para comunicarse entre sí. Necesitan usar el nombre del servicio (`db`).

**Solución:**
Actualizar [gestor/settings.py](gestor/settings.py) para leer la configuración de BD desde variables de entorno:

```python
DATABASES = {
    'default': {
        'ENGINE':"django.db.backends.postgresql",
        "NAME": os.getenv("DB_NAME", "tienda"),
        "USER": os.getenv("DB_USER", "postgres"),
        "PASSWORD": os.getenv("DB_PASSWORD", "my_pass"),
        "HOST": os.getenv("DB_HOST", "db"),       # ← db en Docker, 127.0.0.1 en local
        "PORT": os.getenv("DB_PORT", "5432"),
    }
}
```

Esto permite que `.env` controle el HOST según el entorno (Docker vs local).

---

### ✅ Issue 3: Password authentication failed

**Error:**
```
FATAL:  password authentication failed for user "postgres"
```

**Causa:** El volumen de Docker persistía datos de BD antigua con contraseña diferente.

**Solución:**
Limpiar volúmenes antes de la primera ejecución:
```powershell
docker compose down -v
```

El flag `-v` elimina los volúmenes nombrados, forzando que PostgreSQL se reinicialice con las credenciales del `.env`.

---

## Tabla actualizada: Pain Point → Artifact → Status

| Pain Point # | Descripción (de Pain_Log.md)                              | Artifact que lo resuelve              | Status       |
|:---:|-----------------------------------------------------------|---------------------------------------|:---:|
| 1  | No hay instrucciones de setup en el README                | `GOLDEN_PATH.md` (este archivo) | ✅ Fixed |
| 2  | `psycopg2` requiere compilación en runtime               | Cambiar a `psycopg2-binary` en `requirements.txt` | ✅ Fixed |
| 2b | No se especifica versión de Python requerida              | `Dockerfile` (`FROM python:3.11-slim`) | ✅ Fixed |
| 3  | `SECRET_KEY` hardcodeada en `settings.py`                 | `.env.example` + lectura desde variables de entorno | ✅ Fixed |
| 4  | PostgreSQL no documentado, base de datos no se crea sola  | `docker-compose.yml` (crea DB automáticamente) | ✅ Fixed |
| 5  | `python manage.py migrate` nunca se menciona              | Comando en `GOLDEN_PATH.md` | ✅ Fixed |
| 6  | No se menciona la necesidad de un virtualenv              | `Makefile` (`make setup` para local) | ✅ Fixed |
| 7  | Database HOST hardcodeado a `127.0.0.1` en settings.py    | Cambiar para leer desde `os.getenv("DB_HOST", "db")` | ✅ Fixed |
| —  | Rutas absolutas `/home/ubuntu/` en `lanzar_albaran.py`    | —                                     | ⚠️ Out of Scope (requiere refactor del código fuente) |
| —  | Credenciales SMTP hardcodeadas en scripts                 | `.env.example` (documenta variables SMTP) | ⚠️ Partial (`.env` provee los valores, pero el código aún no los lee con `os.environ`) |
---

*Documento generado como parte del Deliverable 2 — The Golden Path.*
*Repositorio: https://github.com/Pablokill2004/simple_erp-fork-room6*