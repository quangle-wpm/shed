---
name: new-script
description: Create a new script from template. Usage: /new-script <linux|windows> <category/slug> (e.g. /new-script linux utils/my-tool or /new-script windows setup/install-foo)
disable-model-invocation: false
---

Usage: `/new-script <linux|windows> <category/slug>`

Examples:

- `/new-script linux utils/my-tool`
- `/new-script windows setup/install-foo`

Steps:

1. Copy the relevant template:
   - Linux: `cp templates/linux.sh scripts/linux/<category>/<slug>.sh`
   - Windows: `cp templates/windows.ps1 scripts/windows/<category>/<slug>.ps1`
2. For Linux only: `chmod +x scripts/linux/<category>/<slug>.sh`
3. Open the new file and fill in the description and body sections
4. Validate:
   - Linux: `shellcheck scripts/linux/<category>/<slug>.sh`
   - Windows: `pwsh -Command "Invoke-ScriptAnalyzer -Path scripts/windows/<category>/<slug>.ps1 -EnableExit"`
