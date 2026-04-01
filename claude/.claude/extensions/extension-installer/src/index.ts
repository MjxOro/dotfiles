import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { execSync } from "child_process";
import { existsSync, readFileSync, mkdirSync, cpSync, rmSync } from "fs";
import { join, basename } from "path";
import { homedir } from "os";

interface InstallResult {
  success: boolean;
  message: string;
  path?: string;
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("extension:install", {
    description: "Install an extension from a git URL or npm package",
    usage: "/extension:install <git-url-or-npm-package>",
    handler: async (args: string[]) => {
      const source = args[0];
      
      if (!source) {
        pi.notify("Usage: /extension:install <git-url-or-npm-package>", "error");
        return { success: false, message: "No source provided" };
      }

      pi.notify(`Installing extension from ${source}...`, "info");

      try {
        const result = await installExtension(source, pi);
        
        if (result.success) {
          pi.notify(result.message, "success");
          // Trigger extension reload
          pi.notify("Extension installed. Run /reload to load the new extension.", "info");
        } else {
          pi.notify(result.message, "error");
        }
        
        return result;
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        pi.notify(`Installation failed: ${message}`, "error");
        return { success: false, message };
      }
    },
  });

  pi.registerCommand("extension:list", {
    description: "List installed extensions",
    usage: "/extension:list",
    handler: async () => {
      const extensions = listExtensions();
      
      // Group extensions by type
      const agentExts = extensions.filter(e => e.type === "agent-extension");
      const ompPlugins = extensions.filter(e => e.type === "omp-plugin");
      const claudePlugins = extensions.filter(e => e.type === "claude-plugin");
      
      let output = "Installed Extensions & Plugins:\n";
      
      if (agentExts.length > 0) {
        output += "\n📦 Agent Extensions (can manage):\n";
        output += agentExts.map(ext => `  • ${ext.name}${ext.version ? ` v${ext.version}` : ''}`).join("\n");
      }
      
      if (ompPlugins.length > 0) {
        output += "\n\n🔌 OMP Plugins (read-only):\n";
        output += ompPlugins.map(ext => `  • ${ext.name}${ext.version ? ` v${ext.version}` : ''}`).join("\n");
      }
      
      if (claudePlugins.length > 0) {
        output += "\n\n🎨 Claude Marketplace Plugins (read-only):\n";
        output += claudePlugins.map(ext => `  • ${ext.name}${ext.version ? ` v${ext.version}` : ''}`).join("\n");
      }
      
      if (extensions.length === 0) {
        output += "\n  No extensions or plugins installed.";
      }
      
      output += "\n\nUse /extension:remove <name> to remove agent extensions.";
      
      pi.notify(output, "info");
      
      return { success: true, message: `Found ${extensions.length} items`, extensions };
    },
  });

  pi.registerCommand("extension:remove", {
    description: "Remove an installed extension",
    usage: "/extension:remove <extension-name>",
    handler: async (args: string[]) => {
      const name = args[0];
      
      if (!name) {
        pi.notify("Usage: /extension:remove <extension-name>", "error");
        return { success: false, message: "No extension name provided" };
      }

      const result = await removeExtension(name, pi);
      
      if (result.success) {
        pi.notify(result.message, "success");
      } else {
        pi.notify(result.message, "error");
      }
      
      return result;
    },
  });
}

