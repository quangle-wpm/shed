---
paths:
    - "scripts/linux/**"
    - "templates/linux.sh"
---

- Shebang: `#!/usr/bin/env bash`, strict mode: `set -euo pipefail`
- Named `kebab-case.sh`, executable bit tracked in git (`chmod +x`)
- Entry point: `main()` called as `main "$@"`
