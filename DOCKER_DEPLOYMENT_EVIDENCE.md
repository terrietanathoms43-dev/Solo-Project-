# Docker Deployment and Rollback Evidence — APPEX Solo Project

**Date verified:** 3 November 2026

**Proof:** [Successful Docker Image Deployment and Rollback Proof run](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/41690335739)

**Workflow file:** [`.github/workflows/docker-image-rollback.yml`](.github/workflows/docker-image-rollback.yml)

## What the workflow did

1. Checked out the repository and ran automated API tests. The test job passed before deployment began.
2. Built one Docker image from the previous Git commit and another from the current Git commit, each with an immutable commit SHA tag. The `APP_VERSION` build argument lets `GET /health` report the image's version.
3. Started the **previous Docker image** as a container on port `18080` and verified `GET /health`.
4. Started the **current Docker image** on a separate preflight port `18081`, then replaced the previous running container with the current image on port `18080`. Both health checks passed.
5. Rolled back by replacing the current container with the previous Docker image and verified the image reference and `GET /health` response.

## Recorded results

| Stage | Image version | Result |
| --- | --- | --- |
| Previous image deployed | `48d2f4d75d596da82f2cc43cf8c91dfe18350bdf` | Passed |
| Current image deployed | `064826ef7b8209b6366a2860129e599457570823` | Passed |
| Previous image restored | `48d2f4d75d596da82f2cc43cf8c91dfe18350bdf` | Passed |

The final job log confirms:

```text
ROLLBACK VERIFIED: tidewater-tours:48d2f4d75d596da82f2cc43cf8c91dfe18350bdf is now running and healthy
```

## Capture screenshots on a phone

Open the [successful run](https://github.com/terrietanathoms43-dev/Solo-Project-/actions/runs/41690335739) in GitHub, choose **Deploy two Docker images and roll back**, then expand **Deploy previous image, update to current, then roll back**. Take screenshots of these groups:
- **1. Deploy previous Docker image** — initial health check
- **2. Preflight newer Docker image and deploy it** — updated container and health check
- **3. One-step rollback to previous Docker image** — final health check and `ROLLBACK VERIFIED`

Use GitHub's step log's disclosure arrows to expand each group.

## Important limits

- These images were built locally on a GitHub-hosted runner for the demonstration. The repository's separate [Test, Build & Publish workflow](.github/workflows/ci.yml) builds, health-checks, tags and publishes Docker images to GitHub Container Registry.
- The Docker containers were run **on a temporary GitHub Actions runner**, not deployed on LocalStack, AWS or an APPEX-provided persistent shared sandbox. They stop when the job ends.
- The two Git commits were adjacent and may contain no changes to the API itself; the reported version and image tags differ. The demonstration verifies Docker image switching and health checking, not a business-feature change.
- A coach-approved deployment destination remains necessary if the rubric requires AWS/LocalStack/shared sandbox specifically. LocalStack Hobby lacks the AWS ECS/ECR services used for container deployment.
- The separate [LocalStack Hobby demonstration](LOCALSTACK_HOBBY.md) deploys a Lambda ZIP and rolls back Lambda versions; it is **not** Docker container deployment.
- This workflow's complete deploy-and-rollback sequence is run through **Actions → Docker Image Deployment and Rollback Proof → Run workflow**. It can also run after changes to its own workflow file. It is **not** the separately configured persistent-host SSH rollback workflow.
