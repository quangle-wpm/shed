---
name: commit-push
description: Use when changes are ready to commit and push directly to main without creating a branch or pull request
allowed-tools: Bash(git diff:*), Bash(git add:*), Bash(git status:*), Bash(git push:*), Bash(git commit:*)
disable-model-invocation: true
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Based on the above changes:

1. **Stage changes**: If files are already staged, commit only those. If nothing is staged, stage all modified and new files with `git add`.
2. **Review the diff** to determine if changes span multiple distinct concerns (different types, unrelated files). If so, stage and commit each concern separately rather than in one commit.
3. Create each commit using Conventional Commits format:
   - `type(scope): description` — type is one of: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `ci`, `chore`, `revert`
   - Use lowercase imperative description (e.g. `add login page`)
   - Omit scope if it adds no clarity
   - Subject line must be 72 characters or fewer
   - Add body if changes are non-trivial
4. Push to origin main

Pre-commit hooks will run automatically. If they fail, fix the issues and retry — do not use `--no-verify`.

You have the capability to call multiple tools in a single response. Stage, commit, and push in a single message. Do not use any other tools or do anything else. Do not send any other text or messages besides these tool calls.
