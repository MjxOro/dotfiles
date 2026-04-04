---
name: install-pi-extension
description: Use when installing, removing, or managing pi-mono or OMP extensions/plugins from npm or GitHub into OMP, especially when the source may be GitHub-only, use legacy @mariozechner imports, or mix package-style plugins with loose extension and skill folders.
triggers:
  - install pi extension
  - install pi-mono
  - install from github
  - add extension
  - github.com
  - npmjs.com
  - pi install
  - omp plugin install
  - install-pi-extension
  - uninstall plugin
  - remove plugin
  - uninstall extension
  - remove extension
  - delete plugin
  - omp plugin uninstall
  - remove pi extension
  - uninstall pi extension
---

# Install Pi Extension Into OMP

## Overview

OMP is only partially compatible with the pi ecosystem.

The important split is:
- **Manifest compatibility:** OMP can read either `omp` or `pi` in `package.json`
- **Install-source compatibility:** core `omp plugin install` is primarily for **npm/package specs**, not arbitrary GitHub URLs

Do not promise a one-command GitHub install unless you have verified an actual installer path in the user's environment.

## Quick Decision

1. **npm package with `omp` or `pi` manifest**
   - Prefer: `omp plugin install <package>`
2. **GitHub repo with `package.json` and `pi`/`omp` manifest**
   - Usually install manually into `~/.omp/plugins` with Bun, then patch legacy imports if needed
3. **GitHub repo with loose `extensions/` and `skills/` folders**
   - Copy folders into `~/.omp/agent/extensions/` and `~/.omp/agent/skills/`, then patch legacy imports if needed
4. **Hybrid repo: package manifest plus loose `extensions/`/`skills/` folders**
   - Treat package install and manual copy as separate concerns: plugin-style install may work for the extension, but you may still need manual skill copying if OMP does not discover plugin-declared skills

## What To Check First

Before giving steps, inspect the repo for:
- `package.json`
- `omp` or `pi` manifest field
- `extensions`, `skills`, `tools`, `hooks`, `commands`
- legacy imports like `@mariozechner/pi-coding-agent` or `@mariozechner/pi-tui`

Use the repo shape to choose the install path. Do not guess.

## Pattern 1: npm Package

Use this when the extension is published to npm and has a valid `omp` or `pi` manifest.

```bash
omp plugin install some-package
omp plugin install @scope/some-package
```

After install:
- verify with `omp plugin list` or `omp plugin doctor`
- restart OMP if needed
- confirm the extension's command/tool appears

### Truthful caveat

This is the path core OMP supports best. Do not imply that the same command reliably accepts GitHub URLs.

## Pattern 2: GitHub Repo, Package-Style Plugin

Use this when the repo has a root `package.json` with `omp` or `pi`, for example:

```json
{
  "name": "pi-diff-review",
  "pi": {
    "extensions": ["./src/index.ts"]
  }
}
```

This is **not** the same as a loose file drop-in under `~/.omp/agent/extensions/`.

### Steps

1. Ensure the plugins workspace exists:

```bash
mkdir -p ~/.omp/plugins
```

2. Ensure `~/.omp/plugins/package.json` exists. Minimal example:

```json
{
  "name": "omp-plugins",
  "private": true,
  "dependencies": {}
}
```

3. Install the GitHub repo as a Bun dependency:

```bash
cd ~/.omp/plugins
bun add git+https://github.com/user/repo.git
```

4. If the repo uses legacy pi imports, patch them to OMP packages:

```bash
sed -i 's/@mariozechner\/pi-/@oh-my-pi\/pi-/g' path/to/file.ts
```

5. If Bun reports blocked native install scripts, trust the relevant packages and rerun install:

```bash
bun pm untrusted
bun pm trust <package-names>
bun install
```

6. Verify registration:

```bash
omp plugin list
omp plugin doctor
```

Then open OMP and verify the command/tool appears.

### Example: `pi-diff-review`

Verified pattern:
- package-style plugin
- no `skills/` directory
- GitHub-first, not a clean core `omp plugin install` case
- legacy imports from `@mariozechner/pi-*`

Concrete steps:

