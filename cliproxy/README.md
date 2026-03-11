# CLIProxy OpenAI Setup

This package stores the shared dotfiles for a local `CLIProxyAPIPlus` runtime.

Use the main dotfiles installer to set it up:

```bash
./install.sh -p cliproxy
```

That command links the full `cliproxy/` package to `~/.cliproxy/` and reconciles ignored local files such as `config.yaml`, `auths/`, and `logs/` inside the repo-backed directory.

The default runtime follows the VibeProxy pattern:

- the proxy stays bound to localhost through `docker-compose.yml`
- `api-keys` are empty by default, so local clients do not need a separate proxy token
- upstream ChatGPT/Codex OAuth stays in `~/.cliproxy/auths/`
- `round-robin` routing rotates across every authorized account
- `~/.cliproxy/prune-auths.sh` removes invalid or expired non-refreshable auth files before login

After linking, authorize each OpenAI account with:

```bash
~/.cliproxy/login-openai.sh
```

If you later want client auth anyway, add one or more values under `api-keys` in `~/.cliproxy/config.yaml` and configure each client with the same bearer token locally.