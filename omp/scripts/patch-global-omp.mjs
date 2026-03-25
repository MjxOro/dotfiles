#!/usr/bin/env bun

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

const scriptsDir = import.meta.dir;
const bundledCodingAgentDir = path.join(scriptsDir, '..', 'plugins', 'node_modules', '@oh-my-pi', 'pi-coding-agent');

function lines(parts) {
  return `${parts.join("\n")}\n`;
}

function readText(filePath) {
  return fs.readFileSync(filePath, "utf8");
}

function backupOriginal(filePath, current) {
  const backupPath = `${filePath}.dotfiles-orig`;
  if (!fs.existsSync(backupPath)) {
    fs.writeFileSync(backupPath, current);
  }
}

function writeIfChanged(filePath, current, next) {
  if (current === next) return false;
  backupOriginal(filePath, current);
  fs.writeFileSync(filePath, next);
  return true;
}

function replaceOnce(source, before, after, label) {
  if (source.includes(after)) return source;
  if (!source.includes(before)) {
    throw new Error(`Unable to find ${label}`);
  }
  return source.replace(before, after);
}

function prependBefore(source, marker, addition, label) {
  if (source.includes(addition)) return source;
  const index = source.indexOf(marker);
  if (index < 0) {
    throw new Error(`Unable to find ${label}`);
  }
  return `${source.slice(0, index)}${addition}${source.slice(index)}`;
}

function replaceBetween(source, startMarker, endMarker, replacement, label) {
  if (source.includes(replacement)) return source;
  const startIndex = source.indexOf(startMarker);
  if (startIndex < 0) {
    throw new Error(`Unable to find ${label} start`);
  }
  const endIndex = source.indexOf(endMarker, startIndex);
  if (endIndex < 0) {
    throw new Error(`Unable to find ${label} end`);
  }
  return `${source.slice(0, startIndex)}${replacement}${source.slice(endIndex)}`;
}

function resolvePackageRootFromCli(cliPath) {
  if (!cliPath.endsWith(`${path.sep}src${path.sep}cli.ts`)) return null;
  return path.dirname(path.dirname(cliPath));
}

function findActivePackageRoot() {
  const candidates = new Set([
    path.join(os.homedir(), ".bun", "install", "global", "node_modules", "@oh-my-pi", "pi-coding-agent"),
  ]);

  const ompBinPath = path.join(os.homedir(), ".bun", "bin", "omp");
  if (fs.existsSync(ompBinPath)) {
    try {
      const realCliPath = fs.realpathSync(ompBinPath);
      const root = resolvePackageRootFromCli(realCliPath);
      if (root) candidates.add(root);
    } catch {}
  }

  for (const candidate of candidates) {
    const packageJsonPath = path.join(candidate, "package.json");
    if (!fs.existsSync(packageJsonPath)) continue;
    try {
      const pkg = JSON.parse(readText(packageJsonPath));
      if (pkg?.name === "@oh-my-pi/pi-coding-agent") {
        return candidate;
      }
    } catch {}
  }

  return null;
}

function syncBundledCodingAgentSource(root, relativePath) {
  const sourcePath = path.join(bundledCodingAgentDir, relativePath);
  const targetPath = path.join(root, relativePath);
  if (!fs.existsSync(sourcePath) || !fs.existsSync(targetPath)) return [];

  const current = readText(targetPath);
  const next = readText(sourcePath);
  const changed = writeIfChanged(targetPath, current, next);
  return changed ? [relativePath] : [];
}

