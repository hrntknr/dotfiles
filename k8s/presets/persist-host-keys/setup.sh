set -eu

ssh-keygen -t ed25519 -N "" -C "" -f "$K8S_GEN_COMPONENT_DIR/ssh_host_ed25519_key" >/dev/null