```bash
mkdir -p ~/.omp/plugins
cd ~/.omp/plugins
bun add git+https://github.com/badlogic/pi-diff-review.git
sed -i 's/@mariozechner\/pi-coding-agent/@oh-my-pi\/pi-coding-agent/g' \
  ~/.omp/plugins/node_modules/pi-diff-review/src/index.ts \
  ~/.omp/plugins/node_modules/pi-diff-review/src/git.ts
sed -i 's/@mariozechner\/pi-tui/@oh-my-pi\/pi-tui/g' \
  ~/.omp/plugins/node_modules/pi-diff-review/src/index.ts
```

Then:
- check `omp plugin list` or `omp plugin doctor`
- restart OMP
- run `/diff-review` inside a git repo

## Pattern 3: GitHub Repo, Loose Extension + Skills Folders

> Some repos are **hybrids**: they have a root `package.json` with `pi`/`omp` and also ship loose `extensions/` and `skills/` folders. In those cases, do not treat Pattern 2 and Pattern 3 as mutually exclusive. Package-style install may cover the extension, while manual skill copying is still the reliable fallback when OMP does not discover plugin-declared skills.

Use this when the repo is organized more like:
- `extensions/<name>/...`
- `skills/<skill-name>/SKILL.md`

> If the repo is hybrid and the user primarily needs the workflow skill to show up in OMP, prefer the manual skill-copy path unless you have verified plugin-declared skills load correctly in their version.

### Steps

1. Clone the repo:

```bash
git clone https://github.com/user/repo.git
```

2. Ensure OMP capability directories exist:

```bash
mkdir -p ~/.omp/agent/extensions ~/.omp/agent/skills
```

3. Copy the extension folder into OMP's extension directory:

```bash
cp -r repo/extensions/<extension-name> ~/.omp/agent/extensions/
```

4. Copy each skill directory into OMP's skills directory:

```bash
cp -r repo/skills/<skill-name> ~/.omp/agent/skills/
```

5. Patch legacy imports if the copied extension still references `@mariozechner/pi-*`:

```bash
sed -i 's/@mariozechner\/pi-/@oh-my-pi\/pi-/g' ~/.omp/agent/extensions/<extension-name>/index.ts
```

6. Restart or reload OMP and verify in-session with `/extensions`

### Example: `pi-autoresearch`

Verified pattern:
- separate `extensions/` and `skills/` directories
- extension needs legacy import patching
- manual copy workflow is the known OMP workaround

Concrete steps:

```bash
git clone https://github.com/davebcn87/pi-autoresearch.git
mkdir -p ~/.omp/agent/extensions ~/.omp/agent/skills
cp -r pi-autoresearch/extensions/pi-autoresearch ~/.omp/agent/extensions/
cp -r pi-autoresearch/skills/autoresearch-create ~/.omp/agent/skills/
cp -r pi-autoresearch/skills/autoresearch-finalize ~/.omp/agent/skills/
sed -i 's/@mariozechner\/pi-/@oh-my-pi\/pi-/g' ~/.omp/agent/extensions/pi-autoresearch/index.ts
```

Then:
- reload OMP
- verify with `/extensions`
- check the copied skills are discoverable

## Removing Plugins

Removal strategy mirrors the installation patterns. You must identify **where** the plugin is installed, not just its name.

### Quick Decision: Where Is It Installed?

1. **Check if OMP sees it as package-managed:**
   ```bash
   omp plugin list --json
   omp plugin doctor --json
   ```
   If the target appears under the `npm` array, it's Pattern 1 or 2.

2. **Check `~/.omp/plugins/package.json` to distinguish Pattern 1 vs 2:**
   ```bash
   grep -n '"<package-name>"' ~/.omp/plugins/package.json
   ```
   - Registry version like `"^1.2.0"` or `"13.14.2"` = Pattern 1
   - GitHub URL like `"https://github.com/user/repo"` = Pattern 2

3. **Check for manual Pattern 3 assets:**
   ```bash
   ls -1 ~/.omp/agent/extensions
   ls -1 ~/.omp/agent/skills
   ```
   If matching directories exist, Pattern 3 assets are present.

4. **Detect hybrid installs:**
   If the target exists in both `~/.omp/plugins` and `~/.omp/agent/extensions/` or `~/.omp/agent/skills/`, treat it as hybrid and remove both.

### Pattern 1 Removal — npm Package

Use the package name exactly as shown in `omp plugin list`:

```bash
omp plugin uninstall <package-name>
omp plugin uninstall @scope/some-package
```

