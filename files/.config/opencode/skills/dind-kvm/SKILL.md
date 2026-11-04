---
name: DinD via KVM
description: Root-only DinD — a minimal Alpine VM on KVM whose Docker daemon is forwarded to localhost:2375. Use when the user asks to run or build with docker inside this sandbox. /root and /home are shared into the guest at the same paths, so bind mounts use host paths.
---

# DinD via KVM

This sandbox has no `CAP_SYS_ADMIN`, so dockerd cannot run natively. Instead a
122MB Alpine "tiny cloud" VM runs on QEMU/KVM as root and its Docker daemon
is forwarded to the sandbox over TCP. Everything runs as root.

## Usage

```sh
"$SKILL_DIR/scripts/dind-kvm.sh" up     # idempotent boot + wait (first run: ~5 min)
export DOCKER_HOST=tcp://127.0.0.1:2375
docker run --rm hello-world
docker run --rm -v /home/hrntknr/work/<project>:/src alpine ls /src   # host paths work
```

Other subcommands: `status`, `down`, `clean` (deletes VM disks).

## What works

- `docker build / run / exec / compose` — build contexts are streamed, no
  mount needed for builds.
- Bind mounts, read-write, using **host paths**: the sandbox's `/root` and
  `/home` are 9p-shared into the guest at the same paths, so any project is
  bind-mountable without restarting the VM.
- One VM per machine is shared by all sessions on it (`state/qemu.pid` guards
  double-boot); images and caches are shared too.
- Instance isolation if needed: `DIND_STATE`/`DIND_DPORT` env overrides
  (e.g. per-project state dirs) allow side-by-side VMs.

## Notes

- `state/` (base image, disks) is gitignored and must survive skill
  redeploys; exclude it when copying the skill directory.
- The guest root equals the sandbox user, so the VM (and containers in it)
  can read/write everything under the shared `/root` and `/home` — including
  mounted credentials. Same trust model as a local Docker daemon.
- No ssh port into the VM by design. Debug via the guest console log
  (`state/console.log`); `down` sends `system_powerdown` through the QEMU
  human-monitor socket `state/monitor.sock`, which the guest's acpid turns
  into a clean poweroff.
- The seed installs docker and acpid, formats the 50GB `/var/lib/docker`
  disk, and starts dockerd on `tcp://0.0.0.0:2375` (openrc `cgroups`
  dependency has a flaky-start fallback in `/etc/local.d/dind.start`).

## Required host-side setup (outside the sandbox)

`/dev/kvm` must be passed in (podman `--device /dev/kvm`) and made
accessible (`sudo chmod 666 /dev/kvm`, or kvm group +
`--group-add keep-groups`). `up` fails fast with this hint if missing.