async function installExtension(source: string, pi: ExtensionAPI): Promise<InstallResult> {
  const tempDir = join(getTempDir(), `omp-extension-${Date.now()}`);
  const isGitUrl = source.includes("://") || source.startsWith("git@") || source.endsWith(".git");
  
  try {
    // Create temp directory
    mkdirSync(tempDir, { recursive: true });

    if (isGitUrl) {
      // Clone git repository
      pi.notify("Cloning git repository...", "info");
      execSync(`git clone --depth 1 "${source}" "${tempDir}/repo"`, {
        stdio: ["pipe", "pipe", "pipe"],
        timeout: 60000,
      });
      
      const repoDir = join(tempDir, "repo");
      return await installFromDirectory(repoDir, source, pi);
    } else {
      // Install from npm
      pi.notify("Installing from npm...", "info");
      execSync(`npm pack "${source}" --pack-destination "${tempDir}"`, {
        stdio: ["pipe", "pipe", "pipe"],
        timeout: 120000,
      });
      
      // Extract the tarball
      const files = execSync(`ls "${tempDir}"`, { encoding: "utf-8" }).trim().split("\n");
      const tarball = files.find(f => f.endsWith(".tgz"));
      
      if (!tarball) {
        throw new Error("Failed to download npm package");
      }
      
      execSync(`tar -xzf "${tempDir}/${tarball}" -C "${tempDir}"`, {
        stdio: ["pipe", "pipe", "pipe"],
      });
      
      const packageDir = join(tempDir, "package");
      return await installFromDirectory(packageDir, source, pi);
    }
  } finally {
    // Cleanup temp directory
    try {
      rmSync(tempDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }
  }
}

async function installFromDirectory(sourceDir: string, originalSource: string, pi: ExtensionAPI): Promise<InstallResult> {
  const packageJsonPath = join(sourceDir, "package.json");
  
  if (!existsSync(packageJsonPath)) {
    throw new Error("No package.json found in extension");
  }

  const packageJson = JSON.parse(readFileSync(packageJsonPath, "utf-8"));
  
  // Check for omp or pi manifest
  const manifest = packageJson.omp || packageJson.pi;
  
  if (!manifest) {
    throw new Error("Extension missing 'omp' or 'pi' field in package.json");
  }

  const extensionName = manifest.name || packageJson.name || basename(originalSource);
  const safeName = extensionName.replace(/[^a-zA-Z0-9_-]/g, "_");
  
  // Determine install location
  const installDir = join(getOmpExtensionsDir(), safeName);
  
  // Check if already exists
  if (existsSync(installDir)) {
    const confirmed = await pi.confirm(`Extension "${extensionName}" already exists. Overwrite?`);
    if (!confirmed) {
      return { success: false, message: "Installation cancelled" };
    }
    rmSync(installDir, { recursive: true, force: true });
  }

  // Copy extension files
  mkdirSync(installDir, { recursive: true });
  cpSync(sourceDir, installDir, { recursive: true });

  // Validate extensions entry point exists
  const extensions = manifest.extensions || [];
  for (const ext of extensions) {
    const extPath = join(installDir, ext);
    if (!existsSync(extPath)) {
      throw new Error(`Extension entry point not found: ${ext}`);
    }
  }

  return {
    success: true,
    message: `Extension "${extensionName}" installed successfully`,
    path: installDir,
  };
}

interface ExtensionInfo {
  name: string;
  source: string;
  path: string;
  type: "agent-extension" | "omp-plugin" | "claude-plugin";
  version?: string;
}

function listExtensions(): ExtensionInfo[] {
  const extensions: ExtensionInfo[] = [];
  
  // 1. Agent Extensions (from ~/.omp/agent/extensions/)
  const extensionsDir = getOmpExtensionsDir();
  if (existsSync(extensionsDir)) {
    try {
      const entries = execSync(`ls -1 "${extensionsDir}" 2>/dev/null || echo ""`, { encoding: "utf-8" }).trim().split("\n").filter(Boolean);
      
      for (const entry of entries) {
        const extPath = join(extensionsDir, entry);
        const packageJsonPath = join(extPath, "package.json");
        
        if (existsSync(packageJsonPath)) {
          try {
            const packageJson = JSON.parse(readFileSync(packageJsonPath, "utf-8"));
            const manifest = packageJson.omp || packageJson.pi;
            const name = manifest?.name || packageJson.name || entry;
            const source = packageJson.repository?.url || packageJson.name || "local";
            
            extensions.push({ 
              name, 
              source: typeof source === 'string' ? source : JSON.stringify(source), 
              path: extPath,
              type: "agent-extension",
              version: packageJson.version
            });
          } catch {
            // Skip invalid package.json
          }
        }
      }
    } catch {
      // Directory read error
    }
  }
  
  // 2. OMP Plugins (from ~/.omp/plugins/)
  const ompPluginsDir = join(homedir(), ".omp", "plugins");
  const ompPackageJson = join(ompPluginsDir, "package.json");
  if (existsSync(ompPackageJson)) {
    try {
      const packageJson = JSON.parse(readFileSync(ompPackageJson, "utf-8"));
      const deps = { ...packageJson.dependencies, ...packageJson.devDependencies };
      
      for (const [name, version] of Object.entries(deps)) {
        if (typeof version === 'string' && (name.includes("pi-") || name.includes("@oh-my-pi/") || name.includes("omp-"))) {
          extensions.push({
            name,
            source: `npm:${name}@${version}`,
            path: join(ompPluginsDir, "node_modules", name),
            type: "omp-plugin",
            version: version.replace(/[^0-9.]/g, "")
          });
        }
      }
    } catch {
      // Read error
    }
  }
  
  // 3. Claude Plugins (from ~/.claude/plugins/)
  const claudePluginsJson = join(homedir(), ".claude", "plugins", "installed_plugins.json");
  if (existsSync(claudePluginsJson)) {
    try {
      const installed = JSON.parse(readFileSync(claudePluginsJson, "utf-8"));
      if (installed.plugins) {
        for (const [pluginId, installs] of Object.entries(installed.plugins)) {
          if (Array.isArray(installs) && installs.length > 0) {
            const latest = installs[installs.length - 1];
            const [name, publisher] = pluginId.split("@");
            extensions.push({
              name: `${name}@${publisher}`,
              source: latest.installPath || pluginId,
              path: latest.installPath || "unknown",
              type: "claude-plugin",
              version: latest.version
            });
          }
        }
      }
    } catch {
      // Read error
    }
  }
  
  return extensions;
}

async function removeExtension(name: string, pi: ExtensionAPI): Promise<InstallResult> {
  const extensionsDir = getOmpExtensionsDir();
  const extPath = join(extensionsDir, name);
  
  if (!existsSync(extPath)) {
    return { success: false, message: `Extension "${name}" not found` };
  }

  const confirmed = await pi.confirm(`Are you sure you want to remove "${name}"?`);
  if (!confirmed) {
    return { success: false, message: "Removal cancelled" };
  }

  rmSync(extPath, { recursive: true, force: true });
  
  return {
    success: true,
    message: `Extension "${name}" removed successfully`,
  };
  pi.registerCommand("extension:update", {
    description: "Update an installed extension to latest version",
    usage: "/extension:update <extension-name>",
    handler: async (args: string[]) => {
      const name = args[0];
      
      if (!name) {
        pi.notify("Usage: /extension:update <extension-name>", "error");
        return { success: false, message: "No extension name provided" };
      }

      pi.notify(`Checking for updates to "${name}"...`, "info");

      const result = await updateExtension(name, pi);
      
      if (result.success) {
        pi.notify(result.message, "success");
        if (result.updated) {
          pi.notify("Extension updated. Run /reload to load the new version.", "info");
        }
      } else {
        pi.notify(result.message, "error");
      }
      
      return result;
    },
  });
  pi.registerCommand("extension:info", {
    description: "Show details about an installed extension",
    usage: "/extension:info <extension-name>",
    handler: async (args: string[]) => {
      const name = args[0];
      
      if (!name) {
        pi.notify("Usage: /extension:info <extension-name>", "error");
        return { success: false, message: "No extension name provided" };
      }

      const info = await getExtensionInfo(name);
      
      if (!info) {
        pi.notify(`Extension "${name}" not found`, "error");
        return { success: false, message: `Extension "${name}" not found` };
      }

      const details = [
        `Name: ${info.name}`,
        `Version: ${info.version}`,
        `Description: ${info.description || "N/A"}`,
        `Source: ${info.source}`,
        `Location: ${info.path}`,
        `Type: ${info.type}`,
        `Manifest: ${info.hasOmpManifest ? "OMP" : info.hasPiManifest ? "pi-mono" : "none"}`,
        `Entry Points: ${info.entryPoints.join(", ") || "N/A"}`,
      ].join("\n");

      pi.notify(`Extension Details:\n${details}`, "info");
      
      return { success: true, message: "Extension info displayed", info };
    },
  });
}

async function updateExtension(name: string, pi: ExtensionAPI): Promise<InstallResult & { updated?: boolean }> {
  const extensionsDir = getOmpExtensionsDir();
  const extPath = join(extensionsDir, name);
  
  if (!existsSync(extPath)) {
    return { success: false, message: `Extension "${name}" not found` };
  }

  const packageJsonPath = join(extPath, "package.json");
  if (!existsSync(packageJsonPath)) {
    return { success: false, message: `Extension "${name}" has no package.json` };
  }

  const packageJson = JSON.parse(readFileSync(packageJsonPath, "utf-8"));
  
  // Get source from various possible fields
  const source = packageJson.repository?.url || 
                 packageJson.repository || 
                 packageJson.homepage ||
                 packageJson.name;
                 
  if (!source) {
    return { success: false, message: `Cannot determine source for "${name}". No repository URL or package name found.` };
  }

  const isGitUrl = typeof source === 'string' && (
    source.includes("://") || 
    source.startsWith("git@") || 
    source.endsWith(".git")
  );

  if (!isGitUrl) {
    return { success: false, message: `Extension "${name}" was installed from npm. Use /extension:remove and /extension:install to update npm packages.` };
  }

  // Check for local modifications
  const gitDir = join(extPath, ".git");
  if (existsSync(gitDir)) {
    try {
      const status = execSync("git status --porcelain", { 
        cwd: extPath, 
        encoding: "utf-8",
        timeout: 10000 
      });
      if (status.trim()) {
        const confirmed = await pi.confirm(`Extension "${name}" has local changes. These will be lost. Continue?`);
        if (!confirmed) {
          return { success: false, message: "Update cancelled" };
        }
      }
    } catch {
      // Ignore git errors, proceed with reinstall
    }
  }

  // Reinstall from source
  pi.notify(`Updating from ${source}...`, "info");
  
  // Backup current version
  const backupDir = join(getTempDir(), `omp-extension-backup-${name}-${Date.now()}`);
  try {
    mkdirSync(backupDir, { recursive: true });
    cpSync(extPath, backupDir, { recursive: true });
  } catch {
    // Ignore backup errors
  }

  try {
    // Remove old version
    rmSync(extPath, { recursive: true, force: true });
    
    // Install new version
    const result = await installExtension(source, pi);
    
    if (result.success) {
      return { 
        success: true, 
        message: `Extension "${name}" updated successfully`,
        updated: true,
        path: result.path 
      };
    } else {
      // Restore backup on failure
      try {
        mkdirSync(extPath, { recursive: true });
        cpSync(backupDir, extPath, { recursive: true });
        pi.notify("Restored previous version from backup", "info");
      } catch {
        // Ignore restore errors
      }
      return result;
    }
  } finally {
    // Cleanup backup
    try {
      rmSync(backupDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }
  }
}
async function getExtensionInfo(name: string): Promise<{
  name: string;
  version: string;
  description?: string;
  source: string;
  path: string;
  type: "git" | "npm" | "local" | "unknown";
  hasOmpManifest: boolean;
  hasPiManifest: boolean;
  entryPoints: string[];
} | null> {
  const extensionsDir = getOmpExtensionsDir();
  const extPath = join(extensionsDir, name);
  
  if (!existsSync(extPath)) {
    return null;
  }

  const packageJsonPath = join(extPath, "package.json");
  if (!existsSync(packageJsonPath)) {
    return null;
  }

  try {
    const packageJson = JSON.parse(readFileSync(packageJsonPath, "utf-8"));
    const manifest = packageJson.omp || packageJson.pi;
    
    const source = packageJson.repository?.url || 
                   packageJson.repository || 
                   packageJson.homepage ||
                   packageJson.name ||
                   "unknown";
    
    const isGitUrl = typeof source === 'string' && (
      source.includes("://") || 
      source.startsWith("git@") || 
      source.endsWith(".git")
    );
    
    const gitDir = join(extPath, ".git");
    const type: "git" | "npm" | "local" | "unknown" = existsSync(gitDir) 
      ? "git" 
      : isGitUrl 
        ? "git" 
        : packageJson.name 
          ? "npm" 
          : "local";

    const entryPoints = manifest?.extensions || [];

    return {
      name: manifest?.name || packageJson.name || name,
      version: packageJson.version || "unknown",
      description: manifest?.description || packageJson.description,
      source: typeof source === 'string' ? source : JSON.stringify(source),
      path: extPath,
      type,
      hasOmpManifest: !!packageJson.omp,
      hasPiManifest: !!packageJson.pi,
      entryPoints,
    };
  } catch {
    return null;
  }
}
function getOmpExtensionsDir(): string {
  return join(homedir(), ".omp", "agent", "extensions");
}

function getTempDir(): string {
  return process.env.TMPDIR || process.env.TEMP || process.env.TMP || "/tmp";
}