const parserContent = lines([
  '/**',
  ' * Feature bracket parser for plugin install specifiers.',
  ' *',
  ' * Supports syntax like:',
  ' * - "my-plugin" -> base features (null)',
  ' * - "npm:my-plugin" -> npm source with base features',
  ' * - "git:github.com/user/repo" -> git source with base features',
  ' * - "https://github.com/user/repo[search]" -> git source with features',
  ' * - "my-plugin[search,web]" -> specific features',
  ' * - "my-plugin[*]" -> all features',
  ' * - "my-plugin[]" -> no optional features',
  ' * - "@scope/plugin@1.2.3[feat]" -> scoped npm package with version and features',
  ' */',
  '',
  'import { parseGitUrl } from "./git-url";',
  '',
  'export interface ParsedPluginSpec {',
  '\t/** Install target (npm package spec, git source, or supported URL) */',
  '\ttarget: string;',
  '\t/**',
  '\t * Feature selection:',
  '\t * - null: use defaults (base features on first install, preserve on reinstall)',
  '\t * - "*": all features',
  '\t * - string[]: specific features (empty array = no optional features)',
  '\t */',
  '\tfeatures: string[] | null | "*";',
  '}',
  '',
  'export interface ResolvedPluginInstallTarget {',
  '\tkind: "npm" | "git";',
  '\tinstallSpec: string;',
  '}',
  '',
  'function looksLikeExplicitGitSource(target: string): boolean {',
  '\treturn /^git:(?!\\/\\/)/i.test(target) || /^(https?|ssh|git):\\/\\//i.test(target);',
  '}',
  '',
  '/**',
  ' * Parse plugin specifier with feature bracket syntax.',
  ' *',
  ' * @example',
  ' * parsePluginSpec("my-plugin") // { target: "my-plugin", features: null }',
  ' * parsePluginSpec("my-plugin[search,web]") // { target: "my-plugin", features: ["search", "web"] }',
  ' * parsePluginSpec("my-plugin[*]") // { target: "my-plugin", features: "*" }',
  ' * parsePluginSpec("my-plugin[]") // { target: "my-plugin", features: [] }',
  ' * parsePluginSpec("git:github.com/user/repo[feat]") // { target: "git:github.com/user/repo", features: ["feat"] }',
  ' */',
  'export function parsePluginSpec(spec: string): ParsedPluginSpec {',
  '\t// Find the last bracket pair (to handle version specifiers like @1.0.0)',
  '\tconst bracketStart = spec.lastIndexOf("[");',
  '\tconst bracketEnd = spec.lastIndexOf("]");',
  '',
  '\t// No brackets or malformed -> base features',
  '\tif (bracketStart === -1 || bracketEnd === -1 || bracketEnd < bracketStart) {',
  '\t\treturn { target: spec, features: null };',
  '\t}',
  '',
  '\tconst target = spec.slice(0, bracketStart);',
  '\tconst featureStr = spec.slice(bracketStart + 1, bracketEnd).trim();',
  '',
  '\t// All features',
  '\tif (featureStr === "*") {',
  '\t\treturn { target, features: "*" };',
  '\t}',
  '',
  '\t// No optional features',
  '\tif (featureStr === "") {',
  '\t\treturn { target, features: [] };',
  '\t}',
  '',
  '\t// Specific features (comma-separated)',
  '\tconst features = featureStr',
  '\t\t.split(",")',
  '\t\t.map(f => f.trim())',
  '\t\t.filter(Boolean);',
  '',
  '\treturn { target, features };',
  '}',
  '',
  '/**',
  ' * Format a parsed plugin spec back to string form.',
  ' *',
  ' * @example',
  ' * formatPluginSpec({ target: "pkg", features: null }) // "pkg"',
  ' * formatPluginSpec({ target: "pkg", features: "*" }) // "pkg[*]"',
  ' * formatPluginSpec({ target: "pkg", features: [] }) // "pkg[]"',
  ' * formatPluginSpec({ target: "pkg", features: ["a", "b"] }) // "pkg[a,b]"',
  ' */',
  'export function formatPluginSpec(spec: ParsedPluginSpec): string {',
  '\tif (spec.features === null) {',
  '\t\treturn spec.target;',
  '\t}',
  '\tif (spec.features === "*") {',
  '\t\treturn `${spec.target}[*]`;',
  '\t}',
  '\tif (spec.features.length === 0) {',
  '\t\treturn `${spec.target}[]`;',
  '\t}',
  '\treturn `${spec.target}[${spec.features.join(",")}]`;',
  '}',
  '',
  '/**',
  ' * Normalize a plugin install target into a Bun-compatible install spec.',
  ' *',
  ' * Supports bare npm specs, `npm:`-prefixed npm specs, `git:` shorthand, and',
  ' * explicit git/https URLs. Git refs are normalized to `#ref` syntax because',
  ' * Bun accepts that form for remote installs.',
  ' */',
  'export function resolvePluginInstallTarget(target: string): ResolvedPluginInstallTarget {',
  '\tconst trimmed = target.trim();',
  '',
  '\tif (/^npm:/i.test(trimmed)) {',
  '\t\treturn {',
  '\t\t\tkind: "npm",',
  '\t\t\tinstallSpec: trimmed.slice(4).trim(),',
  '\t\t};',
  '\t}',
  '',
  '\tconst gitSource = parseGitUrl(trimmed);',
  '\tif (gitSource) {',
  '\t\treturn {',
  '\t\t\tkind: "git",',
  '\t\t\tinstallSpec: gitSource.ref ? `${gitSource.repo}#${gitSource.ref}` : gitSource.repo,',
  '\t\t};',
  '\t}',
  '',
  '\tif (looksLikeExplicitGitSource(trimmed)) {',
  '\t\tthrow new Error(`Invalid git plugin source: ${target}`);',
  '\t}',
  '',
  '\treturn { kind: "npm", installSpec: trimmed };',
  '}',
  '',
  '/**',
  ' * Extract the installed dependency name from an npm-style package specifier.',
  ' * Used for path lookups after npm installs.',
  ' *',
  ' * @example',
  ' * extractPackageName("lodash@4.17.21") // "lodash"',
  ' * extractPackageName("@scope/pkg@1.0.0") // "@scope/pkg"',
  ' * extractPackageName("@scope/pkg") // "@scope/pkg"',
  ' */',
  'export function extractPackageName(specifier: string): string {',
  '\t// Handle scoped packages: @scope/name@version -> @scope/name',
  '\tif (specifier.startsWith("@")) {',
  '\t\tconst match = specifier.match(/^(@[^/]+\\/[^@]+)/);',
  '\t\treturn match ? match[1] : specifier;',
  '\t}',
  '\t// Unscoped: name@version -> name',
  '\treturn specifier.replace(/@[^@]+$/, "");',
  '}',
]);

const managerValidationOld = lines([
  '/** Valid npm package name pattern (scoped and unscoped, with optional version) */',
  'const VALID_PACKAGE_NAME = /^(@[a-z0-9-~][a-z0-9-._~]*\\/)?[a-z0-9-~][a-z0-9-._~]*(@[a-z0-9-._^~>=<]+)?$/i;',
  '',
  '/**',
  ' * Validate package name to prevent command injection.',
  ' */',
  'function validatePackageName(name: string): void {',
  '\t// Remove version specifier for validation',
  '\tconst baseName = extractPackageName(name);',
  '\tif (!VALID_PACKAGE_NAME.test(baseName)) {',
  '\t\tthrow new Error(`Invalid package name: ${name}`);',
  '\t}',
  '\t// Extra safety: no shell metacharacters',
  '\tif (/[;&|`$(){}[\\]<>\\\\]/.test(name)) {',
  '\t\tthrow new Error(`Invalid characters in package name: ${name}`);',
  '\t}',
  '}',
]);

