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

# Copy frontend files and build
COPY frontend/ /frontend/
RUN npm install

# Fix: Permission issue with vite binary
RUN chmod +x node_modules/.bin/vite

RUN npm run build

# === Final Deployment Image ===
FROM python:3.10-slim
WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    DJANGO_SETTINGS_MODULE=backend.settings

# Copy backend from the backend stage
COPY --from=backend /app /app

# Copy frontend build output to Django static dir
COPY --from=frontend /frontend/dist /app/static/

# Install backend dependencies again (best practice for final image)
RUN pip install --no-cache-dir -r requirements.txt

# Collect static files
RUN python manage.py collectstatic --noinput

# Start app with Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "backend.wsgi"]