This removes the package from `~/.omp/plugins` and cleans OMP runtime config.

### Pattern 2 Removal — GitHub Package-Style Plugin

**Preferred method** (cleans runtime config):
```bash
omp plugin uninstall <package-name>
```

Use the package name from the repo's `package.json`, not the GitHub URL.

**Fallback method** (mirrors install instructions):
```bash
cd ~/.omp/plugins
bun remove <package-name>
```

> **Warning:** Raw `bun remove` does not clean OMP runtime config. After using it, check for orphaned config:
> ```bash
> omp plugin doctor --json
> ```
> If you see `orphan:<package-name>`, the plugin config still exists. Clean it with:
> ```bash
> omp plugin doctor --fix
> ```

### Pattern 3 Removal — Manual Extension + Skills

Use a **move-first quarantine** strategy (safer than immediate delete):

```bash
# Create a quarantine directory with timestamp
STAMP="$(date +%Y%m%d-%H%M%S)"
BASE="$HOME/.omp/removed-plugins/<plugin-name>-$STAMP"
mkdir -p "$BASE/extensions" "$BASE/skills"

# Move extension if present
mv "$HOME/.omp/agent/extensions/<extension-dir>" "$BASE/extensions/"

# Move each skill if present
mv "$HOME/.omp/agent/skills/<skill-dir-1>" "$BASE/skills/"
mv "$HOME/.omp/agent/skills/<skill-dir-2>" "$BASE/skills/"
```

After verification (see below), optionally delete permanently:
```bash
rm -rf "$BASE"
```

### Hybrid Removal

Hybrid installs occupy both package-managed and manual locations. Remove both:

```bash
# Remove package-managed part
omp plugin uninstall <package-name>

# Remove manual extension + skills parts
STAMP="$(date +%Y%m%d-%H%M%S)"
BASE="$HOME/.omp/removed-plugins/<plugin-name>-$STAMP"
mkdir -p "$BASE/extensions" "$BASE/skills"
mv "$HOME/.omp/agent/extensions/<extension-dir>" "$BASE/extensions/"
mv "$HOME/.omp/agent/skills/<skill-dir-1>" "$BASE/skills/"
mv "$HOME/.omp/agent/skills/<skill-dir-2>" "$BASE/skills/"
```

### Example: Removing `pi-diff-review`

Pattern 2 removal (GitHub package-style):

```bash
omp plugin uninstall pi-diff-review
```

Or with Bun fallback:
```bash
cd ~/.omp/plugins
bun remove pi-diff-review
omp plugin doctor --json  # Check for orphaned config
```

### Example: Removing `pi-autoresearch` (Hybrid)

This plugin exists in both package-managed and manual locations:

```bash
# Remove package-managed part
omp plugin uninstall pi-autoresearch

# Remove manual parts (move-first quarantine)
STAMP="$(date +%Y%m%d-%H%M%S)"
BASE="$HOME/.omp/removed-plugins/pi-autoresearch-$STAMP"
mkdir -p "$BASE/extensions" "$BASE/skills"
mv "$HOME/.omp/agent/extensions/pi-autoresearch" "$BASE/extensions/"
mv "$HOME/.omp/agent/skills/autoresearch-create" "$BASE/skills/"
mv "$HOME/.omp/agent/skills/autoresearch-finalize" "$BASE/skills/"
```

### Verification After Removal

**Pattern 1 and 2 (package-managed):**
```bash
omp plugin list --json | grep <package-name>
omp plugin doctor --json | grep <package-name>
test ! -d "$HOME/.omp/plugins/node_modules/<package-name>" && echo "removed from node_modules"
```

**Pattern 2 with raw `bun remove` (check for orphans):**
```bash
omp plugin doctor --json | grep orphan:<package-name>
```

**Pattern 3 (manual):**
```bash
test ! -e "$HOME/.omp/agent/extensions/<extension-dir>" && echo "extension removed"
test ! -e "$HOME/.omp/agent/skills/<skill-dir-1>" && echo "skill-1 removed"
test ! -e "$HOME/.omp/agent/skills/<skill-dir-2>" && echo "skill-2 removed"
```

**Session-level confirmation (all patterns):**
Restart OMP and confirm the tool/command/extension no longer appears:
- For Pattern 1/2: check that `/command` no longer exists
- For Pattern 3: check that `/extensions` no longer lists the extension