const managerValidationNew = lines([
  'type DependencyMap = Record<string, string>;',
  '',
  '/** Valid npm package name pattern (scoped and unscoped, with optional version) */',
  'const VALID_PACKAGE_NAME = /^(@[a-z0-9-~][a-z0-9-._~]*\\/)?[a-z0-9-~][a-z0-9-._~]*(@[a-z0-9-._^~>=<]+)?$/i;',
  '',
  '/**',
  ' * Validate an npm package specifier to prevent command injection.',
  ' */',
  'function validatePackageName(name: string): void {',
  '\tconst baseName = extractPackageName(name);',
  '\tif (!VALID_PACKAGE_NAME.test(baseName)) {',
  '\t\tthrow new Error(`Invalid package name: ${name}`);',
  '\t}',
  '\tif (/[;&|`$(){}[\\]<>\\\\]/.test(name)) {',
  '\t\tthrow new Error(`Invalid characters in package name: ${name}`);',
  '\t}',
  '}',
]);

const managerHelpers = lines([
  '\tasync #readDependencyMap(): Promise<DependencyMap> {',
  '\t\tconst pkg = (await Bun.file(getPluginsPackageJson()).json()) as { dependencies?: DependencyMap };',
  '\t\treturn pkg.dependencies || {};',
  '\t}',
  '',
  '\t#resolveInstalledPackageName(',
  '\t\tbeforeDeps: DependencyMap,',
  '\t\tafterDeps: DependencyMap,',
  '\t\tinstallTarget: ResolvedPluginInstallTarget,',
  '\t): string {',
  '\t\tif (installTarget.kind === "npm") {',
  '\t\t\treturn extractPackageName(installTarget.installSpec);',
  '\t\t}',
  '',
  '\t\tconst exactMatches = Object.entries(afterDeps)',
  '\t\t\t.filter(([, value]) => value === installTarget.installSpec)',
  '\t\t\t.map(([name]) => name);',
  '\t\tif (exactMatches.length === 1) {',
  '\t\t\treturn exactMatches[0]!;',
  '\t\t}',
  '\t\tif (exactMatches.length > 1) {',
  '\t\t\tthrow new Error(',
  '\t\t\t\t`Multiple installed dependencies match ${installTarget.installSpec}: ${exactMatches.join(", ")}`,' ,
  '\t\t\t);',
  '\t\t}',
  '',
  '\t\tconst changedMatches = Object.entries(afterDeps)',
  '\t\t\t.filter(([name, value]) => beforeDeps[name] !== value)',
  '\t\t\t.map(([name]) => name);',
  '\t\tif (changedMatches.length === 1) {',
  '\t\t\treturn changedMatches[0]!;',
  '\t\t}',
  '\t\tif (changedMatches.length > 1) {',
  '\t\t\tthrow new Error(',
  '\t\t\t\t`Installed git plugin name for ${installTarget.installSpec} is ambiguous: ${changedMatches.join(", ")}`,' ,
  '\t\t\t);',
  '\t\t}',
  '',
  '\t\tthrow new Error(`Installed git plugin could not be resolved from ${getPluginsPackageJson()}`);',
  '\t}',
  '',
]);

const managerInstallBlock = lines([
  '\t/**',
  '\t * Install a plugin from npm or git with optional feature selection.',
  '\t *',
  '\t * @param specString - Install source with optional features:',
  '\t *   - "pkg", "npm:pkg", "pkg[feat]", "pkg[*]", "pkg[]"',
  '\t *   - "git:github.com/user/repo" or "https://github.com/user/repo"',
  '\t * @param options - Install options',
  '\t * @returns Installed plugin metadata',
  '\t */',
  '\tasync install(specString: string, options: InstallOptions = {}): Promise<InstalledPlugin> {',
  '\t\tconst spec = parsePluginSpec(specString);',
  '\t\tconst installTarget = resolvePluginInstallTarget(spec.target);',
  '\t\tif (installTarget.kind === "npm") {',
  '\t\t\tvalidatePackageName(installTarget.installSpec);',
  '\t\t}',
  '',
  '\t\tawait this.#ensurePackageJson();',
  '',
  '\t\tif (options.dryRun) {',
  '\t\t\treturn {',
  '\t\t\t\tname: installTarget.kind === "npm" ? extractPackageName(installTarget.installSpec) : spec.target,',
  '\t\t\t\tversion: "0.0.0-dryrun",',
  '\t\t\t\tpath: "",',
  '\t\t\t\tmanifest: { version: "0.0.0-dryrun" },',
  '\t\t\t\tenabledFeatures: spec.features === "*" ? null : (spec.features as string[] | null),',
  '\t\t\t\tenabled: true,',
  '\t\t\t};',
  '\t\t}',
  '',
  '\t\tconst beforeDeps = await this.#readDependencyMap();',
  '',
  '\t\tconst proc = Bun.spawn(["bun", "install", installTarget.installSpec], {',
  '\t\t\tcwd: getPluginsDir(),',
  '\t\t\tstdin: "ignore",',
  '\t\t\tstdout: "pipe",',
  '\t\t\tstderr: "pipe",',
  '\t\t\twindowsHide: true,',
  '\t\t});',
  '',
  '\t\tconst exitCode = await proc.exited;',
  '\t\tif (exitCode !== 0) {',
  '\t\t\tconst stderr = await new Response(proc.stderr).text();',
  '\t\t\tthrow new Error(`bun install failed: ${stderr}`);',
  '\t\t}',
  '',
  '\t\tconst afterDeps = await this.#readDependencyMap();',
  '\t\tconst actualName = this.#resolveInstalledPackageName(beforeDeps, afterDeps, installTarget);',
  '\t\tconst pkgPath = path.join(getPluginsNodeModules(), actualName, "package.json");',
  '',
  '\t\tlet pkg: { name: string; version: string; omp?: PluginManifest; pi?: PluginManifest };',
  '\t\ttry {',
  '\t\t\tpkg = await Bun.file(pkgPath).json();',
  '\t\t} catch (err) {',
  '\t\t\tif (isEnoent(err)) {',
  '\t\t\t\tthrow new Error(`Package installed but package.json not found at ${pkgPath}`);',
  '\t\t\t}',
  '\t\t\tthrow err;',
  '\t\t}',
  '\t\tconst manifest: PluginManifest = pkg.omp || pkg.pi || { version: pkg.version };',
  '\t\tmanifest.version = pkg.version;',
  '',
  '\t\tlet enabledFeatures: string[] | null = null;',
  '\t\tif (spec.features === "*") {',
  '\t\t\tenabledFeatures = manifest.features ? Object.keys(manifest.features) : null;',
  '\t\t} else if (Array.isArray(spec.features)) {',
  '\t\t\tif (spec.features.length > 0) {',
  '\t\t\t\tif (manifest.features) {',
  '\t\t\t\t\tfor (const feat of spec.features) {',
  '\t\t\t\t\t\tif (!(feat in manifest.features)) {',
  '\t\t\t\t\t\t\tthrow new Error(',
  '\t\t\t\t\t\t\t\t`Unknown feature "${feat}" in ${actualName}. Available: ${Object.keys(manifest.features).join(", ")}`,' ,
  '\t\t\t\t\t\t\t);',
  '\t\t\t\t\t\t}',
  '\t\t\t\t\t}',
  '\t\t\t\t}',
  '\t\t\t\tenabledFeatures = spec.features;',
  '\t\t\t} else {',
  '\t\t\t\tenabledFeatures = [];',
  '\t\t\t}',
  '\t\t}',
  '',
  '\t\tconst config = await this.#ensureConfigLoaded();',
  '\t\tconfig.plugins[pkg.name] = {',
  '\t\t\tversion: pkg.version,',
  '\t\t\tenabledFeatures,',
  '\t\t\tenabled: true,',
  '\t\t};',
  '\t\tawait this.#saveRuntimeConfig();',
  '',
  '\t\treturn {',
  '\t\t\tname: pkg.name,',
  '\t\t\tversion: pkg.version,',
  '\t\t\tpath: path.join(getPluginsNodeModules(), actualName),',
  '\t\t\tmanifest,',
  '\t\t\tenabledFeatures,',
  '\t\t\tenabled: true,',
  '\t\t};',
  '\t}',
  '',
  '\t/**',
  '\t * Uninstall a plugin.',
  '\t */',
]);

