# Session handoff

**State (2026-08-16):** The server is built and running. It was set up from
this plan on the machine itself, and none of that work was committed back — so
everything below still describes the starting position and the stage table
still reads "not started". **It is out of date, not accurate.**

The previous text said "Nothing has run on the Mac yet". That was true when it
was written on 2026-08-10 and has been false ever since, and a session reading
this repository from another machine concluded from it that the homelab had
never been started. A handoff file nobody updates is worse than no handoff
file: it does not go quiet, it keeps confidently asserting the last thing
somebody wrote.

**Exact next step, for a session running ON the machine:** record what is
actually there, before anything else. Nothing can be trusted in this file until
that is done.

1. Inventory the real state: `docker ps --format '{{.Names}}\t{{.Image}}'`,
   `systemctl list-units --type=service --state=running`, `sudo ufw status verbose`,
   `free -h`, `df -h /`, `tailscale status`.
2. Write the stage scripts that exist on the machine into `stages/`, and mark
   the table below from what the inventory shows rather than from memory.
3. Commit and push. **That push is the only thing that makes any of this visible
   from anywhere else.**

Only then continue with whatever is genuinely unfinished.

## Stage checklist

⚠ **Every row below is the 10 August starting position, not the current state.**
The machine is running; these have not been updated since. Do not read a "not
started" here as meaning a stage was not done — check the machine.

| Stage | Status |
|---|---|
| 1 Base config | not started |
| 2 SSH + security | not started |
| 3 Docker + Compose | not started |
| 4 Tailscale | not started |
| 5 AdGuard Home | not started |
| 6 Monitoring (Uptime Kuma + Glances) | not started |
| 7 Samba | not started |
| 8 Jellyfin (direct-play) | not started |
| 9 Immich (ML off) | not started |
| 10 Backups (restic + USB) | not started |
| 11 Docs + maintenance | not started |

## Log

- 2026-08-10 — Repo prepared from the Windows session: agent manual
  (`CLAUDE.md`) and this handoff added. Build not yet started on the Mac.
- 2026-08-16 — Corrected from a Windows session. The homelab is running; this
  file and the README were still describing the plan. No stage scripts were
  written from Windows: guessing at a working configuration from another machine
  would be worse than leaving the gap visible.
