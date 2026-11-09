# Nine Steps — GitHub Actions CI/CD for Tidewater Tours

**Project:** Tidewater Tours API  
**Repository:** [terrietanathoms43-dev/Solo-Project-](https://github.com/terrietanathoms43-dev/Solo-Project-)  
**Application stack:** Python 3.12, Flask, Gunicorn, pytest and Docker  
**Tool covered:** GitHub Actions — test → build → health-check → publish → conditional SSH deployment  
**Evidence reviewed:** 3–9 November 2026

These notes describe the actual implementation and observed evidence, not merely a proposed pipeline. They use the nine-part framework **Purpose, Use, Versions and Types, Alternatives, Limits and Risks, Logs and Observability, Configuration, Procedures, and Internals**.

## 1. Purpose — Why does the tool exist?

The CI/CD pipeline automates the checks and release tasks required to ship the Tidewater Tours API reliably. Instead of manually installing dependencies, running tests, building images and copying deployment commands, GitHub Actions performs repeatable steps when the repository changes. Failed tests prevent the image-publication and deployment jobs from starting.

The pipeline provides:
- **Quality gates:** pytest must succeed before a Docker image is published.
- **Reproducibility:** published images use an immutable Git commit SHA tag rather than relying on a changing `latest` tag.
- **Health verification:** the container must answer `/health` during the build smoke test and after SSH deployment.
- **Traceability:** each workflow run is tied to a commit and contains job results, logs and deployment evidence.

GitHub Actions fits this repository because the automation configuration resides beside the source code, works with GitHub pull requests, and can authenticate to GitHub Container Registry (GHCR).

## 2. Use — How is the tool used in real work?

When a developer changes an API route or test and opens a pull request targeting `main`, GitHub Actions runs the Python tests. It deliberately does **not** publish a container for a pull request. A push to `main` runs tests, builds the Docker image, starts it temporarily, verifies `GET /health`, and pushes a commit-tagged image to GHCR. If approved deployment settings are enabled, the workflow also deploys that image over SSH and checks the remote service.

The API exposes:
- `GET /` — basic service information and version.
- `GET /health` — service status and image version.
- `GET /tours` — sample Jamaican tour offerings.
- `GET /tours/<tour_id>` — an individual tour or HTTP 404 if the ID is unknown.

**Observed example:** [the successful 9 November 2026 run](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/42558864872) for commit `94e9c3cfc56834bf944348078daab7192df1c2ef` completed all three jobs successfully: Python tests, Docker build/publish, and approved SSH deployment. The deployment health response recorded `status: ok` and that commit SHA.

This is evidence of a healthy response checked **from the SSH deployment host**. It does not, on its own, prove that the API was publicly reachable from an unrelated network.

## 3. Versions and Types — What options and deployment approaches exist?

| Option | Role in this repository | Important distinction |
| --- | --- | --- |
| GitHub-hosted `ubuntu-latest` runner | Executes tests and build/deployment jobs | Each job starts in a temporary environment. |
| Self-hosted runner | Possible alternative | Requires maintaining and securing the runner. |
| GitHub Actions | Implemented CI/CD service | Workflow YAML files are in `.github/workflows/`. |
| SHA-tagged Docker image to GHCR | Implemented publication mechanism | The full Git SHA identifies the released build. |
| SSH Docker server deployment | Implemented conditional deployment | The server preflights an image, replaces the container and checks health. |
| Docker image rollback proof | Verified temporary demonstration | Two images are deployed on a runner, then the previous image is restored. |
| LocalStack Hobby Lambda ZIP | Verified separate demonstration | Uses published Lambda versions and alias rollback, **not** Docker-image rollback. |
| Blue/green or canary deployments | Possible design alternatives only | Not implemented in this repository. |

The working application is a Flask/Python service, **not** the Express/TypeScript application from the example `tidewater-api` repository. Its local and default SSH-published application port is **8000**.

## 4. Alternatives — What else could solve the problem?

| Alternative | When it makes sense | Why GitHub Actions was selected here |
| --- | --- | --- |
| GitLab CI | Source and pipelines hosted on GitLab | This API already uses GitHub. |
| Jenkins | Organizations needing extensive self-hosted customization | Requires managing another service and plugins. |
| AWS CodePipeline | AWS-specific release infrastructure | Adds AWS setup beyond this small repository's verified workflow. |
| Azure DevOps Pipelines | Azure-centered teams | Would add another platform for this GitHub-based project. |
| Manual Docker and SSH commands | Small experiments and emergencies | Less repeatable and easier to perform inconsistently. |

For Tidewater Tours, GitHub Actions keeps code, workflow definitions, results and registry publishing within one integrated process.

## 5. Limits and Risks — What can go wrong?

| Limit or risk | Mitigation or honest status |
| --- | --- |
| A test suite does not cover every possible bug | Run pytest, Docker `/health` smoke tests and deployment health checks; expand functional tests as needed. |
| Wrong or mutable image reference | Use the stable lowercase GHCR package name and full commit-SHA tags. |
| Incorrect SSH details or server host key | Configure the four deployment secrets; preserve strict host-key checking. Never commit credentials. |
| A newly built image starts but is unhealthy | The remote script preflights it on port 18080 **before** replacing the main container. |
| The replacement fails after the switch | `scripts/remote_deploy.sh` attempts restoration of the previous image. |
| A manual rollback has no recorded previous image | First deploy at least two distinct image versions to the persistent host. |
| A temporary demonstration is mistaken for always-on hosting | The Docker proof runner and LocalStack emulator terminate after their workflow runs. |
| An SSH-side health check is mistaken for public availability | Test from an independent network before claiming public reachability. |

**Verified blocked failure:** [the intentionally failing pull-request run on 3 November 2026](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/41558734147) shows the Python test job failed while the publishing and SSH-deployment jobs were **skipped**. This confirms the dependency gate protects later steps.

**Unverified boundary:** An actual manual rollback on the approved persistent SSH host has **not** been established by the evidence listed below. The separate temporary Docker rollback is verified; the two must not be presented as the same event.

## 6. Logs and Observability — How can I see what happened?

Open the repository's **Actions** tab, select a workflow run, then expand a job and its individual steps. The test job shows pytest results; the publishing job shows Docker build output, a smoke-test response and the GHCR push; the deployment job logs the remote health result.

### Verified evidence register

| Evidence | Run | Result |
| --- | --- | --- |
| CI, image publication and SSH deployment | [9 Nov — successful main run](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/42558864872) | Three jobs succeeded; remote `/health` reported the full commit SHA. |
| Temporary Docker deployment and previous-image rollback | [3 Nov — Docker rollback proof](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/41690335739) | Previous image → current image → previous image, with health verification. |
| Emulated Lambda deployment and alias rollback | [3 Nov — LocalStack Hobby](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/41688357772) | Lambda v1 → v2 → alias restored to v1. |
| Failing test prevents release | [3 Nov — failing test gate](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/41558734147) | Tests failed; publishing and deployment were skipped. |

The 9 November deployment reported a successful JSON health response corresponding to:

```json
{
  "service": "tidewater-tours",
  "status": "ok",
  "version": "94e9c3cfc56834bf944348078daab7192df1c2ef"
}
```

For troubleshooting on the SSH server, `docker ps`, `docker logs tidewater-api`, and `curl -fsS http://127.0.0.1:8000/health` show the running container and its local health. A successful image build alone is not proof of a healthy deployment.

## 7. Configuration — Which settings and permissions matter?

### Workflow behavior

| Rule or setting | Effect |
| --- | --- |
| Push to `main` | Runs tests; on success, builds, tests and publishes a Docker image. |
| Pull request targeting `main` | Runs tests; publishing is excluded. |
| `workflow_dispatch` | Allows manually starting the CI workflow. |
| `publish.needs: test` | Prevents image publication before passing tests. |
| `deploy.needs: publish` | Prevents deployment before image publication. |
| `DEPLOY_ENABLED=true` | Allows the SSH deploy job on `main`; otherwise it is skipped. |
| `GITHUB_TOKEN` and `packages: write` | Gives the publish job permission to push to GHCR. |
| `APP_VERSION=GITHUB_SHA` | Embeds the release identifier in the image's health response. |
| Port `8000` | Gunicorn serves on container port 8000; the SSH script defaults to host port 8000. |
| Port `18080` | Temporary Docker health-check/preflight port, **not** the normal service port. |

### Required secret names and variables

| Name | Kind | Purpose |
| --- | --- | --- |
| `DEPLOY_HOST` | Actions secret | Approved destination hostname or IP. |
| `DEPLOY_USER` | Actions secret | SSH username. |
| `DEPLOY_SSH_KEY` | Actions secret | Private SSH authentication key. |
| `DEPLOY_KNOWN_HOSTS` | Actions secret | Verified SSH host-key entry. |
| `DEPLOY_ENABLED` | Repository variable | Enables the optional SSH deployment. |
| `LOCALSTACK_AUTH_TOKEN` | Actions secret | Used only for the separate LocalStack demo. |
| `GITHUB_TOKEN` | Automatically supplied | Authenticates registry publishing during the workflow. |

The image naming pattern is:

```text
ghcr.io/terrietanathoms43-dev/apex-solo-tidewater-api:<full-commit-sha>
```

The GitHub repository name (`Solo-Project-`) and the GHCR package name (`apex-solo-tidewater-api`) are deliberately different. **Do not paste secret values into notes, screenshots or commits.**

## 8. Procedures — How do I run, deploy and roll back?

### A. Clone, install and test

```bash
git clone https://github.com/terrietanathoms43-dev/Solo-Project-.git
cd Solo-Project-
python -m pip install -r requirements-dev.txt
python -m pytest -q
python app.py
```

During local development, visit `http://127.0.0.1:8000/health` to check the Flask service. Use Docker/Gunicorn for the containerized production-style runtime.

### B. Build and check the Docker application

```bash
docker build -t tidewater-tours:local .
docker run --rm -p 127.0.0.1:8000:8000 tidewater-tours:local
```

In another terminal, run:

```bash
curl -fsS http://127.0.0.1:8000/health
```

Docker maps host port **8000** to container port **8000**. The `18080` references in scripts and CI are only for pre-deployment smoke tests.

### C. Publish and conditionally deploy

1. Push a reviewed change to `main`, or select **Actions → Test, Build & Publish → Run workflow**.
2. Confirm **Run Python tests** is green.
3. Confirm **Build, health-check and publish image** completes and the GHCR tag matches the commit SHA.
4. If `DEPLOY_ENABLED=true` and approved SSH secrets are configured, inspect **Deploy to approved SSH Docker sandbox** for the remote `Deployment healthy` response.
5. Verify the service from the server and, separately, from an external network if public accessibility is required.

### D. Restore the previous Docker image

The persistent-server workflow is **Actions → Roll back previous image → Run workflow**. It requires a previous image recorded at `~/.tidewater/previous_image`, normally after two distinct successful deployments. The rollback command pulls and preflights the prior image, switches the container, checks `/health`, and stores the image that was replaced so it can be recovered again.

For **verified demonstration evidence** rather than persistent-server rollback, use **Actions → Docker Image Deployment and Rollback Proof** and inspect the [successful 3 November run](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/41690335739). The recorded sequence restored SHA `48d2f4d75d596da82f2cc43cf8c91dfe18350bdf` after testing SHA `064826ef7b8209b6366a2860129e599457570823`.

For emulated AWS Lambda version switching, refer to [LOCALSTACK_HOBBY.md](LOCALSTACK_HOBBY.md). Lambda alias rollback does **not** count as previous Docker-image rollback.

### E. Troubleshooting

| Symptom | Check |
| --- | --- |
| Python test job fails | Open failed pytest assertions, fix the code/test, and rerun; downstream jobs should remain skipped. |
| Docker smoke test fails | Inspect `docker logs tidewater-smoke` and the `/health` route. |
| GHCR push fails | Check package name, `packages: write`, and the registry login step. |
| SSH deploy cannot connect | Check approved host/user/key and the verified host key; do not disable verification. |
| The remote health check fails | Inspect deployment step output and `docker logs tidewater-api`; determine whether previous-image restoration occurred. |
| Manual rollback says no previous image | Deploy at least two different versions successfully to the target host first. |

See [RUNBOOK.md](RUNBOOK.md) for the operational runbook and [scripts/remote_deploy.sh](scripts/remote_deploy.sh) for the actual deployment and rollback implementation. Where older prose differs, use the current script's default host port **8000**.

## 9. Internals — How does the pipeline work underneath?

1. **Ephemeral jobs:** `test`, `publish` and `deploy` run on GitHub-hosted Ubuntu runners. A container started for a workflow test is removed with the runner; it does not become a lasting server.
2. **Job dependency graph:** `publish` requires `test`; `deploy` requires `publish`. GitHub marks dependent jobs skipped if a required stage fails. A pull request also explicitly excludes publishing.
3. **Immutable version identification:** Docker is built with `APP_VERSION` set to `GITHUB_SHA`; the same SHA is the GHCR image tag and appears in `/health`.
4. **Registry authentication:** the publish job grants `packages: write` and logs into `ghcr.io` with the short-lived `GITHUB_TOKEN`, avoiding hard-coded registry credentials.
5. **Preflight deployment:** the SSH script pulls the chosen image, starts a separate temporary container on `127.0.0.1:18080`, and verifies its health before removing the existing main container.
6. **Main deployment and recovery:** the script launches `tidewater-api` with a default `8000:8000` mapping, health-checks the server on `127.0.0.1:8000`, and records the former image. If startup or post-switch health fails, it attempts to restore the former image.
7. **Independent Lambda example:** `localstack-hobby.yml` packages the Flask app as a Lambda ZIP and switches a version alias inside a temporary LocalStack environment. That flow is separate from GHCR and SSH Docker image replacement.

### Architecture and control flow

```text
Source change / pull request / manual dispatch
                    |
                    v
             GitHub Actions
                    |
             Python 3.12 + pytest
                    |
              [tests pass?]
               /         \
             no           yes
             |             |
       stop; publish     Docker build
       and deploy are        |
          skipped        smoke /health on :18080
                            |
                    GHCR SHA-tagged image
                            |
                 DEPLOY_ENABLED on main?
                       /          \
                      no          yes
                      |            |
                release stays   SSH Docker host
                   in GHCR         |
                                pull image
                                    |
                              preflight :18080
                                    |
                              switch :8000
                                    |
                            post-deploy /health
                                    |
                          record previous image
                                    |
                        manual rollback available
```

**Evidence boundaries:** The 9 November run verifies CI, GHCR publication and a healthy SSH-side deployment response. The 3 November Docker proof verifies rollback on a **temporary runner**. The separate LocalStack run verifies **Lambda-version** rollback. A persistent-host rollback or externally accessible service should only be described as verified when its corresponding evidence exists.

## Evidence and implementation links

- [Successful tests, image publishing and SSH deployment — 9 November 2026](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/42558864872)
- [Successful previous/current/previous Docker rollback proof — 3 November 2026](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/41690335739)
- [Successful LocalStack Hobby Lambda version rollback — 3 November 2026](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/41688357772)
- [Failing-test gate evidence — 3 November 2026](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/41558734147)
- [Main CI workflow](.github/workflows/ci.yml)
- [Persistent-server rollback workflow](.github/workflows/rollback.yml)
- [Docker deployment script](scripts/remote_deploy.sh)
- [Docker demonstration details](DOCKER_DEPLOYMENT_EVIDENCE.md)
- [LocalStack Hobby demonstration](LOCALSTACK_HOBBY.md)