const pluginCliUsageOld = lines([
  '\tif (packages.length === 0) {',
  '\t\tconsole.error(chalk.red(`Usage: ${APP_NAME} plugin install <package[@version]>[features] ...`));',
  '\t\tconsole.error(chalk.dim("Examples:"));',
  '\t\tconsole.error(chalk.dim(`  ${APP_NAME} plugin install @oh-my-pi/exa`));',
  '\t\tconsole.error(chalk.dim(`  ${APP_NAME} plugin install @oh-my-pi/exa[search,websets]`));',
  '\t\tconsole.error(chalk.dim(`  ${APP_NAME} plugin install @oh-my-pi/exa[*]  # all features`));',
  '\t\tconsole.error(chalk.dim(`  ${APP_NAME} plugin install @oh-my-pi/exa[]   # no optional features`));',
  '\t\tprocess.exit(1);',
  '\t}',
]);

const pluginCliUsageNew = lines([
  '\tif (packages.length === 0) {',
  '\t\tconsole.error(chalk.red(`Usage: ${APP_NAME} plugin install <source>[features] ...`));',
  '\t\tconsole.error(chalk.dim("Examples:"));',
  '\t\tconsole.error(chalk.dim(`  ${APP_NAME} plugin install @oh-my-pi/exa`));',
  '\t\tconsole.error(chalk.dim(`  ${APP_NAME} plugin install npm:pi-multi-pass`));',
  '\t\tconsole.error(chalk.dim(`  ${APP_NAME} plugin install git:github.com/davebcn87/pi-autoresearch`));',
  '\t\tconsole.error(chalk.dim(`  ${APP_NAME} plugin install https://github.com/davebcn87/pi-autoresearch`));',
  '\t\tconsole.error(chalk.dim(`  ${APP_NAME} plugin install @oh-my-pi/exa[search,websets]`));',
  '\t\tconsole.error(chalk.dim(`  ${APP_NAME} plugin install @oh-my-pi/exa[*]  # all features`));',
  '\t\tconsole.error(chalk.dim(`  ${APP_NAME} plugin install @oh-my-pi/exa[]   # no optional features`));',
  '\t\tprocess.exit(1);',
  '\t}',
]);

const pluginCliListOld = lines([
  '\tif (plugins.length === 0) {',
  '\t\tconsole.log(chalk.dim("No plugins installed"));',
  '\t\tconsole.log(chalk.dim(`\\nInstall plugins with: ${APP_NAME} plugin install <package>`));',
  '\t\treturn;',
  '\t}',
]);

const pluginCliListNew = lines([
  '\tif (plugins.length === 0) {',
  '\t\tconsole.log(chalk.dim("No plugins installed"));',
  '\t\tconsole.log(chalk.dim(`\\nInstall plugins with: ${APP_NAME} plugin install <source>`));',
  '\t\treturn;',
  '\t}',
]);

