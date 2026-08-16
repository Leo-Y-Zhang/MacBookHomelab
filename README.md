# MacBookHomelab

Turning an early-2015 MacBook Air (Linux Mint) into a small, modular, secure
home server. Every service is its own Docker Compose file, so any one can be
removed without touching the others. Nothing is exposed to the internet; remote
access is through Tailscale only.

> **Status: the server is built and running. This repository is behind it.**
> The machine was set up from this design, but the later stages were written and
> run on the machine itself and never committed back, so `stages/` here still
> holds only stage 1. **The running machine is the source of truth; this
> repository is the plan it was built from, not an inventory of what is
> installed.** Bringing the two back into step needs a session on the machine —
> nothing else can report what is actually there without guessing.

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
