# Tidewater Tours — deployment runbook

**Prerequisites:** A passing GitHub Actions test job, an image in GHCR, and an instructor-approved Linux Docker server with curl and SSH access. In GitHub Settings → Secrets and variables → Actions, configure `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, `DEPLOY_KNOWN_HOSTS` and set the repository variable `DEPLOY_ENABLED=true`. If the GHCR package is private, the server's Docker account must be authenticated to GHCR; otherwise make the exercise package public where appropriate.

**Deploy:** Push a change to `main`. Open **Actions → Test, Build & Publish** and verify the **test** job is green. The next job builds a Docker image, tags it with the full Git commit SHA, and uploads it to GHCR. With deployment enabled, the **deploy** job connects to the approved server, pulls the image, tests its health on temporary port 18080, replaces the running container on localhost port 8080, and checks `/health` again. Check the job logs for the JSON health response and version SHA.

**Rollback:** After at least two image versions have been deployed, open **Actions → Roll back previous image → Run workflow** on `main`. This runs `scripts/remote_deploy.sh rollback`, which retrieves the prior Docker image tag from `~/.tidewater/previous_image`, checks it first, swaps containers, checks `/health`, and records the replaced version. Screenshot the green rollback job and compare the reported version to the earlier image tag.

**Troubleshooting:** If tests fail, open the test step logs and fix the code before deploying. If deployment cannot pull the image, check GHCR package visibility or the host's Docker login. If SSH fails, confirm approved host details, permissions and trusted host key. If health fails, inspect the deploy job and container logs. Never commit secrets or disable host key verification.


## LocalStack Hobby: verified alternative deployment demo (Lambda ZIP)

This separate demonstration **has been executed successfully**, but it is **not** a Docker-image deployment or previous-image rollback. See [LOCALSTACK_HOBBY.md](LOCALSTACK_HOBBY.md) for verified run links, health responses, and screenshot instructions.

**Prerequisite:** GitHub Actions repository secret `LOCALSTACK_AUTH_TOKEN` is configured. Never commit or display its value.

**Deploy and verify:** On GitHub open **Actions → LocalStack Hobby - Flask Lambda Deploy and Rollback → Run workflow**. The workflow runs tests, starts LocalStack on a temporary GitHub-hosted runner, packages the Flask API as a Lambda ZIP, exposes it through a Lambda Function URL, and confirms that `/health` and `/tours` work. It deploys a second published Lambda version and validates its health.

**Rollback:** The same workflow changes the Lambda alias `live` to the previous published Lambda version and checks the version reported by `/health`. This is a Lambda alias rollback (not a Docker-image rollback). The command is `aws --profile localstack lambda update-alias --function-name tidewater-tours-hobby --name live --function-version 1` in the fresh emulated run (the actual previous version is determined dynamically in the script).

**Troubleshooting:** Expand the failed step in GitHub Actions. If the token step fails, verify the secret name. If the Lambda deployment fails, inspect `LocalStack diagnostics on failure` and the Lambda function/runtime logs. The emulator is removed when the runner finishes and is not an always-on website.