const pluginCliHelpOld = lines([
  'export function printPluginHelp(): void {',
  '\tconsole.log(`${chalk.bold(`${APP_NAME} plugin`)} - Plugin lifecycle management',
  '',
  '${chalk.bold("Commands:")}',
  '  install <pkg[@ver]>[features]  Install plugins from npm',
  '  uninstall <pkg>                Remove plugins',
  '  list                           Show installed plugins',
  '  link <path>                    Link local plugin for development',
  '  doctor                         Check plugin health',
  '  features <pkg>                 View/modify enabled features',
  '  config <cmd> <pkg> [key] [val] Manage plugin settings',
  '  enable <pkg>                   Enable a disabled plugin',
  '  disable <pkg>                  Disable plugin without uninstalling',
  '',
  '${chalk.bold("Feature Syntax:")}',
  '  pkg                Install with default features',
  '  pkg[feat1,feat2]   Install with specific features',
  '  pkg[*]             Install with all features',
  '  pkg[]              Install with no optional features',
  '',
  '${chalk.bold("Config Subcommands:")}',
  '  config list <pkg>              List all settings',
  '  config get <pkg> <key>         Get a setting value',
  '  config set <pkg> <key> <val>   Set a setting value',
  '  config delete <pkg> <key>      Delete a setting',
  '  config validate                Validate all plugin settings',
  '',
  '${chalk.bold("Options:")}',
  '  --json       Output as JSON',
  '  --fix        Attempt automatic fixes (doctor)',
  '  --force      Overwrite without prompting (install)',
  '  --dry-run    Preview changes without applying (install)',
  '  -l, --local  Use project-local overrides',
  '',
  '${chalk.bold("Examples:")}',
  '  ${APP_NAME} plugin install @oh-my-pi/exa[search]',
  '  ${APP_NAME} plugin list --json',
  '  ${APP_NAME} plugin features my-plugin --enable search,web',
  '  ${APP_NAME} plugin config set my-plugin apiKey sk-xxx',
  '  ${APP_NAME} plugin doctor --fix',
  '\t`);',
  '}',
]);

const pluginCliHelpNew = lines([
  'export function printPluginHelp(): void {',
  '\tconsole.log(`${chalk.bold(`${APP_NAME} plugin`)} - Plugin lifecycle management',
  '',
  '${chalk.bold("Commands:")}',
  '  install <source>[features]    Install plugins from npm or git',
  '  uninstall <pkg>               Remove plugins',
  '  list                          Show installed plugins',
  '  link <path>                   Link local plugin for development',
  '  doctor                        Check plugin health',
  '  features <pkg>                View/modify enabled features',
  '  config <cmd> <pkg> [key] [val] Manage plugin settings',
  '  enable <pkg>                  Enable a disabled plugin',
  '  disable <pkg>                 Disable plugin without uninstalling',
  '',
  '${chalk.bold("Feature Syntax:")}',
  '  pkg                  Install npm package with default features',
  '  npm:pkg              Install npm package with explicit source prefix',
  '  git:host/user/repo   Install git-hosted plugin via shorthand',
  '  https://host/user/repo Install git-hosted plugin via URL',
  '  pkg[feat1,feat2]     Install with specific features',
  '  pkg[*]               Install with all features',
  '  pkg[]                Install with no optional features',
  '',
  '${chalk.bold("Config Subcommands:")}',
  '  config list <pkg>              List all settings',
  '  config get <pkg> <key>         Get a setting value',
  '  config set <pkg> <key> <val>   Set a setting value',
  '  config delete <pkg> <key>      Delete a setting',
  '  config validate                Validate all plugin settings',
  '',
  '${chalk.bold("Options:")}',
  '  --json       Output as JSON',
  '  --fix        Attempt automatic fixes (doctor)',
  '  --force      Overwrite without prompting (install)',
  '  --dry-run    Preview changes without applying (install)',
  '  -l, --local  Use project-local overrides',
  '',
  '${chalk.bold("Examples:")}',
  '  ${APP_NAME} plugin install @oh-my-pi/exa[search]',
  '  ${APP_NAME} plugin install npm:pi-multi-pass',
  '  ${APP_NAME} plugin install git:github.com/davebcn87/pi-autoresearch',
  '  ${APP_NAME} plugin list --json',
  '  ${APP_NAME} plugin features my-plugin --enable search,web',
  '  ${APP_NAME} plugin config set my-plugin apiKey sk-xxx',
  '  ${APP_NAME} plugin doctor --fix',
  '\t`);',
  '}',
]);

const pluginTypesFeatureOld = lines([
  '\t/** Additional extension entry points provided by this feature */',
  '\textensions?: string[];',
  '\t/** Additional tool entry points provided by this feature */',
  '\ttools?: string[];',
  '\t/** Additional hook entry points provided by this feature */',
  '\thooks?: string[];',
  '\t/** Additional command files provided by this feature */',
  '\tcommands?: string[];',
]);

const pluginTypesFeatureNew = lines([
  '\t/** Additional extension entry points provided by this feature */',
  '\textensions?: string[];',
  '\t/** Additional skill directories provided by this feature */',
  '\tskills?: string[];',
  '\t/** Additional tool entry points provided by this feature */',
  '\ttools?: string[];',
  '\t/** Additional hook entry points provided by this feature */',
  '\thooks?: string[];',
  '\t/** Additional command files provided by this feature */',
  '\tcommands?: string[];',
]);

const pluginTypesManifestOld = lines([
  '\t/** Entry point for base tools (relative path from package root) */',
  '\ttools?: string;',
  '\t/** Entry point for base hooks (relative path from package root) */',
  '\thooks?: string;',
  '\t/** Extension entry points (relative paths from package root) */',
  '\textensions?: string[];',
  '\t/** Command files (relative paths from package root) */',
  '\tcommands?: string[];',
]);

const pluginTypesManifestNew = lines([
  '\t/** Entry point for base tools (relative path from package root) */',
  '\ttools?: string;',
  '\t/** Entry point for base hooks (relative path from package root) */',
  '\thooks?: string;',
  '\t/** Extension entry points (relative paths from package root) */',
  '\textensions?: string[];',
  '\t/** Skill root directories (relative paths from package root) */',
  '\tskills?: string[];',
  '\t/** Command files (relative paths from package root) */',
  '\tcommands?: string[];',
]);

