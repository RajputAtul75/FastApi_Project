# PFAI Backend API

This is the FastAPI backend for the Personal Finance AI application.

## Prerequisites
- Python 3.11+
- PostgreSQL
- Redis (for Celery workers)

## Setup

1. **Environment Variables**: Clone `.env.example` to `.env` and fill in your values.
2. **Virtual Environment**: 
    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate
    ```
3. **Install Dependencies**:
    ```bash
    pip install -r requirements.txt
    ```
4. **Database Migrations**:
    ```bash
    alembic upgrade head
    ```

## Running the Application

**Using Docker Compose (Recommended for Local Dev):**
From the root directory, run:
```bash
docker-compose up --build
```

**Running manually:**
```bash
uvicorn app.main:app --reload
```
And in another terminal:
```bash
celery -A app.tasks.celery_app worker --loglevel=info
```
