#!/bin/bash
# security-gate.sh — PreToolUse hook for Bash
# Blocks known-dangerous command patterns before execution.
# Universal: works for any project without customization.

json=$(cat)
command=$(echo "$json" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
  exit 0
fi

# Dangerous patterns — exact substrings matched against the command
dangerous_patterns=(
  "rm -rf /"
  "rm -rf ~"
  "rm -rf ."
  "chmod 777"
  "chmod -R 777"
  "> /dev/sda"
  "> /dev/null"
  "mkfs."
  ":(){:|:&};:"
  "dd if=/dev"
  "wget -O - | sh"
  "curl.*| sh"
  "curl.*| bash"
  "git push --force origin main"
  "git push --force origin master"
  "git reset --hard"
  "git clean -fdx"
)

for pattern in "${dangerous_patterns[@]}"; do
  if [[ "$command" == *"$pattern"* ]]; then
    reason="Blocked by security gate: matches dangerous pattern '$pattern'"
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$reason\"}}"
    exit 0
  fi
done

# Dangerous regex patterns — for commands that need flexible matching
dangerous_regex=(
  # find command abuse: -exec/-execdir can run arbitrary commands
  'find\s+.*-exec\b'
  'find\s+.*-execdir\b'
  # find -fprintf can write arbitrary content to any path
  'find\s+.*-fprintf\b'
  # find -delete can remove files with find's privileges
  'find\s+.*-delete\b'
)

for pattern in "${dangerous_regex[@]}"; do
  if echo "$command" | grep -qE "$pattern"; then
    reason="Blocked by security gate: matches dangerous pattern '$pattern'. If you need to search for files, use the Glob tool instead."
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$reason\"}}"
    exit 0
  fi
done

# Allow everything else
exit 0
