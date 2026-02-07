---
description: Interactive staged git commit workflow
---

# Commit Skill

Create a well-formed git commit interactively.

## Steps

1. Run `git status` to show current working tree state
2. Run `git diff` (staged and unstaged) to understand all changes
3. Show the user a summary of changes grouped by file
4. Ask the user which files to stage (or confirm staging all)
5. Stage the selected files with `git add`
6. Draft a conventional commit message based on the changes:
   - Format: `type(scope): description`
   - Types: feat, fix, docs, style, refactor, test, chore, ci
   - Focus on *why* the change was made, not *what* changed
7. Show the draft message and ask for confirmation or edits
8. Create the commit
9. Show `git log --oneline -3` to confirm

## Rules

- Never stage `.env`, credentials, or secret files
- Never use `--no-verify` unless the user explicitly requests it
- Always show the user what will be committed before committing
- Use `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` trailer
