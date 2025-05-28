# === Backend (Django) ===
FROM python:3.10-slim as backend
WORKDIR /app
ENV PYTHONUNBUFFERED=1

COPY backend/ /app/backend/
COPY backend/manage.py /app/manage.py
COPY backend/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# === Frontend (Vite) ===
FROM node:18-alpine as frontend
WORKDIR /frontend
COPY frontend/ /frontend/
RUN npm install && npm run build

# === Final Image ===
FROM python:3.10-slim
WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    DJANGO_SETTINGS_MODULE=backend.settings

# Copy Django backend and manage.py
COPY --from=backend /app /app

# Copy frontend build
COPY --from=frontend /frontend/dist /app/static/

# Install backend dependencies
RUN pip install --no-cache-dir -r requirements.txt

# 💡 Make sure Django knows where settings are
ENV DJANGO_SETTINGS_MODULE=backend.settings

# 🔧 Run from root where manage.py exists
RUN python manage.py collectstatic --noinput

# 🟢 Run with Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "backend.wsgi"]
