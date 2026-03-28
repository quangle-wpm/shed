---
name: commit-push
description: Use when changes are ready to commit and push directly to main without creating a branch or pull request
context: fork
model: sonnet
effort: medium
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git branch:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git stash:*), Bash(git restore:*), Bash(pre-commit run:*)
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Based on the above changes:

1. **Determine commit scope**:
   - If files are already staged, the scope is **exactly those staged files** — keep it locked, ignore untracked and unstaged files entirely.
   - If nothing is staged, all modified and new files become the scope.
2. **Review the diff of files in scope** and group them by distinct concern. Create a separate commit for each group — stage only that group's files, commit, then move to the next group.
3. Create each commit using Conventional Commits format:
   - `type(scope): description` — type is one of: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `ci`, `chore`, `revert`
   - Use lowercase imperative description (e.g. `add login page`)
   - Omit scope if it adds no clarity
   - Subject line must be 72 characters or fewer
   - Add body if changes are non-trivial
4. Push to origin main

Pre-commit hooks will run automatically. If they fail, fix the issues and retry — always let hooks run.

You have the capability to call multiple tools in a single response. Stage, commit, and push in a single message. Only use git tools and only output tool calls.