const pluginLoaderHeaderOld = lines([
  '/**',
  ' * Generic path resolver for plugin manifest entries (tools, hooks, commands, extensions).',
  ' * Handles both single-string and string[] base entries, plus feature-specific entries.',
  ' */',
  'function resolvePluginPaths(plugin: InstalledPlugin, key: "tools" | "hooks" | "commands" | "extensions"): string[] {',
]);

const pluginLoaderHeaderNew = lines([
  '/**',
  ' * Generic path resolver for plugin manifest entries (tools, hooks, commands, extensions, skills).',
  ' * Handles both single-string and string[] base entries, plus feature-specific entries.',
  ' */',
  'function resolvePluginPaths(',
  '\tplugin: InstalledPlugin,',
  '\tkey: "tools" | "hooks" | "commands" | "extensions" | "skills",',
  '): string[] {',
]);

const pluginLoaderExtensionFnsOld = lines([
  'export function resolvePluginExtensionPaths(plugin: InstalledPlugin): string[] {',
  '\treturn resolvePluginPaths(plugin, "extensions");',
  '}',
]);

const pluginLoaderExtensionFnsNew = lines([
  'export function resolvePluginExtensionPaths(plugin: InstalledPlugin): string[] {',
  '\treturn resolvePluginPaths(plugin, "extensions");',
  '}',
  '',
  'export function resolvePluginSkillPaths(plugin: InstalledPlugin): string[] {',
  '\treturn resolvePluginPaths(plugin, "skills");',
  '}',
]);

const pluginLoaderAggregateOld = lines([
  '/**',
  ' * Get all extension module paths from all enabled plugins.',
  ' */',
  'export async function getAllPluginExtensionPaths(cwd: string): Promise<string[]> {',
  '\tconst plugins = await getEnabledPlugins(cwd);',
  '\tconst paths: string[] = [];',
  '',
  '\tfor (const plugin of plugins) {',
  '\t\tpaths.push(...resolvePluginExtensionPaths(plugin));',
  '\t}',
  '',
  '\treturn paths;',
  '}',
]);

const pluginLoaderAggregateNew = lines([
  '/**',
  ' * Get all extension module paths from all enabled plugins.',
  ' */',
  'export async function getAllPluginExtensionPaths(cwd: string): Promise<string[]> {',
  '\tconst plugins = await getEnabledPlugins(cwd);',
  '\tconst paths: string[] = [];',
  '',
  '\tfor (const plugin of plugins) {',
  '\t\tpaths.push(...resolvePluginExtensionPaths(plugin));',
  '\t}',
  '',
  '\treturn paths;',
  '}',
  '',
  '/**',
  ' * Get all skill root paths from all enabled plugins.',
  ' */',
  'export async function getAllPluginSkillPaths(cwd: string): Promise<string[]> {',
  '\tconst plugins = await getEnabledPlugins(cwd);',
  '\tconst paths: string[] = [];',
  '',
  '\tfor (const plugin of plugins) {',
  '\t\tpaths.push(...resolvePluginSkillPaths(plugin));',
  '\t}',
  '',
  '\treturn paths;',
  '}',
]);

const extensionLoaderPluginOld = '\t// 2. Discover extension entry points from installed plugins\n\taddPaths(await getAllPluginExtensionPaths(cwd));\n';
const extensionLoaderPluginNew = lines([
  '\t// 2. Discover extension entry points from installed plugins',
  '\tfor (const pluginPath of await getAllPluginExtensionPaths(cwd)) {',
  '\t\tawait addResolvedPath(pluginPath);',
  '\t}',
]);

const extensionLoaderConfiguredOld = lines([
  '\t// 3. Explicitly configured paths',
  '\tfor (const configuredPath of configuredPaths) {',
  '\t\tconst resolved = resolvePath(configuredPath, cwd);',
  '',
  '\t\tlet stat: fs1.Stats | null = null;',
  '\t\ttry {',
  '\t\t\tstat = await fs.stat(resolved);',
  '\t\t} catch (err) {',
  '\t\t\tif (!isEnoent(err)) throw err;',
  '\t\t}',
  '',
  '\t\tif (stat?.isDirectory()) {',
  '\t\t\tconst entries = await resolveExtensionEntries(resolved);',
  '\t\t\tif (entries) {',
  '\t\t\t\taddPaths(entries);',
  '\t\t\t\tcontinue;',
  '\t\t\t}',
  '',
  '\t\t\tconst discovered = await discoverExtensionsInDir(resolved);',
  '\t\t\tif (discovered.length > 0) {',
  '\t\t\t\taddPaths(discovered);',
  '\t\t\t}',
  '\t\t\tcontinue;',
  '\t\t}',
  '',
  '\t\taddPath(resolved);',
  '\t}',
]);

const extensionLoaderConfiguredNew = lines([
  '\t// 3. Explicitly configured paths',
  '\tfor (const configuredPath of configuredPaths) {',
  '\t\tawait addResolvedPath(resolvePath(configuredPath, cwd));',
  '\t}',
]);

const extensionLoaderHelper = lines([
  '\tconst addResolvedPath = async (candidatePath: string): Promise<void> => {',
  '\t\tlet stat: fs1.Stats | null = null;',
  '\t\ttry {',
  '\t\t\tstat = await fs.stat(candidatePath);',
  '\t\t} catch (err) {',
  '\t\t\tif (!isEnoent(err)) throw err;',
  '\t\t}',
  '',
  '\t\tif (stat?.isDirectory()) {',
  '\t\t\tconst entries = await resolveExtensionEntries(candidatePath);',
  '\t\t\tif (entries) {',
  '\t\t\t\taddPaths(entries);',
  '\t\t\t\treturn;',
  '\t\t\t}',
  '',
  '\t\t\tconst discovered = await discoverExtensionsInDir(candidatePath);',
  '\t\t\tif (discovered.length > 0) {',
  '\t\t\t\taddPaths(discovered);',
  '\t\t\t}',
  '\t\t\treturn;',
  '\t\t}',
  '',
  '\t\taddPath(candidatePath);',
  '\t};',
  '',
]);

