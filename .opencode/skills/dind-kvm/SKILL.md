---
name: DinD via KVM
description: Root-only DinD — a minimal Alpine VM on KVM whose Docker daemon is forwarded to localhost:2375. Use when the user asks to run or build with docker inside this sandbox. Bind mounts work through /workspace (9p share of the project directory).
---

# DinD via KVM

This sandbox has no `CAP_SYS_ADMIN`, so dockerd cannot run natively. Instead a
122MB Alpine "tiny cloud" VM runs on QEMU/KVM as root and its Docker daemon
is forwarded to the sandbox over TCP. Everything runs as root — no extra
user or HOME tricks.

## Usage

```sh
"$SKILL_DIR/scripts/dind-kvm.sh" up     # idempotent boot + wait + smoke test hint
export DOCKER_HOST=tcp://127.0.0.1:2375
docker run --rm hello-world
```

Other subcommands: `status`, `down`, `clean` (deletes VM disks).

## What works

- `docker build / run / exec / compose` — build contexts are streamed, no
  mount needed for builds.
- Bind mounts, read-write, for anything under `/workspace` in the guest,
  which is the **project directory** shared via 9p
  (`-v /workspace/<sub>:/path`). Use `DIND_SHARE=<dir> ./dind-alpine.sh up`
  to share a different directory.
- VM state lives in the skill's `state/` directory, which is on a host bind
  mount — it persists across sandbox re-creations.

## Required host-side setup (outside the sandbox)

`/dev/kvm` must be passed in (podman `--device /dev/kvm`) and made
accessible (`sudo chmod 666 /dev/kvm`, or kvm group + `--group-add
keep-groups`). `up` fails fast with this hint if it is missing.

## Notes baked into the script (all observed failures)

- ssh from this sandbox must use `-F /dev/null`: `/root/.ssh/config` forces every
  host through a ProxyCommand that breaks localhost connections.
- The Alpine cloud image ships with the root account **locked** (`root:!*:`),
  which silently rejects publickey logins; the seed unlocks it
  (`sed` of `/etc/shadow`). ssh (127.0.0.1:2222) is for debug access.
- The Alpine `.sha512` files are bare hashes; the script rewrites them into
  `sha512sum -c` format before verifying.
- `tiny-cloud` runs the seed script once per instance (first boot):
  it installs docker, formats the 50GB `/var/lib/docker` disk, mounts the 9p
  share at `/workspace`, enables dockerd on `tcp://0.0.0.0:2375` via
  `/etc/conf.d/docker`, and installs an `/etc/local.d/dind.start` fallback
  that starts dockerd manually in case the openrc `cgroups` dependency flakes
  (observed once: "cannot start docker as cgroups would not start").
- First boot takes a few minutes (apk fetch over slirp); the script waits up
  to 20 min for `docker info` to answer.
- The openrc boot log never reaches the serial console; if boot stalls, get
  in via ssh (2222) — or reboot the same overlay, tiny-cloud won't re-run
  but everything installed persists.
