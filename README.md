# CI/CD Test App

This is a simple app to test your CI/CD pipeline, consisting of a React frontend and a Django backend.

## Folder Structure
- `frontend/`: React app
- `backend/`: Django app

---

## Running the Backend

1. Navigate to the `backend` folder:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Run migrations:
   ```bash
   python manage.py migrate
   ```
4. Start the Django server:
   ```bash
   python manage.py runserver
   ```

---

## Running the Frontend

1. Navigate to the `frontend` folder:
   ```bash
   cd frontend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Start the React app:
   ```bash
   npm start
   ```

The React app will try to fetch a message from the Django backend at `http://localhost:8000/`. 