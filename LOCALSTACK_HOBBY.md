# LocalStack Hobby — verified deployment demonstration

This document records an **AWS Lambda ZIP deployment** demonstration for the Tidewater Tours Flask API. It complements, but does not replace, the separate Docker image workflow. In particular, **Lambda version rollback is not Docker-image rollback**.

## Verified GitHub Actions evidence (3 November 2026)

- [Green LocalStack Hobby run](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/41688357772)
- [Green Docker build / publish run](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/41688358049)
- [Intentional failing-test run](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/41558734147) — the failure stopped build / publish on the evidence-only pull request; **do not merge it**.

The LocalStack workflow confirmed:
1. Existing Flask API and Lambda adapter tests passed.
2. LocalStack started using the `LOCALSTACK_AUTH_TOKEN` GitHub repository secret.
3. A ZIP of the Flask app was deployed to emulated AWS Lambda (version `1`).
4. Lambda Function URL `/health` returned `status=ok` and version `88e6fcec440c-v1`.
5. Function URL `/tours` returned three tours.
6. A second Lambda version `2` was published and made live; `/health` returned `88e6fcec440c-v2`.
7. The `live` Lambda alias was updated to version `1`, then `/health` again returned `88e6fcec440c-v1`.

These checks ran on a GitHub-hosted Ubuntu runner. The Function URL was a **localhost.localstack.cloud** URL and only worked in the runner while LocalStack was running; it is not an ongoing public deployment.

## How to repeat the demonstration (phone-friendly)

1. Open **GitHub → repository → Actions**.
2. Select **LocalStack Hobby - Flask Lambda Deploy and Rollback**.
3. Click **Run workflow** and choose `main`.
4. Open the workflow run. Check that **Test Flask API and Lambda adapter** and **Deploy Lambda, health-check, and roll back** are green.
5. Expand **Deploy API and demonstrate Lambda version rollback** to see both health responses and the rollback confirmation. Screenshot them before submitting the evidence.

The workflow also runs automatically when the specified source, test, deployment script, or workflow files change on `main`.

## How it works

- `.github/workflows/localstack-hobby.yml` first runs `pytest` and stops on failures.
- It installs `lstk`, starts LocalStack, and uses the GitHub secret `LOCALSTACK_AUTH_TOKEN`. The workflow does not print the token.
- `scripts/localstack_hobby_deploy.sh` installs the Flask dependencies into a Lambda ZIP, publishes two Lambda versions, tests the HTTP Function URL, and rolls the `live` alias back to the first published version.
- `lambda_handler.py` adapts HTTP requests for Flask. The original Dockerfile still runs the same Flask API with Gunicorn.
- `.github/workflows/ci.yml` independently tests, builds, smoke-tests, and publishes a commit-tagged Docker image to GitHub Container Registry.

## Honest assignment limitation

LocalStack Hobby emulates AWS Lambda and supports the demonstrated temporary deployment. **It does not include ECR or ECS**, so it cannot complete the assignment's Docker-image deployment and one-action **previous-image** rollback in the same way as the included SSH Docker deployment scripts. The instructor must approve either:
- A Docker-enabled shared sandbox, or
- A qualifying LocalStack Student account with ECS, with a separate deployment integration,

to complete the original image-based requirement, or explicitly approve the Lambda version-based demonstration as an alternative.

The SSH Docker image deployment and rollback files exist in the repository but **were not executed against a real Docker server**. Do not screenshot the Lambda alias rollback and label it as previous Docker image restoration.

## Practical security note

Never share the CI Auth Token in chat, screenshots, or a committed file. It belongs in **GitHub → Settings → Secrets and variables → Actions**, named `LOCALSTACK_AUTH_TOKEN`.
