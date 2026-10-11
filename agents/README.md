# Agent Skills (shared)

One canonical store for Agent Skills (`<name>/SKILL.md`), read by every coding
agent on this machine. Tracked in git so skills propagate across machines.

## Layout

```
agents/
├── skills/            # canonical store: one dir per skill
│   ├── herdr/
│   │   └── SKILL.md
│   └── ...
├── sync-skills.sh     # adopt + fan-out script (run by install.sh)
└── README.md
```

`install.sh` links this package twice:

- `agents/` -> `~/.config/agents/` (Rule 1; Kimi's recommended generic path)
- `agents/` -> `~/.agents/` (skills-sh CLI global store)

`sync-skills.sh` then symlinks every canonical skill into each installed
agent's native dir (`~/.claude/skills`, `~/.codex/skills`, `~/.kimi/skills`,
`~/.omp/agent/skills`). Kimi also merges the `~/.claude/skills` brand dir
natively, so no Kimi config is needed.

## Workflow

Install a skill globally (lands in the store via `~/.agents`):

```bash
npx skills add <owner>/<repo> --skill <name> -g
./agents/sync-skills.sh
```

The sync adopts real dirs dropped by the CLI into the store, replaces
dangling/foreign-relative links (e.g. ones computed as if `~/.claude` were a
real dir), and links missing skills. Name collisions with differing content
are left alone with a warning. `./install.sh -p agents` runs the sync;
`./install.sh -u -p agents` removes the fan-out links.
