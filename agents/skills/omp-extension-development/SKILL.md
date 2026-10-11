---
name: omp-extension-development
description: Use when developing, installing, or managing Oh My Pi (OMP) extensions. Covers extension manifest format, discovery paths, ExtensionAPI, custom tools, commands, and lifecycle events. Triggers when working with ~/.omp/agent/extensions/, package.json omp/pi fields, or creating plugins for OMP.
---

# Oh My Pi (OMP) Extension Development

## Overview

OMP (Oh My Pi) is a fork of pi-mono with a powerful extension system. Extensions are TypeScript modules that can subscribe to agent lifecycle events, register custom tools, commands, and interact with the TUI. This skill covers the complete extension development workflow.

**OMP maintains backward compatibility with pi-mono** — the `pi` field in package.json works identically to the `omp` field.

## Extension Discovery Paths

Extensions are auto-discovered from (in priority order):

1. **`~/.omp/agent/extensions/`** — User-level extensions (legacy: `~/.pi/agent/extensions/`)
2. **`<cwd>/.omp/extensions/`** — Project-level extensions (legacy: `<cwd>/.pi/extensions/`)
3. **`settings.json` "extensions" array** — Explicit paths
4. **`--extension` CLI flag** — Command-line specified paths
5. **Installed plugins via `package.json` manifest** — Via `omp` or `pi` field

## Extension Module Format

An extension exports a **default function** receiving `ExtensionAPI`:

```typescript
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { Type } from "@sinclair/typebox";

export default function (pi: ExtensionAPI) {
  // Lifecycle event handlers
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "bash" && event.input.command?.includes("rm -rf")) {
      const ok = await ctx.ui.confirm("Dangerous!", "Allow rm -rf?");
      if (!ok) return { block: true, reason: "Blocked by user" };
    }
  });

  // Register custom LLM-callable tools
  pi.registerTool({
    name: "greet",
    label: "Greeting",
    description: "Generate a greeting",
    parameters: Type.Object({
      name: Type.String({ description: "Name to greet" }),
    }),
    async execute(toolCallId, params, onUpdate, ctx, signal) {
      return {
        content: [{ type: "text", text: `Hello, ${params.name}!` }],
        details: {},
      };
    },
  });

  // Register slash commands
  pi.registerCommand("hello", {
    description: "Say hello",
    handler: async (args, ctx) => {
      ctx.ui.notify("Hello!", "info");
    },
  });
}
```

## Plugin Manifest (package.json)

For distributable plugins with dependencies, use the `omp` or `pi` field:

```json
{
  "name": "my-omp-plugin",
  "version": "1.0.0",
  "type": "module",
  "omp": {
    "name": "My Plugin",
    "description": "Does useful things",
    "extensions": ["./src/index.ts"],
    "tools": "./src/tools/index.ts",
    "hooks": "./src/hooks/index.ts",
    "skills": ["./skills"],
    "commands": ["./commands/hello.md"],
    "features": {
      "advanced": {
        "description": "Advanced features",
        "default": false,
        "extensions": ["./src/advanced.ts"],
        "tools": "./src/advanced-tools.ts"
      }
    },
    "settings": {
      "apiKey": {
        "type": "string",
        "description": "API key for external service",
        "secret": true
      }
    }
  }
}
```

### Manifest Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | `string` | Plugin display name |
| `description` | `string` | Human-readable description |
| `version` | `string` | Plugin version (copied from package.json) |
| `extensions` | `string[]` | Extension entry points (relative paths) |
| `tools` | `string` | Base tools entry point |
| `hooks` | `string` | Hooks entry point |
| `skills` | `string[]` | Skill directories |
| `commands` | `string[]` | Command files |
| `features` | `Record<string, PluginFeature>` | Optional feature flags |
| `settings` | `Record<string, PluginSettingSchema>` | Configuration schema |

## Installing Extensions

### Method 1: Direct Extension Files

```bash
# Copy to extensions directory for auto-discovery
cp my-extension.ts ~/.omp/agent/extensions/

# Or use CLI flag
pi --extension ./my-extension.ts
```

### Method 2: Via settings.json

```json
{
  "extensions": [
    "./project-extension.ts",
    "~/.omp/agent/extensions/my-extension.ts"
  ]
}
```

### Method 3: NPM Package with Manifest

```bash
# Install as dependency
npm install my-omp-plugin

# OMP auto-discovers from node_modules if package.json has omp/pi field
```

### Method 4: Git Repository

```bash
# Clone to plugins directory
git clone https://github.com/user/omp-plugin.git ~/.omp/plugins/my-plugin

# Or add to package.json dependencies pointing at git URL
```

## ExtensionAPI Reference

### Lifecycle Events

```typescript
pi.on("agent_start", async () => { ... });
pi.on("agent_end", async (event) => { ... });
pi.on("message_start", async (event) => { ... });
pi.on("message_update", async (event) => { ... });
pi.on("message_end", async (event) => { ... });
pi.on("tool_call", async (event, ctx) => { 
  // Return { block: true, reason: "..." } to block execution
});
pi.on("tool_result", async (event, ctx) => { ... });
pi.on("session_start", async (event, ctx) => { ... });
pi.on("session_switch", async (event) => { ... });
pi.on("session_branch", async (event) => { ... });
pi.on("session_shutdown", async (event) => { ... });
pi.on("ttsr_triggered", async (event) => { ... });
```

### Registration Methods

