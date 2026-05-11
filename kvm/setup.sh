#!/bin/bash
# Provisions a Debian 11 VM under KVM/libvirt and takes a live (disk-only)
# snapshot once it's up.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/deps.sh"

require_root

VM_NAME=debian_vm
IMG_DIR=/var/lib/libvirt/images
MAIN_DISK=$IMG_DIR/debian_image.qcow2
EXTRA_DISK=$IMG_DIR/extra_disk.qcow2

log "installing KVM stack"
install_kvm_packages

log "bringing up the default libvirt network"
# These can fail if the network is already running -- we don't care.
virsh net-start default     2>/dev/null || true
virsh net-autostart default 2>/dev/null || true

ip link show virbr0 >/dev/null 2>&1 || die "virbr0 is missing -- libvirt network didn't come up"

log "building the Debian image (this can take a few minutes)"
virt-builder debian-11 \
    --size 10G \
    --format qcow2 \
    --hostname maquinaDebian \
    --install openssh-server \
    --run-command 'systemctl enable ssh' \
    --run-command 'echo "Welcome to your Debian machine" > /etc/motd' \
    -o "$MAIN_DISK"

log "defining VM $VM_NAME"
virt-install \
    --name "$VM_NAME" \
    --memory 2048 \
    --vcpus 2 \
    --disk "path=$MAIN_DISK,format=qcow2,bus=virtio" \
    --import \
    --os-variant debian11 \
    --network network=default,model=virtio \
    --noautoconsole

log "creating and attaching a 5G secondary disk"
qemu-img create -f qcow2 "$EXTRA_DISK" 5G
virsh attach-disk "$VM_NAME" "$EXTRA_DISK" vdb --subdriver qcow2 --persistent

# A live snapshot needs the domain to be running.
if [ "$(virsh domstate "$VM_NAME")" != "running" ]; then
    virsh start "$VM_NAME"
fi

log "waiting for the guest to settle before snapshotting"
sleep 10

virsh snapshot-create-as \
    --domain "$VM_NAME" \
    --name hot_snapshot \
    --description "Hot snapshot" \
    --disk-only \
    --atomic

log "done"
