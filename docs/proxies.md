# Proxy Setup

This repo keeps proxy guidance in one place. The current setup is an OpenAI-only `CLIProxyAPIPlus` runtime for multiple ChatGPT/Codex accounts.

## CLIProxyAPIPlus

`CLIProxyAPIPlus` can authenticate OpenAI/Codex accounts with device-code login and persist them as separate auth files. With `round-robin` routing enabled, the proxy rotates across those accounts automatically when one hits its rate window.

This repo now follows the same high-level pattern VibeProxy uses for localhost clients: upstream OAuth stays on the proxy side, and local tools do not need a real client secret by default.

## Install

```bash
./install.sh -p cliproxy,omp
```

Requirements:

- `docker`
- `docker compose` v2
- Docker daemon access for the current user
- a browser you can use to complete the device-code login

The dotfiles installer now links the full `cliproxy/` package to `~/.cliproxy/`. Ignored local files such as `config.yaml`, `auths/`, and `logs/` live inside that repo-backed directory, so tracked changes propagate across machines while local secrets stay out of git. In Docker, the proxy binds to all interfaces inside the container, while `docker-compose.yml` still publishes it only on host `127.0.0.1:8317`.

By default `~/.cliproxy/config.yaml` keeps `api-keys: []`, so localhost clients can talk to the proxy without a separate shared access token. If you later want client auth anyway, add one or more keys there and configure the same bearer token in each client locally.

To update the image later:

```bash
~/.cliproxy/update.sh
```

## OpenAI login flow

Run the login helper once per OpenAI account:

```bash
~/.cliproxy/login-openai.sh
```

The helper uses the upstream `--codex-device-login` flag so device-code login is the default path. This is the headless flow and does not use a local OAuth callback port.

The helper runs the OpenAI/Codex device flow inside the container and prints a verification URL plus a one-time code. Open that URL, enter the code, and complete the login in the browser account you want to authorize.

For a second account, run the same helper again and complete the verification flow with the other account.

Authorized credentials are persisted at `~/.cliproxy/auths/` on the host and survive container restarts.

Before each login, the helper also runs:

```bash
~/.cliproxy/prune-auths.sh
```

That cleanup removes invalid JSON files and expired auth files that no longer have a refresh token. Refreshable OAuth records are left alone because Codex/CLIProxy can refresh them automatically.

## Multi-account round-robin

This setup uses file-based account discovery instead of a manual `codex-api-key` list. Each successful OpenAI login creates or refreshes another auth file in `~/.cliproxy/auths/`. That directory is the account pool.

The tracked config template already enables:

```yaml
routing:
  strategy: 'round-robin'

max-retry-credentials: 0
max-retry-interval: 30
```

With two OpenAI accounts authorized, the proxy will rotate across both automatically when one account hits its usage window or a retry path needs another credential.

Useful auth cleanup commands:

```bash
# Preview removals without deleting anything
~/.cliproxy/prune-auths.sh --dry-run

# Remove invalid JSON and expired non-refreshable auth files
~/.cliproxy/prune-auths.sh

# Aggressively remove every auth file whose stored expiry is already in the past
~/.cliproxy/prune-auths.sh --force-expired
```

Use `--force-expired` only when you intentionally want to reseed the account pool from fresh logins.

## Client setup

### Amp

Point Amp at the local proxy instead of the upstream API:

Amp talks to the proxy root URL, so this example uses `http://localhost:8317` without `/v1`. Amp still expects an API-key-shaped value, but on the default localhost-only setup that value is just a placeholder.

```bash
export AMP_API_BASE_URL="http://localhost:8317"
export AMP_API_KEY="dummy-not-used"
```

Add those exports to your shell profile for interactive use. For headless or VM agent loops, set them in the service or container environment that runs Amp.

### opencode

Add a custom provider in `~/.config/opencode/opencode.json`:

