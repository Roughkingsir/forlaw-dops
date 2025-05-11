# Backend (Django)
FROM python:3.10-slim as backend

WORKDIR /app
COPY backend/ /app/
RUN pip install -r requirements.txt

# Frontend (React)
FROM node:18-alpine as frontend

WORKDIR /frontend
COPY frontend/ /frontend/
RUN npm install && npm run build

# Final image
FROM python:3.10-slim
WORKDIR /app

# Copy Django backend
COPY --from=backend /app /app

# Copy React build
COPY --from=frontend /frontend/build /app/static/

ENV DJANGO_SETTINGS_MODULE=backend.settings
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "backend.wsgi"]
