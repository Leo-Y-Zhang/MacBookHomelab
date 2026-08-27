# Operating manual for the on-machine build agent

You are Claude Code running **on the homelab machine itself** — a MacBook Air
7,2 (early 2015) with Linux Mint and **4 GB of RAM**. Your job is to execute the
11-stage build described in `README.md`, in order, start to finish, doing all
the work yourself.

## How to run this build

- **Run every command yourself — never hand the operator a command to type.**
- Before each stage, explain in one or two plain sentences what is about to
  happen and why. After each stage, show the operator one visible result (a web
  page that now loads, a temperature reading, a share that appears on their
  other laptop).
- Warn before anything that triggers a login. Ask before anything destructive
  or hard to undo.

## Hard rules (settled decisions — do not relitigate)

- **Stage order is binding: 1 through 11**, as listed in `README.md`.
- The 4 GB design is settled: Jellyfin is **direct-play only** (no
  transcoding); Immich runs with **machine learning OFF**; a 4 GB swap file
  absorbs spikes.
- Nothing is ever exposed to the internet. Remote access is Tailscale only.
  ufw stays default-deny inbound.
- **Never touch disk partitions, formatting, or existing files.** The only
  acceptable formatting target is an external USB backup drive, and only after
  `lsblk` identification, showing the operator what is on it, and an explicit
  yes.
- Secrets (Tailscale keys, database passwords) are entered at runtime or kept
  in gitignored files. They never appear in a commit or in chat.
- Every container gets `restart: unless-stopped` and a health check; persistent
  data lives under `/srv` exactly as `README.md` lays out.
- A stage is done only when you have **tested the real thing**: resolve a
  domain through AdGuard, open each web UI, close the lid and confirm the
  machine stays up, reboot and confirm services come back on their own.

## Progress tracking (this is how the other session monitors you)

`SESSION_HANDOFF.md` holds the current state and exact next step. After every
completed stage: update it, commit, and push. A companion session on the
operator's Windows laptop watches this repository — pushed handoffs are the
only visibility it has.

## The only times you need the operator

1. **GitHub login** at session start (device flow in the browser) so you can
   push to this repository. It is public, so cloning needs no login; pushing
   does.
2. **Tailscale login** in the browser (Stage 4).
3. **The router's settings page** (Stage 5) to point LAN DNS at AdGuard and to
   give this machine a DHCP reservation. If the router is a struggle, fall
   back to per-device DNS settings and say so in the handoff.
4. **Plugging in the external USB drive** (Stage 10).

## Machine-specific cautions

- **Wi-Fi only** (Broadcom BCM4360 using the `wl` driver — kernel updates can
  break it; after any kernel upgrade, verify Wi-Fi before rebooting anything
  else). Make sure NetworkManager autoconnects on boot.
- Idles around 60 °C. Check `sensors` after each new service; sustained
  temperatures over 85 °C under normal load mean stop and reassess.
- Still unverified from the audit — check during Stage 1: whether Docker is
  already installed, what is currently listening (`ss -tulnp`), and the exact
  Mint version.
