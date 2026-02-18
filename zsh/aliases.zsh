# basic Commands
alias ll="ls -la"

# git
alias lg="lazygit"
alias g="git"
alias gs="git status"

# misc
alias updateZsh="source ~/.zshrc"

alias cc="claude --dangerously-skip-permissions"

_opencode_fallback_theme() {
  if [[ -n "${OPENCODE_THEME_FALLBACK:-}" ]]; then
    printf '%s\n' "$OPENCODE_THEME_FALLBACK"
    return 0
  fi

  printf '%s\n' "system"
}

_opencode_tmux_fallback_theme() {
  if [[ -z "${TMUX:-}" ]]; then
    return 1
  fi

  local tmux_env
  tmux_env="$(tmux show-environment -g OPENCODE_THEME_FALLBACK 2>/dev/null || true)"

  if [[ "$tmux_env" == OPENCODE_THEME_FALLBACK=* ]]; then
    printf '%s\n' "${tmux_env#OPENCODE_THEME_FALLBACK=}"
    return 0
  fi

  return 1
}

opencode() {
  local fallback_theme="${OPENCODE_THEME_FALLBACK:-}"

  if [[ -n "${TMUX:-}" && -z "$fallback_theme" ]]; then
    fallback_theme="$(_opencode_tmux_fallback_theme)"
  fi

  if [[ -n "${TMUX:-}" ]]; then
    if [[ -z "$fallback_theme" ]]; then
      fallback_theme="system"
    fi

    OPENCODE_CONFIG_CONTENT="{\"theme\":\"${fallback_theme}\"}" command opencode "$@"
    return
  fi

  command opencode "$@"
}

