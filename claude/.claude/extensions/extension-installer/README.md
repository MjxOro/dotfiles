# Extension Installer for OMP

Install OMP/pi-mono extensions from git repositories or npm packages using slash commands.

## Installation

This extension is already installed at `~/.omp/agent/extensions/extension-installer/`. Run `/reload` to load it.

## Commands

| Command | Description |
|---------|-------------|
| `/extension:install <source>` | Install from git URL or npm package |
| `/extension:list` | Show all installed extensions |
| `/extension:remove <name>` | Remove an extension |
| `/extension:update <name>` | Update a git-based extension |
| `/extension:info <name>` | Show extension details |

### `/extension:install <source>`

Install an extension from a git URL or npm package name.

**Examples:**
```
/extension:install https://github.com/user/my-extension.git
/extension:install git@github.com:user/my-extension.git
/extension:install my-npm-package
/extension:install @scope/package-name
```

**Features:**
- Auto-detects git vs npm sources
- Validates `package.json` has `omp` or `pi` manifest field
- Installs to `~/.omp/agent/extensions/`
- Shows progress notifications
- Supports reinstall with confirmation

### `/extension:list`

List all installed extensions and plugins across all three systems (Agent Extensions, OMP Plugins, Claude Marketplace).

**Example:**
```
/extension:list
```

**Output:**
```
Installed Extensions & Plugins:

📦 Agent Extensions (can manage):
  • Extension Installer v1.0.0
  • My Custom Tool v0.5.2

🔌 OMP Plugins (read-only):
  • @oh-my-pi/pi-coding-agent v13.17.0
  • pi-multi-pass v1.2.0

🎨 Claude Marketplace Plugins (read-only):
  • superpowers@superpowers-marketplace v5.0.6
  • frontend-design@claude-plugins-official v1.0.0
  • context7@claude-plugins-official v1.0.0

Use /extension:remove <name> to remove agent extensions.
```

**Note:** Only Agent Extensions (in `~/.omp/agent/extensions/`) can be managed (installed/removed/updated) by this tool. OMP Plugins and Claude Marketplace plugins are shown for reference but must be managed through their respective systems (npm/pi-cli for OMP, marketplace UI for Claude).

### `/extension:remove <name>`

Remove an installed extension by name.

**Example:**
```
/extension:remove my-extension
```

**Safety:** Requires confirmation before deletion.

### `/extension:update <name>`

Update a git-based extension to the latest version from its source repository.

**Example:**
```
/extension:update my-extension
```

**Features:**
- Detects if extension was installed from git or npm (npm updates require reinstall)
- Checks for local modifications and warns before overwriting
- Creates backup before updating (restores on failure)
- Shows progress notifications

**Notes:**
- Git extensions: Fetches latest from repository
- NPM extensions: Shows message to use remove + reinstall instead

### `/extension:info <name>`

Show detailed information about an installed extension.

**Example:**
```
/extension:info extension-installer
```

**Output:**
```
Extension Details:
Name: Extension Installer
Version: 1.0.0
Description: Install extensions from git or npm into OMP
Source: https://github.com/user/extension-installer
Location: ~/.omp/agent/extensions/extension-installer
Type: git
Manifest: OMP
Entry Points: ./src/index.ts
```
## Extension Compatibility

### Works With:
- **OMP extensions** with `package.json` `omp` field
- **pi-mono extensions** with `package.json` `pi` field
- Git repositories (HTTPS, SSH, or local paths ending in `.git`)
- NPM packages (scoped or unscoped)

### Required Manifest Format:

```json
{
  "name": "my-extension",
  "version": "1.0.0",
  "omp": {
    "name": "My Extension",
    "description": "What it does",
    "extensions": ["./src/index.ts"],
    "tools": "./src/tools/index.ts",
    "skills": ["./skills"],
    "commands": ["./commands"]
  }
}
```

Or legacy pi-mono format:

```json
{
  "name": "my-extension",
  "pi": {
    "extensions": ["./src/index.ts"]
  }
}
```

## Installation Locations

Extensions are installed to:
- **Primary**: `~/.omp/agent/extensions/<name>/`
- **Legacy**: `~/.pi/agent/extensions/<name>/` (backward compatible)

After installation, run `/reload` to load the new extension.

## Troubleshooting

**"No package.json found"**
- The source doesn't have a valid package.json at root

**"Extension missing 'omp' or 'pi' field"**
- Add `omp` or `pi` field to package.json per format above

**"Extension entry point not found"**
- The `extensions` array in manifest points to non-existent files

**Git clone timeout**
- Large repos may need shallow clone; the tool uses `--depth 1`

**NPM package not found**
- Check the package name is correct and published to registry

## Development

Source location: `/home/cat/dotfiles/claude/.claude/extensions/extension-installer/`

To modify:
1. Edit files in `src/`
2. Run `/reload` to reload the extension
3. Test commands

## Technical Details

- Uses OMP's ExtensionAPI for slash commands
- Supports both git and npm sources
- Validates manifest before installation
- Atomic installation (cleans up temp files)
- Confirmation prompts for destructive actions
