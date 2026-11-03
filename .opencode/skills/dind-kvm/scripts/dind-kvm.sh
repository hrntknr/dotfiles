#!/usr/bin/env bash
# dind-kvm: DinD via an Alpine VM on KVM. dockerd is forwarded to 127.0.0.1:2375;
# $DIND_SHARE (default: project root) is shared into the guest at /workspace.
# Subcommands: up (default) | status | down | clean
set -euo pipefail

SELF_DIR=$(cd "$(dirname "$0")" && pwd)
STATE="$SELF_DIR/../state"
if [[ -n ${DIND_SHARE:-} ]]; then
  SHARE=$DIND_SHARE
else
  SHARE=$(git -C "$SELF_DIR" rev-parse --show-toplevel 2>/dev/null) || SHARE=$(cd "$SELF_DIR/../../../.." && pwd)
fi
PORT=2222
DPORT=2375
VCPU=4 MEM=4G DATASZ=50G

URL=https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/cloud/alpine-3.23.6-x86_64-bios-tiny-r0.qcow2
IMG=${URL##*/}
SSH=(ssh -F /dev/null -i "$STATE/id_ed25519" -p "$PORT"
     -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
     -o ConnectTimeout=5 -o LogLevel=ERROR root@127.0.0.1)
export DOCKER_HOST=tcp://127.0.0.1:$DPORT

ensure_kvm() {
  [[ -w /dev/kvm ]] || { echo "/dev/kvm not writable" >&2
    echo "sandbox needs: podman --device /dev/kvm, and host-side chmod 666 /dev/kvm (or kvm group + --group-add keep-groups)" >&2
    exit 1; }
}

ensure_deps() {
  command -v qemu-system-x86_64 >/dev/null && command -v genisoimage >/dev/null && return
  apt-get update -qq && apt-get install -y -qq --no-install-recommends \
    qemu-system-x86 qemu-utils genisoimage >/dev/null
}

ensure_image() {
  [[ -f $STATE/$IMG ]] || curl -fL -C - -o "$STATE/$IMG" "$URL"
  H=$(curl -fsS "$URL.sha512" | tr -d '[:space:]')   # upstream .sha512 is a bare hash
  echo "$H  $IMG" | (cd "$STATE" && sha512sum -c --quiet)
}

ensure_key() { [[ -f $STATE/id_ed25519 ]] || ssh-keygen -q -t ed25519 -N '' -f "$STATE/id_ed25519"; }

ensure_seed() {
  cat > "$STATE/user-data" <<EOF
#!/bin/sh
exec >/dev/console 2>&1
set -x
mkdir -p /root/.ssh
echo "$(cat "$STATE/id_ed25519.pub")" > /root/.ssh/authorized_keys
chmod 700 /root/.ssh; chmod 600 /root/.ssh/authorized_keys
sed -i '/^root:/ s/^root:[^:]*:/root:*:/' /etc/shadow   # image ships root locked; blocks pubkey login
apk add --no-cache docker e2fsprogs
mkfs.ext4 -F /dev/vdb
mkdir -p /var/lib/docker /workspace
printf '%s\n' '/dev/vdb /var/lib/docker ext4 nofail 0 0' \
  'host0 /workspace 9p trans=virtio,version=9p2000.L,rw,msize=131072,nofail 0 0' >> /etc/fstab
mount /var/lib/docker
mount /workspace
mountinfo -q /sys/fs/cgroup || mount -t cgroup2 none /sys/fs/cgroup
printf '%s\n' \
  '#!/bin/sh' \
  'docker info >/dev/null 2>&1 && exit 0' \
  'mountinfo -q /sys/fs/cgroup || mount -t cgroup2 none /sys/fs/cgroup' \
  'nohup dockerd -H unix:// -H tcp://0.0.0.0:$DPORT >/var/log/docker.log 2>&1 &' \
  > /etc/local.d/dind.start   # fallback: openrc cgroups dependency can fail to start
chmod +x /etc/local.d/dind.start
printf 'DOCKER_OPTS="-H unix:// -H tcp://0.0.0.0:$DPORT"\n' > /etc/conf.d/docker
rc-update add local default
rc-update add docker default
rc-service cgroups start || true
rc-service docker start || /etc/local.d/dind.start
EOF
  printf 'instance-id: dind-alpine-001\nlocal-hostname: dind\n' > "$STATE/meta-data"
  [[ -f $STATE/seed.iso && $STATE/seed.iso -nt $STATE/user-data ]] ||
    genisoimage -quiet -output "$STATE/seed.iso" -volid cidata -joliet -rock \
      "$STATE/user-data" "$STATE/meta-data"
}

ensure_disks() {
  [[ -f $STATE/dind-vm.qcow2 ]] || qemu-img create -f qcow2 -F qcow2 -b "$STATE/$IMG" "$STATE/dind-vm.qcow2" 20G
  [[ -f $STATE/docker-data.qcow2 ]] || qemu-img create -f qcow2 "$STATE/docker-data.qcow2" "$DATASZ"
}

vm_running() { [[ -f $STATE/qemu.pid ]] && kill -0 "$(cat "$STATE/qemu.pid")" 2>/dev/null; }

boot() {
  qemu-system-x86_64 -enable-kvm -cpu host -smp "$VCPU" -m "$MEM" \
    -drive "file=$STATE/dind-vm.qcow2,if=virtio,format=qcow2,cache=writeback" \
    -drive "file=$STATE/docker-data.qcow2,if=virtio,format=qcow2,cache=writeback" \
    -drive "file=$STATE/seed.iso,if=virtio,format=raw,readonly=on" \
    -virtfs "local,mount_tag=host0,path=$SHARE,security_model=none" \
    -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:$PORT-:22,hostfwd=tcp:127.0.0.1:$DPORT-:$DPORT" \
    -device virtio-net-pci,netdev=net0 \
    -display none -serial "file:$STATE/console.log" \
    -daemonize -pidfile "$STATE/qemu.pid"
}

wait_docker() {
  local deadline=$(( $(date +%s) + 1200 ))
  until docker info >/dev/null 2>&1; do
    vm_running || { echo "QEMU died; see $STATE/console.log" >&2; exit 1; }
    (( $(date +%s) < deadline )) || { echo "timeout; see $STATE/console.log" >&2; exit 1; }
    sleep 5
  done
}

cmd_up() {
  ensure_kvm; mkdir -p "$STATE"
  ensure_deps; ensure_image; ensure_key; ensure_seed; ensure_disks
  vm_running || { boot; echo "VM started (pid $(cat "$STATE/qemu.pid"))"; }
  wait_docker
  echo "DinD ready:"
  echo "  export DOCKER_HOST=$DOCKER_HOST"
  echo "  docker run --rm hello-world   # bind mounts: -v /workspace/<dir>:..."
}

cmd_status() {
  vm_running && echo "VM running (pid $(cat "$STATE/qemu.pid"))" || echo "VM stopped"
  docker info --format 'docker {{.ServerVersion}}' 2>/dev/null || true
}

cmd_down()  { vm_running && "${SSH[@]}" poweroff || echo "already stopped"; }

cmd_clean() {
  vm_running && kill "$(cat "$STATE/qemu.pid")"
  rm -f "$STATE"/{dind-vm.qcow2,docker-data.qcow2,seed.iso,qemu.pid,console.log}
  echo "VM state reset (image and ssh key kept)"
}

case "${1:-up}" in
  up) cmd_up ;;  status) cmd_status ;;  down) cmd_down ;;  clean) cmd_clean ;;
  *) echo "usage: $0 [up|down|status|clean]" >&2; exit 2 ;;
esac
