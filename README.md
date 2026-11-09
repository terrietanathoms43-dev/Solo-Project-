# Tidewater Tours API

A lightweight REST API for browsing sample tour offerings in Jamaica. Built with Flask and Python, packaged with Docker, and supported by automated testing, container publishing, deployment, and rollback workflows.

## Features

- **Python 3.12** — Application runtime
- **Flask** — HTTP API and JSON responses
- **Gunicorn** — Production WSGI server
- **Docker** — Containerized application with a non-root user and health check
- **pytest** — Automated API tests
- **GitHub Actions** — Continuous integration and container build automation
- **GitHub Container Registry (GHCR)** — Versioned Docker images tagged by Git commit SHA
- **Deployment and rollback** — Optional SSH-based Docker deployment with health verification and previous-image restoration

## API Endpoints

| Method | Endpoint | Description |
| --- | --- | --- |
| GET | `/` | Service information and version |
| GET | `/tours` | List available sample tours |
| GET | `/tours/<tour_id>` | Retrieve a tour by ID; returns 404 if not found |
| GET | `/health` | Service status and version |

Example health response:

```json
{
  "status": "ok",
  "service": "tidewater-tours",
  "version": "local"
}
```

The tour data is currently defined in `app.py`.

## Getting Started

**Requirements:** Python 3.12 and pip.

Clone the repository, then install the development dependencies:

```bash
python -m pip install -r requirements-dev.txt
```

Start the development server:

```bash
python app.py
```

The API runs at **http://127.0.0.1:8000**.

## Environment Configuration

The application supports one optional runtime environment variable:

| Variable | Description | Default |
| --- | --- | --- |
| `APP_VERSION` | Version identifier returned by `/` and `/health` | `local` |

CI supplies the Git commit SHA as `APP_VERSION` when building Docker images. The basic API does not require a database or application secrets.

Deployment credentials, when needed, are configured as GitHub Actions secrets rather than committed to the repository.

## Testing

Run the API tests:

```bash
python -m pytest -q
```

The test suite covers service responses, tour listing, tour lookup, missing tours, and the health endpoint.

## Docker

**Requirements:** Docker Engine or Docker Desktop.

Build the application image:

```bash
docker build -t tidewater-tours:local .
```

Start the container:

```bash
docker run --rm -p 127.0.0.1:8000:8000 tidewater-tours:local
```

The containerized API is available at **http://127.0.0.1:8000**.

The Dockerfile uses a slim Python base image, runs Gunicorn on port `8000`, and includes a container health check.

## CI/CD

The [GitHub Actions CI workflow](.github/workflows/ci.yml) performs the following steps:

1. Runs pytest on pushes to `main`, pull requests targeting `main`, and manual workflow runs.
2. After successful tests, builds a Docker image on non-pull-request runs.
3. Starts the image and checks its `/health` endpoint.
4. Publishes the image to GHCR with an immutable commit-SHA tag.
5. Optionally deploys the published image to a configured Docker host.

A failed test blocks image publishing and deployment.

## Deployment and Rollback

The SSH deployment workflow supports Linux hosts with Docker, curl, and SSH access. Configure the following in **GitHub → Settings → Secrets and variables → Actions**:

| Setting | Type | Purpose |
| --- | --- | --- |
| `DEPLOY_HOST` | Secret | Destination server hostname or IP address |
| `DEPLOY_USER` | Secret | SSH account on the server |
| `DEPLOY_SSH_KEY` | Secret | SSH private key |
| `DEPLOY_KNOWN_HOSTS` | Secret | Verified SSH host-key entry |
| `DEPLOY_ENABLED` | Variable | Set to `true` to enable deployment |

The server also needs access to the GHCR image, including registry authentication if the package is private.

When deployment is enabled, a successful push to `main` invokes [`scripts/remote_deploy.sh`](scripts/remote_deploy.sh). The script pulls the new image, performs a pre-deployment health check, publishes the service on server port `8000` (mapping `8000:8000` by default), and checks `http://127.0.0.1:8000/health` on the server.

After at least two different image versions have been deployed, use **Actions → Roll back previous image → Run workflow** to restore the prior image. The deployment script also attempts to restore the previous image if a new deployment fails its final health check.

The SSH deployment workflows are configured in the repository; successful operation on a persistent host depends on that host and its credentials being configured.

### Additional Deployment Workflows

- **Docker deployment and rollback test:** [`docker-image-rollback.yml`](.github/workflows/docker-image-rollback.yml) verifies image switching, health checks, and rollback on a temporary GitHub Actions runner.
- **LocalStack Lambda deployment:** [`localstack-hobby.yml`](.github/workflows/localstack-hobby.yml) packages the API for emulated AWS Lambda, checks the endpoints, and tests Lambda version rollback.

These workflows run in temporary environments; they do not create a persistent public deployment. Lambda version rollback is separate from Docker image rollback.

## Project Structure

```text
├── .github/
│   └── workflows/              # CI, deployment and rollback workflows
├── scripts/
│   ├── remote_deploy.sh        # Docker deployment and rollback
│   └── localstack_hobby_deploy.sh
├── tests/
│   └── test_app.py             # Flask API tests
├── app.py                      # Flask application and tour data
├── lambda_handler.py           # Lambda HTTP event adapter
├── Dockerfile                  # Container build configuration
├── requirements.txt            # Runtime dependencies
└── requirements-dev.txt        # Development and test dependencies
```

## Available Commands

| Command | Purpose |
| --- | --- |
| `python app.py` | Start the development API |
| `python -m pytest -q` | Run automated tests |
| `docker build -t tidewater-tours:local .` | Build a local Docker image |
| `docker run --rm -p 127.0.0.1:8000:8000 tidewater-tours:local` | Run the API in Docker |

For deployment operations, use the corresponding workflows in the repository's **Actions** tab.
