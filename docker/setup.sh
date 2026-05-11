#!/bin/bash
# Installs Docker CE and runs a small custom Nginx image built from ./web.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/deps.sh"

require_root

WEB_DIR=$SCRIPT_DIR/web
IMAGE=custom_nginx_image
CONTAINER=my_web_container
HOST_PORT=8080

log "installing Docker"
install_docker_packages

systemctl enable docker
systemctl start docker
systemctl is-active --quiet docker || die "docker service didn't come up"

log "smoke test (whalesay)"
docker run --rm docker/whalesay cowsay "Hello from Docker"

log "building $IMAGE from $WEB_DIR"
docker build -t "$IMAGE" "$WEB_DIR"

# Re-run cleanly even if a previous container is hanging around.
docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker run -d -p "$HOST_PORT:80" --name "$CONTAINER" "$IMAGE"

log "web server up at http://localhost:$HOST_PORT"
