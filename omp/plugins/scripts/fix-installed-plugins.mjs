import { existsSync, mkdirSync, readFileSync, unlinkSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const scriptsDir = dirname(fileURLToPath(import.meta.url));
const pluginsDir = join(scriptsDir, "..");
const ompDir = join(pluginsDir, "..");

function writeIfChanged(path, next) {
  const current = existsSync(path) ? readFileSync(path, "utf8") : null;
  if (current === next) return;
  writeFileSync(path, next);
}

function deleteIfExists(path) {
  if (!existsSync(path)) return;
  unlinkSync(path);
}

function patchMultiPassManifest() {
  const manifestPath = join(pluginsDir, "node_modules", "pi-multi-pass", "package.json");
  if (!existsSync(manifestPath)) return;

  const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
  const extensions = manifest?.pi?.extensions;
  if (!Array.isArray(extensions)) return;

  const nextExtensions = extensions.map((entry) => (entry === "./extensions" ? "./extensions/multi-sub.ts" : entry));
  if (JSON.stringify(nextExtensions) === JSON.stringify(extensions)) return;

  manifest.pi = { ...manifest.pi, extensions: nextExtensions };
  writeIfChanged(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
}

function patchDesignDeckManifest() {
  const manifestPath = join(pluginsDir, "node_modules", "pi-design-deck", "package.json");
  if (!existsSync(manifestPath)) return;

  const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
  const piConfig = manifest?.pi;
  if (!piConfig || typeof piConfig !== "object") return;

  const commands = [
    "./prompts/deck.md",
    "./prompts/deck-plan.md",
    "./prompts/deck-discover.md",
  ];

  const currentCommands = Array.isArray(piConfig.commands) ? piConfig.commands : [];
  if (JSON.stringify(currentCommands) === JSON.stringify(commands)) return;

  manifest.pi = { ...piConfig, commands };
  writeIfChanged(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
}

function patchLegacyImports(relativePath) {
  const sourcePath = join(pluginsDir, "node_modules", relativePath);
  if (!existsSync(sourcePath)) return;

  const current = readFileSync(sourcePath, "utf8");
  const next = current
    .replaceAll("@mariozechner/pi-coding-agent", "@oh-my-pi/pi-coding-agent")
    .replaceAll("@mariozechner/pi-tui", "@oh-my-pi/pi-tui")
    .replaceAll("@mariozechner/pi-ai/oauth", "@oh-my-pi/pi-ai")
    .replaceAll("@mariozechner/pi-ai", "@oh-my-pi/pi-ai");

  writeIfChanged(sourcePath, next);
}

function patchMultiPassCompatibility() {
  const sourcePath = join(pluginsDir, "node_modules", "pi-multi-pass", "extensions", "multi-sub.ts");
  if (!existsSync(sourcePath)) return;

  const current = readFileSync(sourcePath, "utf8");
  const next = current
    .replace(/\n\s*builtinOAuth: .*?,/g, "")
    .replace(/\n\s*builtinOAuth: .*OAuthProviderInterface;\n/g, "\n")
    .replaceAll("anthropicOAuthProvider,\n", "")
    .replaceAll("openaiCodexOAuthProvider,\n", "")
    .replaceAll("githubCopilotOAuthProvider,\n", "")
    .replaceAll("geminiCliOAuthProvider,\n", "")
    .replaceAll("antigravityOAuthProvider,\n", "")
    .replaceAll("getModels, type Api, type Model", "getBundledModels, type Api, type Model")
    .replaceAll("getModels(", "getBundledModels(");

  writeIfChanged(sourcePath, next);
}

function normalizeDesignDeckPrompt(content) {
  const match = content.match(/^(---\n[\s\S]*?\n---\n)([\s\S]*)$/);
  if (!match) return content;

  const [, frontmatter, body] = match;
  const nextBody = body.replace(/^Load the `design-deck` skill[\s\S]*?\n\n/, "");
  return `${frontmatter}${nextBody}`;
}

function syncDesignDeckCommands() {
  const promptsDir = join(pluginsDir, "node_modules", "pi-design-deck", "prompts");
  const commandsDir = join(ompDir, "agent", "commands");
  const promptFiles = ["deck.md", "deck-plan.md", "deck-discover.md"];

  mkdirSync(commandsDir, { recursive: true });

  for (const file of promptFiles) {
    const sourcePath = join(promptsDir, file);
    const targetPath = join(commandsDir, file);

    if (!existsSync(sourcePath)) {
      deleteIfExists(targetPath);
      continue;
    }

    const source = readFileSync(sourcePath, "utf8");
    writeIfChanged(targetPath, normalizeDesignDeckPrompt(source));
  }
}

patchMultiPassManifest();
patchDesignDeckManifest();
patchLegacyImports(join("pi-design-deck", "index.ts"));
patchLegacyImports(join("pi-multi-pass", "extensions", "multi-sub.ts"));
patchMultiPassCompatibility();
syncDesignDeckCommands();