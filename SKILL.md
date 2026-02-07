---
name: codebase-readme-generator
description: Generate a structured README.md by detecting language, build system, and project layout.
version: 0.1.0
license: Apache-2.0
---

# Codebase README Generator

## Purpose
`codebase-readme-generator` scans a project directory and produces a ready-to-edit
`README.md` skeleton with inferred language, build workflow, and project structure.

## Quick Start
```bash
cd .soup/skills/codebase-readme-generator
chmod +x scripts/run.sh
./scripts/run.sh --project /path/to/project --dry-run
./scripts/run.sh --project /path/to/project --output README.generated.md --overwrite
```

## Reference Index
- `references/api.md` - Full CLI contract, flags, arguments, and exit codes.
- `references/usage-guide.md` - End-to-end walkthrough from first run to customization.
- `references/configuration.md` - Config keys, environment variables, and precedence.
- `references/examples.md` - Copy-paste examples, including edge and error scenarios.
- `references/architecture.md` - Internal flow and detection heuristics.

## Implementation
The implementation lives in `scripts/run.sh` and follows the contract documented in
the reference files.