#!/bin/bash

set -euo pipefail

# Configuration
DOCKER_HUB_REPO="${DOCKER_HUB_REPO:-bnutzer/otbr-tcp}"
IMAGE_TAG="${IMAGE_TAG:-$(date +%Y%m%d)}"
PLATFORMS="linux/amd64,linux/arm64"

# Cleanup function
cleanup() {
	local exit_code=$?
	if [[ -n "${BUILDER_NAME:-}" ]] && docker buildx ls 2>/dev/null | grep -q "$BUILDER_NAME"; then
		echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} Cleaning up: switching back to default builder"
		docker buildx use default 2>/dev/null || true
	fi
	exit $exit_code
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
	echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

warn() {
	echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $*"
}

error() {
	echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $*" >&2
	exit 1
}

# Check if buildx is available
if ! docker buildx version >/dev/null 2>&1; then
	error "Docker buildx is required but not available. Please install Docker Desktop or enable buildx."
fi

# Check if logged into Docker Hub (skip in CI environments)
if [[ -z "${CI:-}" ]] && [[ -z "${GITHUB_ACTIONS:-}" ]]; then
	if [[ ! -f ~/.docker/config.json ]] || ! grep -q "auths" ~/.docker/config.json 2>/dev/null; then
		warn "Not logged into Docker Hub. Run 'docker login' first."
		echo "Would you like to login now? (y/n)"
		read -r response
		if [[ "$response" == "y" ]]; then
			docker login
		else
			error "Docker Hub login required to push images."
		fi
	fi
fi

# Check if we're in a git repository and if git tag already exists
if ! git rev-parse --git-dir >/dev/null 2>&1; then
	error "Not in a git repository. Cannot create git tag."
fi

if git tag -l | grep -q "^$IMAGE_TAG$"; then
	error "Git tag '$IMAGE_TAG' already exists. Use a different tag or delete the existing one."
fi

# Create/use buildx builder
BUILDER_NAME="otbr-builder"
if ! docker buildx ls | grep -q "$BUILDER_NAME"; then
	log "Creating buildx builder: $BUILDER_NAME"
	docker buildx create --name "$BUILDER_NAME" --driver docker-container --use
	docker buildx inspect --bootstrap
else
	log "Using existing buildx builder: $BUILDER_NAME"
	docker buildx use "$BUILDER_NAME"
fi

# Build and push multi-architecture image
log "Building and pushing multi-architecture image..."
log "Repository: $DOCKER_HUB_REPO"
log "Tag: $IMAGE_TAG"
log "Platforms: $PLATFORMS"

docker buildx build \
	--platform "$PLATFORMS" \
	--tag "$DOCKER_HUB_REPO:$IMAGE_TAG" \
	--tag "$DOCKER_HUB_REPO:latest" \
	--push \
	.

log "Successfully built and pushed $DOCKER_HUB_REPO:$IMAGE_TAG and $DOCKER_HUB_REPO:latest"
log "Image supports: $PLATFORMS"

# Create git tag
log "Creating git tag: $IMAGE_TAG"
git tag -a "$IMAGE_TAG" -m "Release version $IMAGE_TAG"

log "Build and push completed successfully!"
log "Docker images: $DOCKER_HUB_REPO:$IMAGE_TAG and $DOCKER_HUB_REPO:latest"
log "Git tag: $IMAGE_TAG created"
log ""
log "To push the git tag to remotes, run:"
log "  git push origin $IMAGE_TAG"
log "  git push github $IMAGE_TAG"