ocssh() {
  if (( $# < 1 )); then
    echo "Usage: ocssh <ssh-target>"
    return 1
  fi

  local ssh_target="$1"
  local fallback_theme
  fallback_theme="$(_opencode_fallback_theme)"
  local fallback_theme_quoted
  fallback_theme_quoted="${(q)fallback_theme}"

  command ssh -t "$ssh_target" "export OPENCODE_THEME_FALLBACK=$fallback_theme_quoted; tmux set-environment -g OPENCODE_THEME_FALLBACK $fallback_theme_quoted 2>/dev/null || true; exec \$SHELL -l"
}

claudedev() {
     if [ "$1" = "zai" ]; then
        export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
        export ANTHROPIC_AUTH_TOKEN=$ANTHROPIC_AUTH_TOKEN_OG
        echo "Switched to Claude Profile 2 (API)"
        source ~/.zshrc
        echo $ANTHROPIC_BASE_URL
        echo $ANTHROPIC_AUTH_TOKEN
        claude
     elif [ "$1" = "kimi" ]; then
        export ANTHROPIC_BASE_URL=https://api.moonshot.ai/anthropic
        export ANTHROPIC_AUTH_TOKEN=redacted
        export ANTHROPIC_MODEL=kimi-k2-thinking
        export ANTHROPIC_SMALL_FAST_MODEL=kimi-latest
        echo "Switched to kimi (API)"
        source ~/.zshrc
        echo $ANTHROPIC_BASE_URL
        echo $ANTHROPIC_AUTH_TOKEN
        claude
      elif [ "$1" = "mm" ]; then
        export ANTHROPIC_BASE_URL="https://api.minimax.io/anthropic"
        export ANTHROPIC_AUTH_TOKEN=$MINIMX_API_KEY
        export ANTHROPIC_MODEL="MiniMax-M2"
        export ANTHROPIC_SMALL_FAST_MODEL="MiniMax-M2"  # Same model
        export API_TIMEOUT_MS=3000000
        echo "Switched to minimax-m2 (Subscription)"
        echo $ANTHROPIC_BASE_URL
        echo $ANTHROPIC_AUTH_TOKEN
        source ~/.zshrc
        claude
    else
        export ANTHROPIC_BASE_URL=""
        export ANTHROPIC_AUTH_TOKEN=""
        export ANTHROPIC_CUSTOM_HEADERS=""
        export ANTHROPIC_MODEL=""
        export ANTHROPIC_SMALL_FAST_MODEL=""  # Same model
        export API_TIMEOUT_MS=""
        echo "Switched to Claude Profile 1 (Subscription)"
        source ~/.zshrc
        echo $ANTHROPIC_BASE_URL
        echo $ANTHROPIC_AUTH_TOKEN
        claude
    fi
}

#tmux dev
fdev() {
  local session="fdev"

  # Kill any existing session
  tmux kill-session -t "$session" 2>/dev/null

  # Create attached session and build layout in one tmux command
  tmux new-session -s "$session" \; \
    split-window -h \; \
    split-window -h \; \
    split-window -h \; \
    select-pane -t 0 \; \
    split-window -v \; \
    send-keys -t 0 "echo 'start'" C-m \; \
    send-keys -t 1 "echo 'start'" C-m \; \
    send-keys -t 2 "echo 'start'" C-m \; \
    send-keys -t 3 "echo 'start'" C-m \; \
    select-pane -t 0
}
dev() {
  local session="dev"
  local editor="${2:-nvim}"

  # Kill any existing sessions
  tmux kill-session -t "$session" 2>/dev/null
  tmux kill-session -t "agents" 2>/dev/null

  # Create dev session with panes
  tmux new-session -s "$session" \; \
    split-window -h -p 20 \; \
    split-window -v -p 20 -t 0 \; \
    split-window -h -p 50 -t 1 \; \
    send-keys -t 0 "$editor ." C-m \; \
    send-keys -t 1 "echo 'ready'" C-m \; \
    send-keys -t 2 "echo 'ready'" C-m \; \
    send-keys -t 3 "claudedev" C-m \; \
    select-pane -t 0 \; \
    new-window -n "agents" \; \
    split-window -h \; \
    split-window -h \; \
    split-window -h -t 0 \; \
    send-keys -t 0 "echo 'start'" C-m \; \
    send-keys -t 1 "echo 'start'" C-m \; \
    send-keys -t 2 "echo 'start'" C-m \; \
    send-keys -t 3 "echo 'start'" C-m \; \
    select-pane -t 0
}
tkill() {
  local target="${1:-dev}"   # default to "dev" if no arg given
  tmux kill-session -t "$target" 2>/dev/null
}

tmux_opencode_layout() {
  local pane_count="${1:-6}"
  local session="agent${pane_count}"

  if [[ "$pane_count" != "5" && "$pane_count" != "6" ]]; then
    echo "Usage: tmux_opencode_layout [5|6]"
    return 1
  fi

  tmux kill-session -t "$session" 2>/dev/null
  tmux new-session -d -s "$session" -c "$PWD"

  local fallback_theme
  fallback_theme="$(_opencode_fallback_theme)"

  if [[ -z "$fallback_theme" ]]; then
    fallback_theme="system"
  fi

  local opencode_config_content
  opencode_config_content="{\"theme\":\"${fallback_theme}\"}"
  local term_for_opencode
  term_for_opencode="tmux-256color"
  local opentui_no_graphics
  opentui_no_graphics="1"
  local opencode_disable_terminal_title
  opencode_disable_terminal_title="1"
  local opencode_force_explicit_width
  opencode_force_explicit_width="0"
  local opencode_startup_settle_seconds
  opencode_startup_settle_seconds="3"
  local term_program
  term_program="tmux"
  local term_program_version
  term_program_version="0"
  local tmux_version_output
  tmux_version_output="$(tmux -V 2>/dev/null || true)"
  if [[ "$tmux_version_output" == tmux\ * ]]; then
    term_program_version="${tmux_version_output#tmux }"
  fi

  tmux set-environment -t "$session" OPENCODE_THEME_FALLBACK "$fallback_theme"
  tmux set-environment -t "$session" OPENCODE_CONFIG_CONTENT "$opencode_config_content"
  tmux set-environment -t "$session" TERM "$term_for_opencode"
  tmux set-environment -t "$session" TERM_PROGRAM "$term_program"
  tmux set-environment -t "$session" TERM_PROGRAM_VERSION "$term_program_version"
  tmux set-environment -t "$session" OPENTUI_NO_GRAPHICS "$opentui_no_graphics"
  tmux set-environment -t "$session" OPENTUI_FORCE_EXPLICIT_WIDTH "$opencode_force_explicit_width"
  tmux set-environment -t "$session" OPENCODE_DISABLE_TERMINAL_TITLE "$opencode_disable_terminal_title"

  local i
  for ((i = 1; i < pane_count; i++)); do
    tmux split-window -t "$session":0 -c "$PWD"
    tmux select-layout -t "$session":0 tiled
  done

  (
    sleep 0.4

    for i in 0 1 2 3; do
      tmux select-pane -t "$session":0."$i"
      tmux respawn-pane -k -t "$session":0."$i" "command opencode ."
      sleep "$opencode_startup_settle_seconds"
    done

    tmux select-pane -t "$session":0.0
  ) &

  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$session"
  else
    tmux attach-session -t "$session"
  fi
}

tmux_nvim_lazygit_layout() {
  local session="nvlg"

  tmux kill-session -t "$session" 2>/dev/null
  tmux new-session -d -s "$session" -c "$PWD"
  tmux split-window -h -t "$session":0 -c "$PWD"
  tmux send-keys -t "$session":0.0 "nvim ." C-m
  tmux send-keys -t "$session":0.1 "lazygit" C-m
  tmux select-pane -t "$session":0.0

  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$session"
  else
    tmux attach-session -t "$session"
  fi
}

alias o5="tmux_opencode_layout 5"
alias o6="tmux_opencode_layout 6"
alias agent5="tmux_opencode_layout 5"
alias agent6="tmux_opencode_layout 6"
alias nvlg="tmux_nvim_lazygit_layout"