const skillsBlockNew = lines([
  '\tconst pluginDirectories = await getAllPluginSkillPaths(cwd);',
  '\tconst extraDirectorySources = [',
  '\t\t...pluginDirectories.map(dir => ({',
  '\t\t\tdir,',
  '\t\t\tproviderId: "plugin",',
  '\t\t\tproviderName: "Plugin",',
  '\t\t\tsource: "plugin:user",',
  '\t\t})),',
  '\t\t...customDirectories.map(dir => ({',
  '\t\t\tdir: expandTilde(dir),',
  '\t\t\tproviderId: "custom",',
  '\t\t\tproviderName: "Custom",',
  '\t\t\tsource: "custom:user",',
  '\t\t})),',
  '\t];',
  '',
  '\tconst extraDirectoryResults = await Promise.all(',
  '\t\textraDirectorySources.map(async source => {',
  '\t\t\tconst scanResult = await scanSkillsFromDir(',
  '\t\t\t\t{ cwd, home: os.homedir(), repoRoot: null },',
  '\t\t\t\t{',
  '\t\t\t\t\tdir: source.dir,',
  '\t\t\t\t\tproviderId: source.providerId,',
  '\t\t\t\t\tlevel: "user",',
  '\t\t\t\t\trequireDescription: true,',
  '\t\t\t\t},',
  '\t\t\t);',
  '\t\t\treturn { source, scanResult };',
  '\t\t}),',
  '\t);',
  '',
  '\tconst allExtraSkills: Array<{ skill: Skill; path: string }> = [];',
  '\tfor (const { source, scanResult } of extraDirectoryResults) {',
  '\t\tfor (const capSkill of scanResult.items) {',
  '\t\t\tif (disabledSkillNames.has(capSkill.name)) continue;',
  '\t\t\tif (matchesIgnorePatterns(capSkill.name)) continue;',
  '\t\t\tif (!matchesIncludePatterns(capSkill.name)) continue;',
  '\t\t\tallExtraSkills.push({',
  '\t\t\t\tskill: {',
  '\t\t\t\t\tname: capSkill.name,',
  '\t\t\t\t\tdescription:',
  '\t\t\t\t\t\ttypeof capSkill.frontmatter?.description === "string" ? capSkill.frontmatter.description : "",',
  '\t\t\t\t\tfilePath: capSkill.path,',
  '\t\t\t\t\tbaseDir: capSkill.path.replace(/\\/SKILL\\.md$/, ""),',
  '\t\t\t\t\tsource: source.source,',
  '\t\t\t\t\t_source: { ...capSkill._source, providerName: source.providerName },',
  '\t\t\t\t},',
  '\t\t\t\tpath: capSkill.path,',
  '\t\t\t});',
  '\t\t}',
  '\t\tcollisionWarnings.push(...(scanResult.warnings ?? []).map(message => ({ skillPath: source.dir, message })));',
  '\t}',
  '',
  '\tconst extraRealPaths = await Promise.all(',
  '\t\tallExtraSkills.map(async ({ path }) => {',
  '\t\t\ttry {',
  '\t\t\t\treturn await fs.realpath(path);',
  '\t\t\t} catch {',
  '\t\t\t\treturn path;',
  '\t\t\t}',
  '\t\t}),',
  '\t);',
  '',
  '\tfor (let i = 0; i < allExtraSkills.length; i++) {',
  '\t\tconst { skill } = allExtraSkills[i];',
  '\t\tconst resolvedPath = extraRealPaths[i];',
  '\t\tif (realPathSet.has(resolvedPath)) continue;',
  '',
  '\t\tconst existing = skillMap.get(skill.name);',
  '\t\tif (existing) {',
  '\t\t\tcollisionWarnings.push({',
  '\t\t\t\tskillPath: skill.filePath,',
  '\t\t\t\tmessage: `name collision: "${skill.name}" already loaded from ${existing.filePath}, skipping this one`,',
  '\t\t\t});',
  '\t\t} else {',
  '\t\t\tskillMap.set(skill.name, skill);',
  '\t\t\trealPathSet.add(resolvedPath);',
  '\t\t}',
  '\t}',
  '',
  '\tconst skills = Array.from(skillMap.values());',
]);

function patchParser(root) {
  const filePath = path.join(root, 'src', 'extensibility', 'plugins', 'parser.ts');
  const current = readText(filePath);
  const changed = writeIfChanged(filePath, current, parserContent);
  return changed ? ['parser.ts'] : [];
}

function patchManager(root) {
  const filePath = path.join(root, 'src', 'extensibility', 'plugins', 'manager.ts');
  let source = readText(filePath);
  const current = source;

  source = replaceOnce(
    source,
    'import { extractPackageName, parsePluginSpec } from "./parser";\n',
    'import { extractPackageName, parsePluginSpec, resolvePluginInstallTarget } from "./parser";\nimport type { ResolvedPluginInstallTarget } from "./parser";\n',
    'manager parser imports',
  );
  source = replaceOnce(source, managerValidationOld, managerValidationNew, 'manager validation block');
  source = prependBefore(
    source,
    '\t// ==========================================================================\n\t// Install / Uninstall\n\t// ==========================================================================\n',
    managerHelpers,
    'manager helper insertion',
  );
  source = replaceBetween(
    source,
    '\t/**\n\t * Install a plugin from npm with optional feature selection.\n',
    '\n\t/**\n\t * Uninstall a plugin.\n\t */\n',
    managerInstallBlock,
    'manager install block',
  );
  source = source.replace(
    'throw new Error(`npm uninstall failed for ${name}`);',
    'throw new Error(`bun uninstall failed for ${name}`);',
  );

  const changed = writeIfChanged(filePath, current, source);
  return changed ? ['manager.ts'] : [];
}

