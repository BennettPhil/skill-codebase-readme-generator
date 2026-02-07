# Usage Guide

> Step-by-step guide to generating and customizing README scaffolds.

## Overview

This guide covers the common workflow from first run to repeatable configuration.
Use it when you need a fast README baseline that still leaves room for editing.

## Prerequisites

- `bash` and standard Unix shell tools
- Access to the target project directory
- Optional: `jq` for better Node script detection

## Getting Started

### Step 1: Run a preview

```bash
./scripts/run.sh --project /path/to/project --dry-run
```

Expected output:
```text
# <project-name>
...
## Getting Started
```

### Step 2: Write to a file

```bash
./scripts/run.sh --project /path/to/project --output /path/to/project/README.generated.md
```

Expected output:
```text
README generated at /path/to/project/README.generated.md
```

### Step 3: Override title and description

```bash
./scripts/run.sh \
  --project /path/to/project \
  --title "Project Atlas" \
  --description "Atlas is an internal automation service." \
  --overwrite
```

Expected output:
```text
README generated at /path/to/project/README.generated.md
```

## Common Tasks

### Generate without tree snapshot

```bash
./scripts/run.sh --project /path/to/project --include-tree false --overwrite
```

### Reduce snapshot depth

```bash
./scripts/run.sh --project /path/to/project --max-depth 1 --overwrite
```

### Use a config file for repeat runs

```bash
./scripts/run.sh --config /path/to/project/.readme-generator.conf --overwrite
```

## Troubleshooting

### Output already exists

**Symptom**: Exit code `4` and message about existing output file.  
**Cause**: `--overwrite` was not set.  
**Fix**: Add `--overwrite` or choose a new `--output`.

### Invalid boolean value

**Symptom**: Exit code `2` with invalid boolean error.  
**Cause**: `--include-tree` or env/config value was not true/false style.  
**Fix**: Use `true|false|1|0|yes|no`.

### Target directory not found

**Symptom**: Exit code `3`.  
**Cause**: `PROJECT_DIR` path is wrong or inaccessible.  
**Fix**: Verify path and permissions, then rerun.

## Cross-References

- API details: `references/api.md`
- Config precedence: `references/configuration.md`
- Ready-to-copy commands: `references/examples.md`
