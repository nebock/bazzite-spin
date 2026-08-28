#!/bin/bash

set -ouex pipefail

# Based on AmyOS's script to install apps
# https://github.com/astrovm/amyos/blob/706164a6f48d48d3b86482fa3265a27ca3762e3c/build_files/install-apps.sh

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

# RPM packages list
declare -A RPM_PACKAGES=(
  ["fedora"]="\
    guestfs-tools \
    kitty \
    libvirt \
    libvirt-daemon-config-network \
    libvirt-daemon-kvm \
    nmap \
    qemu-kvm \
    virt-install \
    virt-manager \
    virt-viewer \
    " 

  ["netbird"]="\
    netbird-ui \
    --setopt=tsflags=noscripts"
)

log "Starting build process"

log "Installing RPM packages"
mkdir -p /var/opt
for repo in "${!RPM_PACKAGES[@]}"; do
  read -ra pkg_array <<<"${RPM_PACKAGES[$repo]}"
  if [[ $repo == copr:* ]]; then
    # Handle COPR packages
    copr_repo=${repo#copr:}
    dnf5 -y copr enable "$copr_repo"
    dnf5 -y install "${pkg_array[@]}"
    dnf5 -y copr disable "$copr_repo"
  else
    # Handle regular packages
    [[ $repo != "fedora" ]] && enable_opt="--enable-repo=$repo" || enable_opt=""
    cmd=(dnf5 -y install)
    [[ -n "$enable_opt" ]] && cmd+=("$enable_opt")
    cmd+=("${pkg_array[@]}")
    "${cmd[@]}"
  fi
done

log "Build process completed"

systemctl enable podman.socket