`opencode`, Factory, and `oh-my-pi` use the OpenAI-compatible endpoint, so their examples point at `http://localhost:8317/v1`. For clients that require an API key field, use a dummy placeholder unless you have explicitly enabled proxy `api-keys`.

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "cliproxy": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "CLIProxy",
      "options": {
        "baseURL": "http://localhost:8317/v1",
        "apiKey": "dummy-not-used"
      },
      "models": {
        "gpt-5": { "name": "GPT-5" }
      }
    }
  },
  "model": "cliproxy/gpt-5"
}
```

If your opencode version fails to forward custom provider options and returns `404`, set these env vars instead and use the built-in OpenAI provider:

```bash
export OPENAI_BASE_URL="http://localhost:8317/v1"
export OPENAI_API_KEY="dummy-not-used"
```

### Factory

Set the API endpoint in your Factory workspace settings or `~/.factory/config.yaml`:

```yaml
api:
  base_url: "http://localhost:8317/v1"
  api_key: "dummy-not-used"
  model: "gpt-5"
```

Keep shared, non-secret defaults in tracked `factory/settings.json` when they belong to the repo. Put machine-specific proxy endpoints and other local settings in local Factory config or workspace settings instead.

### Oh My Pi

Track shared `oh-my-pi` defaults in `omp/agent/` and link them with `./install.sh -p omp`.

- `./install.sh -p omp` now links the full `omp/` package to `~/.omp/`.
- Ignored local databases, sessions, logs, and cache now live inside the repo-backed `omp/` directory.
- Tracked files such as `omp/agent/config.yml`, `omp/agent/models.yml`, and `omp/agent/themes/` stay global, so repo edits propagate across machines after a pull.
- The tracked `omp/agent/models.yml` now uses `auth: none`, so OMP talks to the localhost proxy without any proxy-secret environment variable by default.

If you deliberately enable proxy `api-keys` later, keep the existing `models:` list unchanged and replace `auth: none` in `~/.omp/agent/models.yml` with:

```yaml
apiKey: CLIPROXY_API_KEY
authHeader: true
```

That local override is required because upstream OMP only supports env-name-or-literal semantics for `apiKey`; file-path references such as `~/.cliproxy/config.yaml` are not supported.

## Optional proxy access token

The default posture is: no separate client auth, loopback-only exposure, upstream OAuth stored in `~/.cliproxy/auths/`. That is enough for a single-user local machine.

If you still want a client access token on top of localhost binding, set it explicitly in `~/.cliproxy/config.yaml`:

```yaml
api-keys:
  - 'choose-a-local-proxy-token'
```

Then configure clients with that same token instead of `dummy-not-used`. For OMP, use the local `apiKey` + `authHeader: true` override shown above.

The tracked runtime is local-only by default and binds to `127.0.0.1`. If you later want LAN access from another machine, you must deliberately widen the bind in both `~/.cliproxy/config.yaml` and `~/.cliproxy/docker-compose.yml` before using a LAN IP.

## Troubleshooting

```bash
# Tail live logs
docker logs -f cli-proxy-api-plus

# Confirm the proxy is alive (no auth header needed on the default localhost-only setup)
curl http://localhost:8317/v1/models

# Restart
docker compose -f ~/.cliproxy/docker-compose.yml restart

# Full reset while keeping config and auths
docker compose -f ~/.cliproxy/docker-compose.yml down
docker compose -f ~/.cliproxy/docker-compose.yml up -d
```

If you enabled proxy `api-keys`, add the same bearer token to your curl requests and client config when testing.

## Repo layout

Tracked package roots live under `cliproxy/` and `omp/`:

```text
cliproxy/
|- .gitignore
|- config.yaml.example
|- docker-compose.yml
|- login-openai.sh
|- prune-auths.sh
|- update.sh
`- README.md

omp/
|- .gitignore
`- agent/
   |- config.yml
   |- models.yml
   `- themes/
```

Runtime state lives in ignored files inside `~/.cliproxy/` and `~/.omp/`, so it remains local to each machine even though the package roots are symlinked to the repo.