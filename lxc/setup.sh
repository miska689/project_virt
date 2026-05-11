#!/bin/bash
# Creates an Ubuntu 22.04 LXC container with Nginx, snapshots it,
# and clones the snapshot into a second container.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/deps.sh"

require_root

# Avoid apt prompts (tzdata etc.) inside the container.
export DEBIAN_FRONTEND=noninteractive

CONTAINER=web_container
CLONE=cloned_web_container

log "installing LXC stack"
install_lxc_packages

log "creating $CONTAINER (ubuntu jammy)"
lxc-create -n "$CONTAINER" -t download -- -d ubuntu -r jammy -a amd64

# Auto-start the container at host boot.
echo "lxc.start.auto = 1" >> "/var/lib/lxc/$CONTAINER/config"

log "starting and installing nginx"
lxc-start -n "$CONTAINER"

# Wait for DHCP -- attach will fail without network.
sleep 15
lxc-attach -n "$CONTAINER" -- apt-get update
lxc-attach -n "$CONTAINER" -- apt-get install -y nginx

log "snapshotting (requires container stopped)"
lxc-stop -n "$CONTAINER"
lxc-snapshot -n "$CONTAINER"

log "cloning snapshot to $CLONE and restarting original"
lxc-snapshot -n "$CONTAINER" -r snap0 -N "$CLONE"
lxc-start -n "$CONTAINER"

log "done"
