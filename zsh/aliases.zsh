# basic Commands
alias ll="ls -la"

# git
alias lg="lazygit"
alias g="git"
alias gs="git status"

# misc
alias updateZsh="source ~/.zshrc"

#tmux dev
fdev() {
  local session="fdev"
  local cmd="${1:-npm run dev}"
  local editor="${2:-nvim}"

  # Kill any existing session
  tmux kill-session -t "$session" 2>/dev/null

  # Create attached session and build layout in one tmux command
  tmux new-session -s "$session" \; \
    split-window -h -p 20 \; \
    split-window -v -p 20 -t 0 \; \
    split-window -h -p 50 -t 1 \; \
    send-keys -t 0 "$editor ." C-m \; \
    send-keys -t 1 "$cmd" C-m \; \
    send-keys -t 2 "echo 'ready'" C-m \; \
    send-keys -t 3 "claude" C-m \; \
    select-pane -t 0
}
dev() {
  local session="dev"
  local editor="${2:-nvim}"

  # Kill any existing session
  tmux kill-session -t "$session" 2>/dev/null

  # Create attached session and build layout in one tmux command
  tmux new-session -s "$session" \; \
    split-window -h -p 20 \; \
    split-window -v -p 20 -t 0 \; \
    split-window -h -p 50 -t 1 \; \
    send-keys -t 0 "$editor ." C-m \; \
    send-keys -t 1 "echo 'ready'" C-m \; \
    send-keys -t 2 "echo 'ready'" C-m \; \
    send-keys -t 3 "claude" C-m \; \
    select-pane -t 0
}
tkill() {
  local target="${1:-dev}"   # default to "dev" if no arg given
  tmux kill-session -t "$target" 2>/dev/null
}