### Safety Rules for Removal

1. **Never remove whole parent directories**
   - Wrong: `rm -rf ~/.omp/plugins` or `rm -rf ~/.omp/agent/extensions`
   - Right: Remove specific package or specific directories only

2. **Don't trust `omp plugin list` alone as the deletion target**
   - The list can include shared support packages flagged as `not an omp plugin`
   - Only remove what the user explicitly asked to remove

3. **Prefer `omp plugin uninstall` over raw `bun remove`**
   - It performs the same package removal plus cleans OMP runtime config

4. **Do not use `--dry-run` for uninstall**
   - The CLI parses it globally but uninstall does not implement it
   - Preview by inspecting with `list` and `doctor` instead

5. **Move-first for Pattern 3, verify, then optionally delete**
   - This preserves recovery if a skill or extension was shared or misidentified

6. **Always restart OMP before declaring completion**
   - Extensions and skills are discovery-time state
   - A stale session can make removal look incomplete or complete when it's not

### Edge Cases

**User doesn't remember how it was installed:**
1. Run `omp plugin list --json` and `omp plugin doctor --json`
2. Inspect `~/.omp/plugins/package.json` for the package entry
3. Inspect `~/.omp/agent/extensions/` and `~/.omp/agent/skills/` for matching directories
4. If both exist, remove both (hybrid case)

**Repo slug and package name differ:**
- Use the package name from `package.json` or `omp plugin list --json`
- Example: installed with `bun add git+https://github.com/badlogic/pi-diff-review.git`, removed as `pi-diff-review` (the package name), not the URL

**Hybrid repo with plugin manifest plus loose skills:**
- Treat package install and manual skill copy as separate removal surfaces
- Remove the package from `~/.omp/plugins` AND each copied skill/extension directory from `~/.omp/agent/*`

**Source clone outside OMP paths:**
- Do not delete clones in `~/projects/` or `/tmp/` by default
- Installed-state cleanup is complete once the package is gone from `~/.omp/plugins` and/or copied dirs are gone from `~/.omp/agent/*`
- Deleting a source clone is a separate user decision

## Known OMP Limits You Must Tell the User

- `omp plugin install` is best treated as **npm/package-spec based**, not a generic GitHub installer
- plugin-declared `skills` may not be discovered reliably in current OMP; manual skill copying can still be necessary
- older pi repos often need import patching from `@mariozechner/pi-*` to `@oh-my-pi/pi-*`
- a repo having a `pi` manifest means OMP can understand it **after installation**; it does **not** guarantee a one-command install source

## Common Mistakes

### Mistake: Treat every GitHub repo like an npm package
Wrong because OMP core install flow is not a general GitHub repo installer.

### Mistake: Treat every repo like a loose extension folder
Wrong because some repos are package-style plugins and belong under `~/.omp/plugins`, not `~/.omp/agent/extensions/`.

### Mistake: Say skills are available immediately
Wrong unless you have verified that OMP actually discovers them for that install path.

### Mistake: Skip verification
Always verify with the mechanism that matches the install path:
- package-style plugin: `omp plugin list` / `omp plugin doctor`
- loose extension + skills: `/extensions` inside OMP

### Mistake: Assume one removal command works for all
Wrong because removal is location-based. `omp plugin uninstall` only handles package-managed plugins (Patterns 1 and 2). It does not touch manual extensions/skills (Pattern 3).

### Mistake: Forget hybrid installs exist
Wrong because some repos are installed both ways. Check both locations before declaring success.

## Response Template

### For Installation Requests

When helping a user install, answer in this order:
1. state which repo pattern they have
2. explain why that changes the install path
3. give exact commands
4. call out any legacy import patching
5. give a concrete verification step

If the repo shape is still unknown, inspect it first. Do not invent a universal install command.

### For Removal/Uninstall Requests

When helping a user remove a plugin, answer in this order:
1. identify where the plugin is installed (run the quick decision flow)
2. state which removal pattern(s) apply (1, 2, 3, or hybrid)
3. give exact removal commands for each location
4. call out any orphaned config or manual assets
5. give concrete verification steps for each pattern
6. confirm with session restart

If the install location is unknown, run discovery commands first. Do not assume Pattern 1 removal will clean up everything.
