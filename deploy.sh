#!/usr/bin/env sh
set -eu

IMAGE_NAME="${IMAGE_NAME:-sorvec-official-web}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_NAME="${CONTAINER_NAME:-sorvec-official-web}"
HOST_HTTP_PORT="${HOST_HTTP_PORT:-80}"
HOST_HTTPS_PORT="${HOST_HTTPS_PORT:-443}"

usage() {
  cat <<USAGE
Usage: ./deploy.sh [--rebuild]

Environment overrides:
  IMAGE_NAME       Docker image name (default: sorvec-official-web)
  IMAGE_TAG        Docker image tag (default: latest)
  CONTAINER_NAME   Docker container name (default: sorvec-official-web)
  HOST_HTTP_PORT   Host HTTP port (default: 80)
  HOST_HTTPS_PORT  Host HTTPS port (default: 443)
USAGE
}

REBUILD=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --rebuild)
      REBUILD=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required but was not found in PATH." >&2
  exit 1
fi

IMAGE_REF="${IMAGE_NAME}:${IMAGE_TAG}"

if [ "$REBUILD" -eq 1 ] || ! docker image inspect "$IMAGE_REF" >/dev/null 2>&1; then
  echo "Building Docker image: $IMAGE_REF"
  docker build -t "$IMAGE_REF" .
else
  echo "Using existing local Docker image: $IMAGE_REF"
fi

if docker ps -a --format '{{.Names}}' | grep -Fx "$CONTAINER_NAME" >/dev/null 2>&1; then
  echo "Stopping and removing existing container: $CONTAINER_NAME"
  docker rm -f "$CONTAINER_NAME" >/dev/null
fi

echo "Starting container: $CONTAINER_NAME"
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p "${HOST_HTTP_PORT}:80" \
  -p "${HOST_HTTPS_PORT}:443" \
  -v "${CONTAINER_NAME}-caddy-data:/data" \
  -v "${CONTAINER_NAME}-caddy-config:/config" \
  "$IMAGE_REF"

echo "Deployment complete."
docker ps --filter "name=${CONTAINER_NAME}" --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
