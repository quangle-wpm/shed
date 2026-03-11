---
paths:
  - "scripts/windows/**"
  - "templates/windows.ps1"
---

- Header: `#Requires -Version 5.1`, `Set-StrictMode -Version Latest`, `$ErrorActionPreference = 'Stop'`
- Named `kebab-case.ps1`
- Entry point: `Main` function
- Not linted automatically (PSScriptAnalyzer unavailable on Linux)
