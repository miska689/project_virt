#!/bin/bash
# All package installation lives here so the setup scripts stay focused
# on the actual provisioning logic.

install_kvm_packages() {
    apt-get update
    apt-get install -y \
        qemu-kvm \
        libvirt-daemon-system \
        libvirt-clients \
        bridge-utils \
        virtinst \
        libguestfs-tools
}

install_lxc_packages() {
    apt-get update
    apt-get install -y lxc lxc-utils lxc-templates bridge-utils
}

install_docker_packages() {
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release

    # Pull Docker's signing key and pin it to the apt source we add below.
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    local arch codename
    arch=$(dpkg --print-architecture)
    codename=$(. /etc/os-release && echo "$VERSION_CODENAME")

    cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$arch signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $codename stable
EOF

    apt-get update
    apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
}

install_minikube_binary() {
    command -v minikube >/dev/null 2>&1 && return

    local tmp
    tmp=$(mktemp)
    curl -L --fail -o "$tmp" \
        https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install "$tmp" /usr/local/bin/minikube
    rm -f "$tmp"
}

install_kubectl_binary() {
    command -v kubectl >/dev/null 2>&1 && return

    local version tmp
    version=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    tmp=$(mktemp)
    curl -L --fail -o "$tmp" \
        "https://dl.k8s.io/release/$version/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 "$tmp" /usr/local/bin/kubectl
    rm -f "$tmp"
}
