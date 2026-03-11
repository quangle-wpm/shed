---
name: commit-push
description: Use when changes are ready to commit and push directly to main without creating a branch or pull request
allowed-tools: Bash(git diff:*), Bash(git add:*), Bash(git status:*), Bash(git push:*), Bash(git commit:*)
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Based on the above changes:

1. Stage all relevant changes
2. Create a single commit using Conventional Commits format:
    - `type(scope): description` — type is one of: `feat`, `fix`, `docs`,
      `style`, `refactor`, `test`, `chore`
    - Use lowercase imperative description (e.g. `add login page`)
    - Omit scope if it adds no clarity
    - Add body if changes are non-trivial
3. Push to origin main

You have the capability to call multiple tools in a single response.
Stage, commit, and push in a single message. Do not use any other tools
or do anything else. Do not send any other text or messages besides
these tool calls.
