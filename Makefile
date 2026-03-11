# ============================================================
# Makefile — simple_erp
# Uso: make <target>
# Ejemplos: make setup | make run | make migrate | make clean
# ============================================================

# Variables configurables. Puedes cambiarlas al invocar:
# make setup PYTHON=python3.11
PYTHON      = python3
VENV        = venv
PIP         = $(VENV)/bin/pip
MANAGE      = $(VENV)/bin/python manage.py

# .PHONY: declara targets que no son archivos reales.
# Sin esto, si existiera un archivo llamado "setup", make se confundiría.
.PHONY: help setup install env migrate seed run clean docker-up docker-down

# ----------------------------------------------------------
# Target por defecto: muestra ayuda al correr solo "make"
# ----------------------------------------------------------
help:
	@echo ""
	@echo "  simple_erp — comandos disponibles"
	@echo "  ─���───────────────────────────────"
	@echo "  make setup       → Setup completo (primera vez)"
	@echo "  make install     → Solo instalar dependencias Python"
	@echo "  make env         → Copiar .env.example → .env"
	@echo "  make migrate     → Correr migraciones de Django"
	@echo "  make run         → Arrancar servidor de desarrollo"
	@echo "  make clean       → Eliminar venv y archivos temporales"
	@echo "  make docker-up   → Levantar stack completo con Docker"
	@echo "  make docker-down → Detener y limpiar contenedores"
	@echo ""

# ----------------------------------------------------------
# make setup — EL COMANDO PRINCIPAL para nuevos developers
# Ejecuta todo en orden: crea venv, instala deps, copia .env, migra
# ----------------------------------------------------------
setup: $(VENV)/bin/activate env migrate
	@echo ""
	@echo "✅ Setup completo. Para arrancar el servidor:"
	@echo "   make run"
	@echo ""

# Crea el virtualenv si no existe todavía.
# Un virtualenv es una carpeta aislada con su propio Python y pip,
# para no contaminar el Python global del sistema.
$(VENV)/bin/activate:
	@echo "→ Creando entorno virtual en ./$(VENV)..."
	$(PYTHON) -m venv $(VENV)
	@echo "→ Actualizando pip..."
	$(PIP) install --upgrade pip

# ----------------------------------------------------------
# make install — Instala dependencias Python en el venv
# ----------------------------------------------------------
install: $(VENV)/bin/activate
	@echo "→ Instalando dependencias desde requirements.txt..."
	$(PIP) install -r requirements.txt
	@echo "✅ Dependencias instaladas."

# ----------------------------------------------------------
# make env — Copia .env.example a .env si .env no existe
# ----------------------------------------------------------
env:
	@if [ ! -f .env ]; then \
		echo "→ Copiando .env.example → .env"; \
		cp .env.example .env; \
		echo "⚠️  IMPORTANTE: Edita .env con tus valores reales antes de continuar."; \
	else \
		echo "→ .env ya existe, no se sobreescribe."; \
	fi

# ----------------------------------------------------------
# make migrate — Corre las migraciones de Django
# Requiere que PostgreSQL esté corriendo y .env configurado
# ----------------------------------------------------------
migrate: install
	@echo "→ Corriendo migraciones de Django..."
	$(MANAGE) migrate
	@echo "✅ Migraciones aplicadas."

# ----------------------------------------------------------
# make run — Arranca el servidor de desarrollo Django
# ----------------------------------------------------------
run:
	@echo "→ Iniciando servidor en http://127.0.0.1:8000 ..."
	$(MANAGE) runserver

# ----------------------------------------------------------
# make clean — Limpia el entorno local
# ----------------------------------------------------------
clean:
	@echo "→ Eliminando entorno virtual..."
	rm -rf $(VENV)
	@echo "→ Eliminando archivos .pyc y __pycache__..."
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	@echo "✅ Limpieza completa."

# ----------------------------------------------------------
# make docker-up — Levanta el stack completo con Docker
# No necesitas instalar PostgreSQL localmente
# ----------------------------------------------------------
docker-up:
	@echo "→ Levantando stack con Docker Compose..."
	docker compose up --build

# ----------------------------------------------------------
# make docker-down — Detiene los contenedores
# ----------------------------------------------------------
docker-down:
	docker compose down