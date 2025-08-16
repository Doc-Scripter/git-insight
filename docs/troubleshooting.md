# Troubleshooting Guide

This guide provides solutions to common issues you might encounter while setting up or developing with GitInsight.

## General Issues

### Port Conflicts

If you encounter errors indicating that a port is already in use (e.g., `3000` for the frontend or `8000` for the backend), it means another application is using that port.

**Solution:**

1.  **Identify the process:**
    *   **Linux/macOS:** `sudo lsof -i :<PORT_NUMBER>` (e.g., `sudo lsof -i :3000`)
    *   **Windows (PowerShell):** `Get-NetTCPConnection -LocalPort <PORT_NUMBER> | Select-Object OwningProcess`
2.  **Terminate the process:**
    *   **Linux/macOS:** `kill -9 <PID>` (replace `<PID>` with the process ID from the previous step)
    *   **Windows (Command Prompt as Admin):** `taskkill /PID <PID> /F`
3.  **Alternatively, configure GitInsight to use a different port:**
    *   **Frontend (SvelteKit):** Modify `svelte.config.js` or use the `PORT` environment variable (e.g., `PORT=3001 yarn dev`).
*   **Python Backend (FastAPI/Uvicorn):** Specify the port when running Uvicorn (e.g., `uvicorn main:app --port 8001 --reload`).
*   **Go Backend:** Check the `main.go` file or environment variables for port configuration (e.g., `http://localhost:8080`).

### Dependency Installation Issues

Problems during `npm install`, `yarn install`, `pip install`, or `pipenv install` can occur due to network issues, corrupted caches, or incorrect environment setups.

**Solution:**

1.  **Clear Caches:**
    *   **npm:** `npm cache clean --force`
    *   **yarn:** `yarn cache clean`
    *   **pip:** `pip cache purge`
2.  **Reinstall Dependencies:** After clearing caches, try installing again.
3.  **Check Network Connection:** Ensure you have a stable internet connection and no proxy issues.
4.  **Update Package Managers:** Ensure your `npm`, `yarn`, `pip`, or `pipenv` are up to date.

## Python Backend Specific Issues

### Database Connection Errors

If your backend cannot connect to the PostgreSQL database.

**Solution:**

1.  **Ensure Docker Container is Running:**
    ```bash
docker-compose ps
    ```
    Look for the `db` service and ensure its status is `Up`.
2.  **Check Database Logs:**
    ```bash
docker-compose logs db
    ```
    Look for errors during database startup.
3.  **Verify Connection String:** Double-check the database connection string in your backend configuration (e.g., environment variables or a config file) against the `docker-compose.yml` details.
4.  **Firewall:** Ensure no firewall is blocking the connection to `localhost:5432`.

### Migration Errors

Issues when running database migrations (e.g., `alembic upgrade head`).

**Solution:**

1.  **Check Alembic Configuration:** Ensure `alembic.ini` and `env.py` are correctly configured.
2.  **Database State:** If you're developing, sometimes dropping and recreating the database can resolve issues with inconsistent migration states.
    *   **Caution:** This will delete all data. Only do this in development.
    ```bash
docker-compose down -v
docker-compose up -d db
    ```
3.  **Review Migration Scripts:** Examine the specific migration script that failed for syntax errors or logical issues.

## Go Backend Specific Issues

### Build or Run Errors

If your Go application fails to build or run.

**Solution:**

1.  **Check Go Version:** Ensure you have the correct Go version installed as specified in `setup.md`.
2.  **Module Dependencies:** Run `go mod tidy` in the Go backend directory to ensure all dependencies are correctly downloaded and managed.
3.  **Syntax Errors:** Review the console output for Go compiler errors, which are usually very descriptive.
4.  **Environment Variables:** Ensure any necessary environment variables for the Go application are set correctly.

## Frontend Specific Issues

### "Cannot find module" or "Module not found" errors

These typically occur when dependencies are not correctly installed or paths are incorrect.

**Solution:**

1.  **Reinstall `node_modules`:** Delete the `node_modules` directory and `package-lock.json` (or `yarn.lock`), then run `npm install` or `yarn install` again.
2.  **Check Import Paths:** Verify that all `import` statements in your code correctly point to the modules or components.
3.  **Case Sensitivity:** On some operating systems (like Linux), file paths are case-sensitive. Ensure your import paths match the exact casing of the file names.

### Blank Page or Hydration Errors in SvelteKit

If your SvelteKit application shows a blank page or throws hydration errors, it often relates to server-side rendering mismatches or client-side JavaScript issues.

**Solution:**

1.  **Check Browser Console:** Look for errors in your browser's developer console.
2.  **Server-Side Logs:** Check the terminal where your Next.js development server is running for any server-side errors.
3.  **Ensure `window` is not accessed on Server:** If you're using browser-specific APIs (like `window` or `document`), ensure they are only accessed on the client-side (e.g., inside `useEffect` hooks or dynamic imports with `ssr: false`).

## Docker Specific Issues

### Docker Containers Fail to Start

If `docker-compose up` fails or containers exit immediately.

**Solution:**

1.  **Check Docker Daemon:** Ensure the Docker daemon is running on your system.
2.  **Review Container Logs:** The most crucial step. Check the logs of the failing container:
    ```bash
docker-compose logs <service_name>
    ```
    (e.g., `docker-compose logs backend` or `docker-compose logs db`)
3.  **Resource Constraints:** Ensure your system has enough memory and CPU allocated to Docker.
4.  **Image Pull Issues:** If images fail to pull, check your network connection or Docker Hub rate limits.

If you encounter an issue not covered here, please refer to the `CONTRIBUTING.md` guide for reporting bugs or seek help from the community.