```typescript
// Register custom tools callable by LLM
pi.registerTool(toolDefinition: CustomTool);

// Register slash commands
pi.registerCommand(name: string, command: RegisteredCommand);

// Register CLI flags
pi.registerFlag(name: string, options: FlagOptions);
```

### UI Methods (Interactive Mode Only)

Available when `ctx.hasUI` is true:

```typescript
// Show notification
ctx.ui.notify(message: string, type: "info" | "warning" | "error");

// Confirmation dialog
const ok = await ctx.ui.confirm(title: string, message: string);

// Selection dialog
const selected = await ctx.ui.select(items: SelectItem[], options?: SelectOptions);

// Mount custom TUI component
const result = await ctx.ui.custom<T>(
  (tui: TUI, theme: Theme, keybindings: KeybindingsManager, done: (result: T) => void) => Component
);

// Set editor text
ctx.ui.setEditorText(text: string);
```

## Custom Tool Definition

```typescript
import { Type } from "@sinclair/typebox";

pi.registerTool({
  name: "my_tool",
  label: "My Tool",
  description: "What this tool does",
  parameters: Type.Object({
    input: Type.String({ description: "Input parameter" }),
    optional: Type.Optional(Type.Number()),
  }),
  
  async execute(toolCallId, params, onUpdate, ctx, signal) {
    // Stream partial results
    onUpdate?.({
      content: [{ type: "text", text: "Processing..." }],
      details: { phase: "processing" },
    });
    
    // Return final result
    return {
      content: [{ type: "text", text: `Result: ${params.input}` }],
      details: { final: true },
    };
  },
  
  // Optional: Custom rendering
  renderCall(args, theme) {
    return theme.fg("accent", `Running: ${args.input}`);
  },
  
  renderResult(result, options, theme, args) {
    return result.content.map(c => c.text).join("\n");
  },
});
```

## State Persistence

Store state in tool result `details` for proper branching support:

```typescript
return {
  content: [{ type: "text", text: "Done" }],
  details: { todos: [...todos], nextId }, // Persisted in session
};

// Reconstruct on session events
pi.on("session_start", async (_event, ctx) => {
  for (const entry of ctx.sessionManager.getBranch()) {
    if (entry.type === "message" && entry.message.toolName === "my_tool") {
      const details = entry.message.details;
      // Restore state from details
    }
  }
});
```

## Common Patterns

### Permission Gate

```typescript
pi.on("tool_call", async (event, ctx) => {
  if (event.toolName === "bash") {
    const cmd = event.input.command;
    if (cmd?.match(/rm -rf|sudo|dd if/)) {
      const ok = await ctx.ui.confirm("Dangerous Command", `Allow: ${cmd}?`);
      if (!ok) return { block: true, reason: "User denied dangerous command" };
    }
  }
});
```

### Protected Paths

```typescript
pi.on("tool_call", async (event) => {
  if (event.toolName === "write" || event.toolName === "edit") {
    const path = event.input.path;
    if (path?.match(/\.env$|\.git\/|node_modules/)) {
      return { block: true, reason: `Protected path: ${path}` };
    }
  }
});
```

### Custom UI Component

```typescript
pi.registerCommand("pick-model", {
  description: "Pick a model profile",
  handler: async (_args, ctx) => {
    if (!ctx.hasUI) return;
    
    const selected = await ctx.ui.custom<string | undefined>(
      (tui, theme, keybindings, done) => {
        // Return a Component implementation
        return new ModelPicker(done, keybindings);
      }
    );
    
    if (selected) ctx.ui.notify(`Selected: ${selected}`, "info");
  },
});
```

## Project Structure Example

```
my-omp-extension/
├── package.json          # With "omp" or "pi" manifest field
├── src/
│   ├── index.ts          # Main extension entry point
│   ├── tools/
│   │   └── index.ts      # Tool definitions
│   ├── commands/
│   │   └── hello.md      # Slash command docs
│   └── hooks/
│       └── index.ts      # Hook handlers
├── skills/
│   └── my-skill/
│       └── SKILL.md      # Skill documentation
└── tsconfig.json
```

## Key Implementation Files

- `packages/coding-agent/src/extensibility/extensions/types.ts` — ExtensionAPI types
- `packages/coding-agent/src/extensibility/plugins/types.ts` — Plugin manifest types
- `packages/coding-agent/examples/extensions/` — Working examples
- `packages/tui/src/tui.ts` — TUI Component interface

## Best Practices

1. **Always guard UI usage**: Check `ctx.hasUI` before calling UI methods
2. **Use TypeBox for parameters**: Required for proper schema validation
3. **Persist state in details**: Enables proper session branching/resume
4. **Handle cancellation**: Forward `signal` to async operations
5. **Clean up resources**: Use `dispose()` on components when applicable
6. **Test in non-UI mode**: Extensions should work headless too
7. **Namespace tool names**: Avoid collisions with built-in tools

## Troubleshooting

**Extension not loading:**
- Check discovery path: `~/.omp/agent/extensions/` or project `.omp/extensions/`
- Verify file has `.ts` extension and is valid TypeScript
- Check OMP logs for load errors

**Tool not appearing:**
- Ensure tool name is unique (not colliding with built-ins)
- Verify `Type.Object()` schema is properly defined
- Check that tool is registered in extension default export

**UI methods failing:**
- Always check `ctx.hasUI` before calling UI methods
- UI is only available in interactive TUI mode, not RPC/headless

**Plugin not discovered:**
- Ensure `package.json` has `omp` or `pi` field
- Check that paths in manifest are relative to package root
- Verify plugin is in `~/.omp/plugins/` or project `node_modules/`
