# ============================================================
# Dockerfile — simple_erp
# Pin explícito de Python 3.11 (compatible con Django 4.2.2
# y psycopg2 2.9.6). Resuelve [VERSION_HELL] e [IMPLICIT_DEP].
# ============================================================

# "FROM" es la imagen base. python:3.11-slim es Python 3.11
# sobre Debian mínimo (~130MB vs ~900MB de la imagen completa).
FROM python:3.11-slim

# Evita que Python genere archivos .pyc (bytecode cacheado).
# En contenedores no los necesitamos.
ENV PYTHONDONTWRITEBYTECODE=1

# Fuerza que los prints/logs salgan inmediatamente al terminal
# (sin buffer). Importante para ver logs en tiempo real.
ENV PYTHONUNBUFFERED=1

# Directorio de trabajo dentro del contenedor.
# Todos los comandos siguientes se ejecutan desde aquí.
WORKDIR /app

# Instala libpq-dev: cabeceras de C que psycopg2 necesita
# para compilarse. Resuelve [IMPLICIT_DEP] #2.
# gcc: compilador C necesario para la compilación.
# --no-install-recommends: no instala paquetes extra innecesarios.
# rm -rf /var/lib/apt/lists/*: limpia cache de apt para reducir tamaño de imagen.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libpq-dev \
        gcc \
    && rm -rf /var/lib/apt/lists/*

# Copia solo requirements.txt primero.
# Docker cachea capas: si requirements.txt no cambia,
# no reinstala dependencias aunque cambies código fuente.
COPY requirements.txt .

# Instala dependencias Python.
# --no-cache-dir: no guarda cache de pip dentro de la imagen.
RUN pip install --no-cache-dir -r requirements.txt

# Copia el resto del código fuente al contenedor.
COPY . .

# Puerto que expone el contenedor. Django por defecto corre en 8000.
# EXPOSE es solo documentación; el mapeo real va en docker-compose.yml.
EXPOSE 8000

# Comando por defecto al arrancar el contenedor.
# gunicorn es más robusto que runserver para producción.
# Para dev, docker-compose.yml sobreescribe este comando.
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]