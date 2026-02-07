#!/bin/bash
# path-protector.sh — PreToolUse hook for Edit|Write
# Denies writes to sensitive files (secrets, credentials, production config).
# Universal: works for any project. Add project-specific paths to the array.

json=$(cat)
file_path=$(echo "$json" | jq -r '.tool_input.file_path // empty')

if [ -z "$file_path" ]; then
  exit 0
fi

# Normalize: strip leading ./ if present
file_path="${file_path#./}"

# Protected path patterns (glob-style matching)
protected_patterns=(
  ".env"
  ".env.*"
  "*.secret"
  "*.pem"
  "*.key"
  "credentials/*"
  "config/production/*"
  "**/secrets/*"
  ".claude/settings.json"
)

for pattern in "${protected_patterns[@]}"; do
  # Use bash extended globbing for matching
  if [[ "$file_path" == $pattern ]]; then
    reason="Blocked by path protector: '$file_path' matches protected pattern '$pattern'"
    echo "{\"hookSpecificOutput\":{\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$reason\"}}"
    exit 0
  fi
done

# Allow everything else
exit 0
