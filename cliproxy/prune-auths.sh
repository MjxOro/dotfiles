#!/usr/bin/env bash

set -euo pipefail

runtime_dir="${CLIPROXY_HOME:-$HOME/.cliproxy}"
auth_dir="${CLIPROXY_AUTH_DIR:-$runtime_dir/auths}"
dry_run=0
mode="safe"

while (($#)); do
  case "$1" in
    --dry-run)
      dry_run=1
      ;;
    --force-expired)
      mode="force-expired"
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      printf 'Usage: %s [--dry-run] [--force-expired]\n' "${0##*/}" >&2
      exit 1
      ;;
  esac
  shift
done

python3 - "$auth_dir" "$mode" "$dry_run" <<'PY'
from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
import json
import sys


def parse_timestamp(raw: object) -> datetime | None:
    if not isinstance(raw, str) or not raw.strip():
        return None

    try:
        value = raw.replace("Z", "+00:00")
        parsed = datetime.fromisoformat(value)
    except ValueError:
        return None

    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def get_refresh_token(payload: object) -> str:
    if isinstance(payload, dict):
        refresh_token = payload.get("refresh_token")
        if isinstance(refresh_token, str):
            return refresh_token.strip()

        tokens = payload.get("tokens")
        if isinstance(tokens, dict):
            nested = tokens.get("refresh_token")
            if isinstance(nested, str):
                return nested.strip()

    return ""


def remove_file(path: Path, reason: str, dry_run: bool) -> None:
    action = "Would remove" if dry_run else "Removed"
    print(f"{action} {path.name}: {reason}")
    if not dry_run:
        path.unlink(missing_ok=True)


auth_dir = Path(sys.argv[1]).expanduser()
mode = sys.argv[2]
dry_run = sys.argv[3] == "1"

if not auth_dir.exists():
    raise SystemExit(0)

now = datetime.now(timezone.utc)
checked = 0
removed = 0

for path in sorted(auth_dir.glob("*.json")):
    checked += 1
    try:
        payload = json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        removed += 1
        remove_file(path, f"invalid JSON ({exc.msg})", dry_run)
        continue

    expired_at = parse_timestamp(payload.get("expired"))
    if expired_at is None or expired_at > now:
        continue

    refresh_token = get_refresh_token(payload)
    if mode != "force-expired" and refresh_token:
        continue

    reason = "expired auth file" if mode == "force-expired" else "expired auth file without refresh token"
    removed += 1
    remove_file(path, reason, dry_run)

if checked and removed == 0:
    print(f"Auth cleanup: checked {checked} file(s), nothing to remove.")
elif checked:
    print(f"Auth cleanup: checked {checked} file(s), {'would remove' if dry_run else 'removed'} {removed}.")
PY
