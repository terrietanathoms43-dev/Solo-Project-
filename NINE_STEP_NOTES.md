# Nine-step notes — GitHub Actions (student writing guide)

**Important:** The assignment doesn't specify the coach's exact nine headings. Confirm them with the coach if there is a prescribed framework. Rewrite these notes *in your own words* with screenshots or specific examples from your actual runs. The prompts are a starting point, **not** a completed personal reflection.

1. **Purpose:** What manual deployment problem does Tidewater Tours have? Why automate testing and publishing?
   - Project example: a push to `main` starts a workflow instead of someone manually building an image.

2. **Inputs:** Which GitHub event starts it, what files does it read, and where does the commit SHA come from?
   - Project example: `push` or `workflow_dispatch`; it checks out the repository.

3. **Setup:** What does the GitHub-hosted runner install or provide?
   - Project example: Python 3.12 and Docker support on an Ubuntu runner.

4. **Steps/Process:** What order do tests, Docker build, registry publish, and deployment occur in? Why?
   - Project example: `publish` needs `test`, and `deploy` needs `publish`.

5. **Internals:** How do jobs pass/fail, how does `needs` work, and why is an image tagged with the commit SHA?
   - Project example: a test's nonzero exit code fails the job; a SHA identifies a version.

6. **Outputs:** What artifacts or proof does the workflow produce?
   - Project example: the GHCR image with its SHA tag, green jobs, and `/health` JSON.

7. **Limits:** What can the current automation **not** do without extra configuration?
   - Project example: it cannot deploy to AWS/shared sandbox until there is an approved target and credentials.

8. **Logs:** Where do you find output when a step fails? Which log line did you investigate?
   - Project example: GitHub → Actions → workflow run → job → failed step. Add the *actual* error observed.

9. **Errors, recovery and rollback:** How does the system prevent a bad deployment and how is the previous image restored?
   - Project example: intentionally failing tests block publishing; a manual rollback workflow restores the earlier image.

**Before handing in:** Replace the prompts with a few sentences per step in your own language. Explain at least one real test run, one failed test, and one real rollback after your deployment target is configured.
