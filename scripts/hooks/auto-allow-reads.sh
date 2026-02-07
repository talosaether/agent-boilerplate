#!/bin/bash
# auto-allow-reads.sh — PermissionRequest hook
# Auto-allows read-only tools and safe bash commands to reduce permission dialog friction.
# Universal: only allows operations that cannot modify state.

json=$(cat)

tool_name=$(echo "$json" | jq -r '.tool_name // empty')
command=$(echo "$json" | jq -r '.tool_input.command // empty')

# Read-only tools — always safe
case "$tool_name" in
  Read|Glob|Grep|WebSearch|WebFetch)
    echo '{"hookSpecificOutput":{"behavior":"allow"}}'
    exit 0
    ;;
esac

# Safe bash commands — read-only operations only
if [ "$tool_name" = "Bash" ] && [ -n "$command" ]; then
  # Reject anything with shell operators that could enable writes
  # (pipes to tee/dd, redirections, command substitution tricks, etc.)
  if echo "$command" | grep -qE '>\s|>>' ; then
    # Contains output redirection — not safe, let the normal permission flow handle it
    exit 0
  fi

  # Extract the base command (first word, ignoring env vars and flags)
  base_cmd=$(echo "$command" | sed 's/^[A-Z_]*=[^ ]* *//' | awk '{print $1}')

  # Safe read-only commands
  case "$base_cmd" in
    ls|cat|head|tail|wc|file|which|whoami|pwd|date|uname|env|printenv)
      echo '{"hookSpecificOutput":{"behavior":"allow"}}'
      exit 0
      ;;
    git)
      # Only allow read-only git subcommands
      git_subcmd=$(echo "$command" | grep -oP 'git\s+\K\S+')
      case "$git_subcmd" in
        status|log|diff|show|branch|tag|remote|stash\ list|rev-parse|describe|shortlog|blame)
          echo '{"hookSpecificOutput":{"behavior":"allow"}}'
          exit 0
          ;;
      esac
      ;;
    node|python|python3)
      # Only allow version checks
      if echo "$command" | grep -qE '^(node|python3?)\s+--version$'; then
        echo '{"hookSpecificOutput":{"behavior":"allow"}}'
        exit 0
      fi
      ;;
    gh)
      # Only allow read operations
      gh_subcmd=$(echo "$command" | grep -oP 'gh\s+\K\S+')
      case "$gh_subcmd" in
        pr\ view|pr\ list|issue\ view|issue\ list|api|repo\ view|run\ list|run\ view)
          echo '{"hookSpecificOutput":{"behavior":"allow"}}'
          exit 0
        ;;
      esac
      ;;
  esac
fi

# Everything else — defer to normal permission flow
exit 0
