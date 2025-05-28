# Backend (Django)
FROM python:3.10-slim as backend
WORKDIR /app
ENV PYTHONUNBUFFERED=1
COPY backend/ /app/backend/
COPY backend/manage.py /app/manage.py
COPY backend/requirements.txt /app/requirements.txt
COPY backend/*.py /app/  # Ensure main.py, settings.py, etc., are accessible
RUN pip install --no-cache-dir -r requirements.txt

# Frontend (Vite)
FROM node:18-alpine as frontend
WORKDIR /frontend
COPY frontend/ /frontend/
RUN npm install && npm run build

# Final image
FROM python:3.10-slim
WORKDIR /app

# Set PYTHONPATH so that 'backend' can be found
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    DJANGO_SETTINGS_MODULE=backend.settings

# Copy Django backend and manage.py
COPY --from=backend /app /app

# Copy frontend build output
COPY --from=frontend /frontend/dist /app/static/

# Install Python dependencies again
RUN pip install --no-cache-dir -r requirements.txt

# Collect static files
RUN python manage.py collectstatic --noinput

# Run the app using Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "backend.wsgi"]
