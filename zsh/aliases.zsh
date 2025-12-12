# basic Commands
alias ll="ls -la"

# git
alias lg="lazygit"
alias g="git"
alias gs="git status"

# misc
alias updateZsh="source ~/.zshrc"

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
