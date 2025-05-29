# === Backend (Django) ===
FROM python:3.10-slim as backend
WORKDIR /app

ENV PYTHONUNBUFFERED=1

# Copy backend files
COPY backend/ /app/backend/
COPY backend/manage.py /app/manage.py
COPY backend/requirements.txt /app/requirements.txt

# Install backend dependencies
RUN pip install --no-cache-dir -r requirements.txt

# === Frontend (Vite + React) ===
FROM node:18-alpine as frontend
WORKDIR /frontend

COPY frontend/ /frontend/
RUN npm install
RUN chmod +x node_modules/.bin/vite
RUN npm run build

# === Final Deployment Image ===
FROM python:3.10-slim
WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    DJANGO_SETTINGS_MODULE=backend.settings

# Copy backend and frontend builds
COPY --from=backend /app /app
COPY --from=frontend /frontend/dist /app/static/

# Install backend requirements again in clean layer
RUN pip install --no-cache-dir -r requirements.txt

# Collect static files (secret key not needed here)
RUN python manage.py collectstatic --noinput

# Start Django app with Gunicorn (secret key from env var at runtime)
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "backend.wsgi"]
