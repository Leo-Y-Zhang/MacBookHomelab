# MacBookHomelab

Turning an early-2015 MacBook Air (Linux Mint) into a small, modular, secure
home server. The design gives every service its own Docker Compose file, so any
one can be removed without touching the others. Nothing is exposed to the
internet; remote access is through Tailscale only.

> **Status: the server is built and running. This repository is behind it.**
> The machine was set up from this design, but the later stages were written and
> run on the machine itself and never committed back, so `stages/` here holds
> only stage 1 and none of the Compose files described below are in this
> repository. **The running machine is the source of truth; this repository is
> the plan it was built from, not an inventory of what is installed.** Bringing
> the two back into step needs a session on the machine — nothing else can
> report what is actually there without guessing.

## Running and checking this repository

There is nothing to install and no application to start. This repository holds
the build plan and the stage scripts that carry it out. A stage script runs on
the server itself, one at a time, in the order below:

```sh
sh stages/stage1-base.sh
```

Requirements for running a stage: a Debian-family Linux with `apt-get`, and a
user who can `sudo`. Run it as that user, not with `sudo` in front: the script
asks for `sudo` itself where it needs it, and stage 1 refuses to run as root
because the `/srv` folders it creates must belong to you. No language runtime
and no build tooling are involved — the scripts are plain POSIX shell.

Away from the server, what a checkout can be checked for is what CI checks
(`.github/workflows/shellcheck.yml`): every stage script must declare a
`#!/bin/sh` shebang, parse under `sh -n`, and come back clean from shellcheck.
The last two of those are one command on any machine with a POSIX shell:

```sh
sh -c 'for f in stages/*.sh; do echo "sh -n $f"; sh -n "$f" || exit 1; done' && shellcheck stages/*.sh
```

`sh -n` parses without executing, so this is safe to run on a laptop. It takes
one file at a time, which is why this loops: `sh -n stages/*.sh` would parse
only the first script and silently pass over the rest. shellcheck is not in a
base install (`sudo apt-get install shellcheck`, or `brew install shellcheck`);
it is preinstalled on the GitHub runner CI uses. Dropping it still leaves the
parse loop, which is the check that catches the fault this repository has
actually had — an unterminated quote that stopped stage 1 parsing at all.

## The hardware this is designed around

| | |
|---|---|
| Model | MacBook Air 7,2 (early 2015, 13-inch) |
| CPU | Intel Core i5-5250U, 2 cores (Broadwell, has QuickSync) |
| RAM | **4 GB** — the constraint that shapes every choice below |
| Disk | 128 GB Apple SSD (~104 GB free), ext4, UEFI |
| Network | Wi-Fi only (Broadcom BCM4360); no built-in Ethernet |
| Battery | ~90% health — doubles as a small built-in UPS |

## What runs here, and what it costs

RAM budgets are rough resident use at idle.

| Service | Role | RAM | Storage | Notes |
|---|---|---|---|---|
| AdGuard Home | network-wide DNS + ad blocking | ~60 MB | `/srv/appdata/adguard` | serves DNS on the LAN |
| Tailscale | private remote access | ~30 MB | host package | the only way in from outside |
| Uptime Kuma | is-each-service-up monitoring | ~120 MB | `/srv/appdata/uptime-kuma` | notifies on outages |
| Glances | live CPU / RAM / disk / temps | ~80 MB | none | host metrics web UI |
| Samba | network file sharing | ~50 MB | `/srv/share` | SMB shares for the LAN |
| Jellyfin | home media server | ~150 MB idle | `/srv/media` + appdata | **direct-play only, no transcoding on 4 GB** |
| Immich | photo management | heavy | `/srv/photos` + appdata | **machine-learning OFF on 4 GB** (upload/albums/timeline still work) |
| restic | backups | runs on a timer | external USB | photos + configs, not re-downloadable media |

Comfortable always-on set: AdGuard + Tailscale + Uptime Kuma + Glances + Samba
(~350 MB). Jellyfin fits with direct-play. Immich is the stretch and is built
light; a swap file absorbs spikes.

## Directory layout (persistent storage)

```
/srv
  /appdata/<service>   # each container's config + database (small, gets backed up)
  /share               # Samba shares
  /media               # Jellyfin library (bulky; put on external USB when it grows)
  /photos              # Immich library (irreplaceable; always backed up)
  /backups             # restic repository target (ideally an external USB drive)
```

## The stages

Each stage explains what it installs, why, its resource use, how to test it, and
how to undo it. Nothing destructive runs without a warning; disks and existing
data are never touched.

1. **Base config** — updates, firewall (ufw), automatic security updates, a swap
   file, lm-sensors for temperatures, the `/srv` layout, and keeping the server
   running with the lid closed.
2. **SSH + security** — key-based login so the machine can be managed without the
   lid open.
3. **Docker + Compose** — the container runtime everything else sits on.
4. **Tailscale** — private remote access; no ports opened to the internet.
5. **AdGuard Home** — network DNS and ad blocking.
6. **Monitoring** — Uptime Kuma + Glances.
7. **Samba** — network file shares.
8. **Jellyfin** — media server (direct-play).
9. **Immich** — photos (ML off on 4 GB).
10. **Backups** — restic to external USB on a schedule.
11. **Documentation + maintenance** — how to update, restore, and remove cleanly.

## Safety rules baked in

- Read-only audits before any change; disks and partitions are never modified.
- Every container: `restart: unless-stopped` and a health check.
- Firewall default-deny inbound; only DNS (LAN), SSH, and Tailscale allowed.
- Secrets (Tailscale keys, Immich/DB passwords) are entered at runtime and never
  committed to this repository.