function patchPluginCli(root) {
  const filePath = path.join(root, 'src', 'cli', 'plugin-cli.ts');
  let source = readText(filePath);
  const current = source;

  source = replaceOnce(source, pluginCliUsageOld, pluginCliUsageNew, 'plugin CLI install usage');
  source = replaceOnce(source, pluginCliListOld, pluginCliListNew, 'plugin CLI list hint');
  const pluginCliHelpBodyNew = pluginCliHelpNew.replace(/\n}\n$/, '\n');
  if (!source.includes('  install <source>[features]    Install plugins from npm or git')) {
    source = replaceBetween(
      source,
      'export function printPluginHelp(): void {\n',
      '\n}\n',
      pluginCliHelpBodyNew,
      'plugin CLI help text',
    );
  }
  source = source.replace('\n}\n\n}\n', '\n}\n');
  const changed = writeIfChanged(filePath, current, source);
  return changed ? ['plugin-cli.ts'] : [];
}

function patchPluginTypes(root) {
  const filePath = path.join(root, 'src', 'extensibility', 'plugins', 'types.ts');
  let source = readText(filePath);
  const current = source;

  source = replaceOnce(source, pluginTypesFeatureOld, pluginTypesFeatureNew, 'plugin feature skills support');
  source = replaceOnce(source, pluginTypesManifestOld, pluginTypesManifestNew, 'plugin manifest skills support');

  const changed = writeIfChanged(filePath, current, source);
  return changed ? ['types.ts'] : [];
}

function patchPluginLoader(root) {
  const filePath = path.join(root, 'src', 'extensibility', 'plugins', 'loader.ts');
  let source = readText(filePath);
  const current = source;

  source = replaceOnce(source, pluginLoaderHeaderOld, pluginLoaderHeaderNew, 'plugin loader path resolver header');
  source = replaceOnce(source, pluginLoaderExtensionFnsOld, pluginLoaderExtensionFnsNew, 'plugin loader skill resolver');
  source = replaceOnce(source, pluginLoaderAggregateOld, pluginLoaderAggregateNew, 'plugin loader skill aggregate');

  const changed = writeIfChanged(filePath, current, source);
  return changed ? ['loader.ts'] : [];
}

function patchExtensionLoader(root) {
  const filePath = path.join(root, 'src', 'extensibility', 'extensions', 'loader.ts');
  let source = readText(filePath);
  const current = source;

  source = prependBefore(
    source,
    '\t// 1. Discover extension modules via capability API (native .omp/.pi only)\n',
    extensionLoaderHelper,
    'extension loader directory resolver',
  );
  source = replaceOnce(source, extensionLoaderPluginOld, extensionLoaderPluginNew, 'extension loader plugin path resolution');
  source = replaceOnce(source, extensionLoaderConfiguredOld, extensionLoaderConfiguredNew, 'extension loader configured path resolution');

  const changed = writeIfChanged(filePath, current, source);
  return changed ? ['extensions/loader.ts'] : [];
}

function patchSkills(root) {
  const filePath = path.join(root, 'src', 'extensibility', 'skills.ts');
  let source = readText(filePath);
  const current = source;

  source = replaceOnce(
    source,
    'import { expandTilde } from "../tools/path-utils";\n',
    'import { expandTilde } from "../tools/path-utils";\nimport { getAllPluginSkillPaths } from "./plugins/loader";\n',
    'skills plugin import',
  );
  if (source.includes('const pluginDirectories = await getAllPluginSkillPaths(cwd);')) {
    source = source.replace(
      '\n\tconst skills = Array.from(skillMap.values());\n\n\tconst skills = Array.from(skillMap.values());\n',
      '\n\tconst skills = Array.from(skillMap.values());\n',
    );
  } else {
    source = replaceBetween(
      source,
      '\tconst customDirectoryResults = await Promise.all(\n',
      '\n\t// Deterministic ordering for prompt stability (case-insensitive, then exact name, then path).\n',
      `${skillsBlockNew}\t// Deterministic ordering for prompt stability (case-insensitive, then exact name, then path).\n`,
      'skills plugin/custom directory merge block',
    );
  }

  const changed = writeIfChanged(filePath, current, source);
  return changed ? ['skills.ts'] : [];
}

function main() {
  const root = findActivePackageRoot();
  if (!root) {
    console.log('No active global @oh-my-pi/pi-coding-agent install found. Skipping OMP compatibility patch.');
    return;
  }

  const pkg = JSON.parse(readText(path.join(root, 'package.json')));
  console.log(`Patching OMP runtime at ${root} (version ${pkg.version ?? 'unknown'})`);

  const changedFiles = [
    ...patchParser(root).map(name => `plugins/${name}`),
    ...patchManager(root).map(name => `plugins/${name}`),
    ...patchPluginCli(root).map(name => `cli/${name}`),
    ...patchPluginTypes(root).map(name => `plugins/${name}`),
    ...patchPluginLoader(root).map(name => `plugins/${name}`),
    ...patchExtensionLoader(root),
    ...patchSkills(root),
    ...syncBundledCodingAgentSource(root, path.join('src', 'modes', 'components', 'extensions', 'state-manager.ts')),
    ...syncBundledCodingAgentSource(root, path.join('src', 'modes', 'controllers', 'extension-ui-controller.ts')),
    ...syncBundledCodingAgentSource(root, path.join('src', 'modes', 'interactive-mode.ts')),
    ...syncBundledCodingAgentSource(root, path.join('src', 'modes', 'types.ts')),
  ];
  if (changedFiles.length === 0) {
    console.log('OMP compatibility patch already applied.');
    return;
  }

  console.log('Updated files:');
  for (const file of changedFiles) {
    console.log(`- ${file}`);
  }
}

main();
