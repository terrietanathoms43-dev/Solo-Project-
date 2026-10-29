# Tidewater Tours — Apex Solo Project

A small Flask API packaged in Docker, tested automatically by GitHub Actions, and published to GitHub Container Registry (GHCR) using immutable commit-SHA tags.

**Assignment due:** Monday 9 November 2026, 9:00 a.m.

## What works and what still needs configuration

- ✅ Flask sample API: `/`, `/tours`, `/tours/1`, `/health`.
- ✅ Automated pytest tests. A failed test blocks publishing and deployment.
- ✅ Dockerfile: slim Python base, non-root app user, healthcheck and Gunicorn.
- ✅ GitHub Actions CI: tests first, then builds and pushes to GHCR tagged with the Git commit.
- ✅ Optional SSH deployment and one-action rollback *workflow files* are included.
- ⏳ A live environment, server credentials and deployment evidence are **not configured**. The instructor must confirm whether AWS, a shared sandbox, or LocalStack is required.

### Architecture

`GitHub push → pytest → Docker build → GHCR:commit-sha → (if configured) SSH target → /health`

Failed tests stop before the Docker build or deployment. Images are saved with immutable SHA tags, so a previous version can be selected for rollback.

## Use entirely from a phone

1. Open the repository in your phone browser (enable **Desktop site** if necessary).
2. Choose **Actions → Test, Build & Publish** to see CI runs and logs. A push to `main` starts this workflow automatically. You can also choose **Run workflow**.
3. Check the `test` job first; the `publish` job runs only if tests succeed.
4. Open **Packages** in your GitHub account to find the published container image. The GHCR package may initially be private; make it public **only if appropriate for the exercise**, or authenticate Docker on the deployment host.
5. When an environment is agreed on, add the deployment settings below using **Settings → Secrets and variables → Actions** in GitHub. Never paste credentials in source files or chat.
6. For proof of a blocked build, edit a test on a **temporary branch** to make an assertion fail, open a pull request to `main`, and screenshot the red test job. **Do not merge that intentionally failing branch.** Restore/close it afterward.
7. After you have deployed at least two different images, use **Actions → Roll back previous image → Run workflow** to roll back and screenshot its successful health check.

## API endpoints

| Route | Purpose |
| --- | --- |
| `GET /` | Welcome message and service version |
| `GET /tours` | List sample tours |
| `GET /tours/1` | Details of tour 1 |
| `GET /health` | JSON health indicator and current version |

For example, `GET /health` responds with JSON like `{"status":"ok","service":"tidewater-tours","version":"local"}`. In Docker images built by CI, the version is the commit SHA.

## Optional local commands (only if a computer becomes available)

```bash
python -m pip install -r requirements-dev.txt
python -m pytest -q
docker build -t tidewater-tours:local .
docker run --rm -p 8080:8000 tidewater-tours:local
# Visit http://localhost:8080/health
```

A laptop is not required for CI. GitHub-hosted runners do the testing and Docker build.

## Enable automatic deployment to a Docker-capable SSH sandbox

**Do not enable deployment before the instructor chooses the target.** The included deployment job assumes a Linux server that has Docker and curl, a dedicated SSH account that can run Docker, and (if the GHCR package is private) Docker authentication for that account.

In repository **Settings → Secrets and variables → Actions**:

**Repository secrets:**
- `DEPLOY_HOST` — approved server DNS name or IP
- `DEPLOY_USER` — SSH username for the approved server
- `DEPLOY_SSH_KEY` — private key for that limited-deployment account
- `DEPLOY_KNOWN_HOSTS` — verified SSH host public-key entry obtained from the administrator, not an unverified scan

**Repository variable:**
- `DEPLOY_ENABLED` = `true` only when the above are configured and the target is approved.

Then a successful push to `main` deploys the image automatically using `scripts/remote_deploy.sh`. The job checks `http://127.0.0.1:8080/health` **on the server**. This local binding is intentional; publishing the service on a public domain requires an administrator-approved reverse proxy and firewall setup.

To roll back: **Actions → Roll back previous image → Run workflow**. Rollback is available only after a deployment has replaced an earlier running image. On the server the script records the last image tag in `~/.tidewater/previous_image`; it probes the target image before swapping and checks health afterward. On failed health, it attempts to restore the prior image automatically.

**Note:** An AWS or LocalStack deployment might need a different adapter if there is no SSH-accessible Docker host. Do not call the assignment fully deployed until the required environment is chosen, a successful health check is observed there, and rollback is demonstrated.

## Size and security explanation

The Dockerfile uses `python:3.12-slim`, installs only the production dependencies, excludes tests and Git metadata via `.dockerignore`, and uses a non-root user. A multi-stage build was not used because this tiny API has no compiled artifacts or build toolchain; it would add complexity without a clear size benefit. The registry login uses the automatically supplied, permission-scoped `GITHUB_TOKEN`. No access keys are committed.

## Submission checklist

- [ ] Repository link and this README
- [ ] Screenshot of green test/build/publish run
- [ ] Screenshot of failed test stopping publish (temporary PR branch)
- [ ] Actual deployment with passing `/health` endpoint
- [ ] Screenshot of rollback and confirmation of older version
- [ ] Short runbook: [RUNBOOK.md](RUNBOOK.md)
- [ ] Nine-step notes written in **your own words**: [NINE_STEP_NOTES.md](NINE_STEP_NOTES.md)

The brief does not name the headings in the instructor's nine-step framework. The notes file is a scaffold to personalize and check against your coach's nine headings.
