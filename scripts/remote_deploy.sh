#!/usr/bin/env bash
# Run on an instructor-approved Docker host via SSH from GitHub Actions.
set -Eeuo pipefail

MODE="${1:-}"
REQUESTED_IMAGE="${2:-}"
APP_CONTAINER="tidewater-api"
PREFLIGHT_CONTAINER="tidewater-api-preflight"
STATE_DIR="$HOME/.tidewater"
PREVIOUS_FILE="$STATE_DIR/previous_image"
mkdir -p "$STATE_DIR"

health_check() {
  local port="$1"
  local attempt
  for attempt in {1..15}; do
    if curl --fail --silent --max-time 2 "http://127.0.0.1:$port/health" >/dev/null; then
      return 0
    fi
    sleep 2
  done
  return 1
}

running_image() {
  docker inspect --format '{{.Config.Image}}' "$APP_CONTAINER" 2>/dev/null || true
}

switch_image() {
  local new_image="$1"
  local old_image="$2"

  echo "Preparing image: $new_image"
  docker pull "$new_image"

  # Confirm the replacement image works without disrupting the current service.
  docker rm -f "$PREFLIGHT_CONTAINER" >/dev/null 2>&1 || true
  docker run -d --name "$PREFLIGHT_CONTAINER" -p 127.0.0.1:18080:8000 "$new_image" >/dev/null
  if ! health_check 18080; then
    docker logs --tail 40 "$PREFLIGHT_CONTAINER" || true
    docker rm -f "$PREFLIGHT_CONTAINER" >/dev/null 2>&1 || true
    echo "Preflight health check failed. The existing service was not changed." >&2
    exit 1
  fi
  docker rm -f "$PREFLIGHT_CONTAINER" >/dev/null

  docker rm -f "$APP_CONTAINER" >/dev/null 2>&1 || true
  if ! docker run -d --name "$APP_CONTAINER" --restart unless-stopped -p 127.0.0.1:8080:8000 "$new_image" >/dev/null; then
    echo "Could not start new container; attempting to restore previous image." >&2
    restore_image "$old_image"
    exit 1
  fi

  if ! health_check 8080; then
    docker logs --tail 40 "$APP_CONTAINER" || true
    docker rm -f "$APP_CONTAINER" >/dev/null 2>&1 || true
    echo "Deployed image failed health check; attempting previous image." >&2
    restore_image "$old_image"
    exit 1
  fi

  if [[ -n "$old_image" && "$old_image" != "$new_image" ]]; then
    printf '%s\n' "$old_image" > "$PREVIOUS_FILE"
  fi
  echo "Deployment healthy:"
  curl --fail --silent --show-error "http://127.0.0.1:8080/health"
  echo
}

restore_image() {
  local prior="$1"
  if [[ -z "$prior" ]]; then
    echo "No previous image available to restore." >&2
    return 1
  fi
  docker rm -f "$APP_CONTAINER" >/dev/null 2>&1 || true
  docker run -d --name "$APP_CONTAINER" --restart unless-stopped -p 127.0.0.1:8080:8000 "$prior" >/dev/null
  health_check 8080
}

case "$MODE" in
  deploy)
    [[ -n "$REQUESTED_IMAGE" ]] || { echo "An image tag is required for deploy." >&2; exit 2; }
    switch_image "$REQUESTED_IMAGE" "$(running_image)"
    ;;
  rollback)
    [[ -s "$PREVIOUS_FILE" ]] || { echo "No previous version recorded. Deploy two versions first." >&2; exit 2; }
    previous="$(cat "$PREVIOUS_FILE")"
    current="$(running_image)"
    [[ -n "$current" ]] || { echo "No current running container to roll back." >&2; exit 2; }
    switch_image "$previous" "$current"
    ;;
  *)
    echo "Usage: bash remote_deploy.sh deploy IMAGE | rollback" >&2
    exit 2
    ;;
esac
