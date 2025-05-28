# Backend (Django)
FROM python:3.10-slim as backend
WORKDIR /app
COPY backend/ /app/
ARG SECRET_KEY
ENV SECRET_KEY=$SECRET_KEY
RUN pip install -r requirements.txt

# Frontend (Vite)
FROM node:18-alpine as frontend
WORKDIR /frontend
COPY frontend/ /frontend/
RUN npm install 
RUN chmod +x node_modules/.bin/vite
RUN npm run build

# Final image
FROM python:3.10-slim
WORKDIR /app

ARG SECRET_KEY
ENV SECRET_KEY=$SECRET_KEY

# Copy Django backend
COPY --from=backend /app /app

# Copy Vite build output
COPY --from=frontend /frontend/dist /app/static/

# Reinstall Django dependencies
RUN pip install -r requirements.txt

# Collect static files
RUN python manage.py collectstatic --noinput

ENV DJANGO_SETTINGS_MODULE=settings

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "wsgi:application"]
