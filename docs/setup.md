# Development Environment Setup

This document outlines the steps required to set up your development environment for GitInsight, covering both the frontend and backend components.

## Prerequisites

Before you begin, ensure you have the following installed on your system:

*   **Git:** For version control.
*   **Docker & Docker Compose:** For containerized development environments.
*   **Node.js (LTS version) & npm/yarn:** For frontend development (SvelteKit).
*   **Python 3.9+ & pip/pipenv/poetry:** For Python backend development.
*   **Go 1.18+:** For Go backend development.

## 1. Clone the Repository

First, clone the GitInsight repository to your local machine:

```bash
git clone https://github.com/your-org/git-insight.git
cd git-insight
```

## 2. Backend Setup (Python/FastAPI)

The backend is built with Python and FastAPI. We recommend using a virtual environment.

### Using `pipenv` (Recommended)

If you have `pipenv` installed:

```bash
cd backend
pipenv install --dev
pipenv shell
```

### Using `venv` and `pip`

Alternatively, you can use Python's built-in `venv`:

```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: .\venv\Scripts\activate
pip install -r requirements.txt
```

### Running the Backend

Once dependencies are installed, you can run the backend server:

```bash
# If using pipenv
pipenv run uvicorn main:app --reload

# If using venv
uvicorn main:app --reload
```

The backend API will typically be available at `http://localhost:8000`.

## 3. Frontend Setup (SvelteKit with Shadcn UI)

The frontend is built with SvelteKit.

First, navigate to the frontend directory and install dependencies:

```bash
cd frontend
yarn install  # or npm install
```

### Shadcn UI Setup (if not already done)

If you are setting up Shadcn UI for the first time or need to add new components, follow the official Shadcn UI documentation for SvelteKit. This typically involves:

*   Initializing Shadcn UI in your project.
*   Adding components using the Shadcn CLI (e.g., `npx shadcn-ui@latest add button`).

### Running the Frontend

To start the frontend development server:

```bash
yarn dev  # or npm run dev
```

The frontend application will typically be available at `http://localhost:3000`.

## 4. Go Backend Setup

The Go backend handles high-performance API endpoints.

```bash
cd backend/go
go mod tidy
```

### Running the Go Backend

To start the Go backend server:

```bash
cd backend/go
go run main.go
```

The Go backend API will typically be available at `http://localhost:8080` (or as configured).

## 5. Database Setup (PostgreSQL)

## 6. Database Setup (PostgreSQL)

GitInsight uses PostgreSQL for its database. You can run a local PostgreSQL instance using Docker Compose.

From the project root directory:

```bash
docker-compose up -d db
```

This will start a PostgreSQL container. You can connect to it using a tool like `psql` or `DBeaver` with the connection details specified in `docker-compose.yml` (e.g., `localhost:5432`, user `gitinsight_user`, password `gitinsight_password`, database `gitinsight_db`).

### Running Migrations

After setting up the database, you'll need to run database migrations to create the necessary tables. (Instructions for specific migration tool, e.g., Alembic for Python, will go here).

```bash
# Example: For Alembic
cd backend
alembic upgrade head
```

## 7. Running Tests

### Backend Tests

```bash
cd backend
pipenv run pytest  # or pytest
```

### Frontend Tests

```bash
cd frontend
yarn test  # or npm test
```

## 8. Linting and Formatting

To maintain code consistency, please run linters and formatters before committing your changes.

### Backend

```bash
cd backend
pipenv run black .  # or black .
pipenv run isort .   # or isort .
```

### Frontend

```bash
cd frontend
yarn lint --fix  # or npm run lint --fix
yarn format      # or npm run format
```

## Troubleshooting

*   **Port Conflicts:** If you encounter issues with ports (e.g., 3000 or 8000) being in use, you might need to stop other applications using those ports or configure GitInsight to use different ones.
*   **Dependency Issues:** Ensure all dependencies are correctly installed. Try clearing caches (`npm cache clean --force`, `pip cache purge`) and reinstalling.
*   **Docker Issues:** If Docker containers fail to start, check Docker logs for errors (`docker logs <container_name>`) and ensure Docker Desktop/Daemon is running.

If you face any persistent issues, please refer to the `CONTRIBUTING.md` guide for reporting bugs or seek help from the community.