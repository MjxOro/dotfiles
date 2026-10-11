#!/usr/bin/env bash
#
# Sync canonical agent skills into every installed agent's native skills dir.
#
# Canonical store: <dotfiles>/agents/skills/<name>/SKILL.md  (tracked here)
# The skills-sh CLI global store (~/.agents/skills) resolves to the same
# directory via the ~/.agents symlink managed by install.sh, so
# `skills add <repo> --skill <name> -g` lands directly in this repo.
#
# Fan-out targets (linked only when the agent home exists):
#   ~/.claude/skills          Claude Code (brand dir, also read by Kimi)
#   ~/.codex/skills           Codex CLI
#   ~/.kimi/skills            Kimi Code CLI (brand dir)
#   ~/.omp/agent/skills       OMP / pi-coding-agent
# Kimi additionally reads ~/.config/agents/skills, which install.sh links
# to the store's parent (Rule 1: agents/ -> ~/.config/agents).
#
# Usage: sync-skills.sh [--unlink]
#   default : adopt real dirs into the store, (re)link everything
#   --unlink: remove fan-out links that point into the store (real dirs kept)
#
set -euo pipefail

MODE="link"
if [[ "${1:-}" == "--unlink" ]]; then MODE="unlink"; fi

STORE_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")/skills" >/dev/null 2>&1 && pwd)"
mkdir -p "$STORE_DIR"
REPO_ROOT="$(dirname -- "$(dirname -- "$STORE_DIR")")"

# Relative path from a directory to a target (both absolute), pure bash.
# Used so links inside the repo stay portable across checkouts.
relpath() {
  local target="$1" base="$2" common="$2" back=""
  while [[ "$target" != "$common" && "$target" != "$common/"* ]]; do
    common="$(dirname -- "$common")"
    back="../$back"
  done
  printf '%s%s' "$back" "${target#$common/}"
}

# Portable canonicalizer (mirrors lib/utils.sh resolve_path).
canonicalize() {
  local path="$1"
  if command -v realpath >/dev/null 2>&1; then
    realpath "$path" 2>/dev/null && return 0
  fi
  if command -v perl >/dev/null 2>&1; then
    perl -MCwd=realpath -e 'my $r = realpath(shift); exit 1 unless defined $r; print $r;' "$path" 2>/dev/null && return 0
  fi
  return 1
}

# Agent skills dirs whose parent home marker exists.
agent_dirs() {
  [[ -d "$HOME/.claude" ]] && printf '%s\n' "$HOME/.claude/skills"
  [[ -d "$HOME/.codex" ]] && printf '%s\n' "$HOME/.codex/skills"
  [[ -d "$HOME/.kimi-code" ]] && printf '%s\n' "$HOME/.kimi/skills"
  [[ -d "$HOME/.omp" ]] && printf '%s\n' "$HOME/.omp/agent/skills"
}
link_entry() {
  local store_entry="$1" agent_entry="$2" target="$1"
  if [[ "$agent_entry" == "$REPO_ROOT/"* ]]; then
    target="$(relpath "$store_entry" "$(dirname -- "$agent_entry")")"
  fi
  ln -sfn "$target" "$agent_entry"
  echo "  linked $(basename "$agent_entry") <- $target"
}

probe_file() {
  # $1 = skill path inside a skills dir (dir or .md); echoes the SKILL.md path.
  if [[ -d "$1" ]]; then printf '%s/SKILL.md' "$1"; else printf '%s' "$1"; fi
}

points_at_store() {
  # True when $1 (agent entry) resolves to $2 (store entry).
  local agent_entry="$1" store_entry="$2"
  [[ -L "$agent_entry" ]] || return 1
  local a s
  a=$(canonicalize "$(probe_file "$agent_entry")" 2>/dev/null || true)
  s=$(canonicalize "$(probe_file "$store_entry")" 2>/dev/null || true)
  [[ -n "$a" && "$a" == "$s" ]]
}


adopt_or_link() {
  local name="$1" agent_dir="$2"
  local store_entry="$STORE_DIR/$name" agent_entry="$agent_dir/$name"

  if [[ -e "$agent_entry" || -L "$agent_entry" ]]; then
    if points_at_store "$agent_entry" "$store_entry"; then
      return 0
    fi
    if [[ -L "$agent_entry" ]]; then
      if [[ ! -e "$agent_entry" ]]; then
        echo "  replacing dangling link $agent_entry"
        link_entry "$store_entry" "$agent_entry"
        return 0
      fi
      echo "  WARNING: $agent_entry is a foreign link; left alone"
      return 0
    fi
    # Real dir/file in the agent dir: adopt into the store.
    if [[ -e "$store_entry" ]]; then
      if diff -r -q "$agent_entry" "$store_entry" >/dev/null 2>&1; then
        rm -rf "$agent_entry"
        link_entry "$store_entry" "$agent_entry"
      else
        echo "  WARNING: $agent_entry differs from store copy; left alone"
      fi
      return 0
    fi
    mv "$agent_entry" "$store_entry"
    echo "  adopted $agent_entry into store"
    link_entry "$store_entry" "$agent_entry"
  fi

  if [[ -e "$store_entry" ]]; then
    link_entry "$store_entry" "$agent_entry"
  fi
}

unlink_entry() {
  local name="$1" agent_dir="$2"
  local agent_entry="$agent_dir/$name"
  if points_at_store "$agent_entry" "$STORE_DIR/$name"; then
    rm "$agent_entry"
    echo "  unlinked $agent_entry"
  fi
}

main() {
  local agent_dir
  while IFS= read -r agent_dir; do
    [[ -n "$agent_dir" ]] || continue
    if [[ "$MODE" == "link" ]]; then
      mkdir -p "$agent_dir"
      echo "syncing $agent_dir"
      local real_dir
      real_dir=$(canonicalize "$agent_dir" 2>/dev/null || printf '%s' "$agent_dir")
      agent_dir="$real_dir"
      while IFS= read -r -d '' entry; do
        name=$(basename "$entry")
        adopt_or_link "$name" "$agent_dir"
      done < <(find "$agent_dir" -mindepth 1 -maxdepth 1 \( -type d -o -type l -o -name '*.md' \) -print0 2>/dev/null)
      # Then link anything in the store that the agent lacks.
      while IFS= read -r -d '' entry; do
        name=$(basename "$entry")
        if [[ ! -e "$agent_dir/$name" && ! -L "$agent_dir/$name" ]]; then
          link_entry "$entry" "$agent_dir/$name"
        fi
      done < <(find "$STORE_DIR" -mindepth 1 -maxdepth 1 \( -type d -o -name '*.md' \) -print0 2>/dev/null)
    else
      [[ -d "$agent_dir" ]] || continue
      echo "unsyncing $agent_dir"
      local entry
      while IFS= read -r -d '' entry; do
        unlink_entry "$(basename "$entry")" "$agent_dir"
      done < <(find "$agent_dir" -mindepth 1 -maxdepth 1 \( -type d -o -name '*.md' -o -type l \) -print0 2>/dev/null)
    fi
  done < <(agent_dirs)
}

main
