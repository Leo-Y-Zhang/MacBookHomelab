# Session handoff

**State (2026-08-10):** Nothing has run on the Mac yet. Claude Code has just
been installed there (that is how you are reading this). Hardware audit is
done (facts in `README.md`); the design is decided.

**Exact next step:** Stage 1 — review `stages/stage1-base.sh`, explain it to
the operator in two sentences, run it yourself with `sh stages/stage1-base.sh`,
then verify: `sensors` shows a CPU temperature, `free -h` shows 4 GB swap,
`sudo ufw status verbose` shows default-deny with SSH + LAN DNS allowed, and
closing the lid does not suspend the machine. Then update this file, commit,
push, and continue to Stage 2.

## Stage checklist

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
