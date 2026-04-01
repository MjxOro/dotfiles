---
name: install-pi-extension
description: Install pi-mono extensions from GitHub or npm into OMP. Handles download, manifest detection, compatibility patching, and registration automatically.
triggers:
  - install pi extension
  - install pi-mono
  - install from github
  - add extension
  - "github.com"
  - "npmjs.com"
  - "pi install"
  - install-pi-extension
---

# Install Pi-Mono Extension

Install any pi-mono extension into OMP with one command.

## Quick Usage

**Command line:**
```bash
install-pi-extension https://github.com/davebcn87/pi-autoresearch
install-pi-extension pi-multi-pass
install-pi-extension @oh-my-pi/swarm-extension
```

**Or tell me:**
```
Install https://github.com/user/repo
```

## What It Does

1. **Downloads** the extension to `~/.omp/plugins/node_modules/`
2. **Detects** if it's a pi-mono extension (looks for `pi` field in package.json)
3. **Installs dependencies** with bun
4. **Patches** imports from `@mariozechner/pi-*` to `@oh-my-pi/pi-*`
5. **Verifies** the extension is properly registered
6. **Reports** what commands/skills are now available

## Supported Sources

- GitHub repos: `https://github.com/user/repo` or `git:github.com/user/repo`
- npm packages: `pi-multi-pass`, `@oh-my-pi/swarm-extension`
- Direct URLs: Any git or npm installable URL

## Example Extensions

| Extension | Install Command |
|-----------|----------------|
| pi-autoresearch | `install-pi-extension https://github.com/davebcn87/pi-autoresearch` |
| pi-multi-pass | `install-pi-extension pi-multi-pass` |
| pi-design-deck | `install-pi-extension pi-design-deck` |
| @oh-my-pi/swarm-extension | `install-pi-extension @oh-my-pi/swarm-extension` |

## Post-Install

After installation:
- Extension appears in `omp plugin list`
- Skills are available immediately (use `/skill:NAME`)
- Commands show in help
- Some extensions add UI widgets

## Troubleshooting

If install fails:
1. Check if the repo has a `package.json` with `pi` field
2. Verify it's actually a pi-mono extension (not just a regular npm package)
3. Check `omp plugin doctor` for errors
4. Look at `~/.omp/plugins/node_modules/REPO_NAME/package.json`

## Manual Fix

If automatic patching fails:
```bash
cd ~/.omp/plugins
node ./scripts/fix-installed-plugins.mjs
```

## Legacy Usage

**From GitHub:**
```
Install https://github.com/davebcn87/pi-autoresearch
```

**From npm:**
```
Install pi-multi-pass from npm
```

**Or directly:**
```
Use install_pi_extension tool with source "https://github.com/user/repo"
```
