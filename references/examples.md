# Examples

> Copy-paste-ready examples for common `codebase-readme-generator` workflows.

## Basic Usage

### Preview README without writing a file

```bash
./scripts/run.sh --project ~/work/my-service --dry-run
```

Output (truncated):
```text
# my-service
...
## Getting Started
```

### Generate README next to the project

```bash
./scripts/run.sh --project ~/work/my-service
```

Output:
```text
README generated at ~/work/my-service/README.generated.md
```

## Customization

### Override title and description

```bash
./scripts/run.sh \
  --project ~/work/my-service \
  --title "My Service" \
  --description "My Service powers internal workflows." \
  --overwrite
```

### Disable project snapshot

```bash
./scripts/run.sh --project ~/work/my-service --include-tree false --overwrite
```

### Reduce snapshot noise with depth=1

```bash
./scripts/run.sh --project ~/work/my-service --max-depth 1 --overwrite
```

## Config-Driven Usage

### Use project-local config

`~/work/my-service/.readme-generator.conf`
```ini
title=My Service
include_tree=true
max_depth=2
```

Command:
```bash
./scripts/run.sh --project ~/work/my-service --overwrite
```

### Use explicit config path

```bash
./scripts/run.sh --config ~/profiles/readme-generator.conf --overwrite
```

## Error Handling

### Existing output without overwrite

```bash
./scripts/run.sh --project ~/work/my-service --output README.md
```

Output:
```text
Output file already exists: README.md
```

Resolution: rerun with `--overwrite` or select another `--output`.

### Invalid max depth

```bash
./scripts/run.sh --project ~/work/my-service --max-depth 0
```

Output:
```text
Invalid value for --max-depth: 0
```

Resolution: use a positive integer such as `1` or `2`.
