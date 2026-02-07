# Configuration

> All configuration inputs and precedence rules for `codebase-readme-generator`.

## Overview

The tool accepts settings from command-line flags, environment variables, and an
optional config file. Precedence is deterministic so runs are predictable.

## Precedence

Configuration is resolved in this order (highest first):

1. Command-line arguments
2. Environment variables
3. Config file
4. Built-in defaults

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `README_GEN_PROJECT` | `.` | Target project directory. |
| `README_GEN_OUTPUT` | `<project>/README.generated.md` | Output path in write mode. |
| `README_GEN_OVERWRITE` | `false` | Whether existing output may be replaced. |
| `README_GEN_TITLE` | Folder name | Override README H1 title. |
| `README_GEN_DESCRIPTION` | Auto text | Override README summary paragraph. |
| `README_GEN_INCLUDE_TREE` | `true` | Include filesystem snapshot section. |
| `README_GEN_MAX_DEPTH` | `2` | Depth used for snapshot generation. |
| `README_GEN_CONFIG` | unset | Explicit config file path. |

Boolean variables accept: `true`, `false`, `1`, `0`, `yes`, `no`.

## Config File

Default discovery:

- If `--config` is set, use that file.
- Else if `README_GEN_CONFIG` is set, use that file.
- Else if `<project>/.readme-generator.conf` exists, use it.

Format: `key=value` pairs, one per line. Lines beginning with `#` are comments.

Example:
```ini
project=.
output=README.generated.md
overwrite=false
title=My Service
description=Internal API service for billing workflows.
include_tree=true
max_depth=2
```

## Options Reference

### `project`

- **Type**: string
- **Default**: `.`
- **Env**: `README_GEN_PROJECT`
- **Flag**: `--project`
- **Description**: Path to the project analyzed for README generation.

### `output`

- **Type**: string
- **Default**: `<project>/README.generated.md`
- **Env**: `README_GEN_OUTPUT`
- **Flag**: `--output`
- **Description**: Destination file path in non-dry-run mode.

### `overwrite`

- **Type**: boolean
- **Default**: `false`
- **Env**: `README_GEN_OVERWRITE`
- **Flag**: `--overwrite`
- **Description**: Allow replacing an existing output file.

### `title`

- **Type**: string
- **Default**: project folder name
- **Env**: `README_GEN_TITLE`
- **Flag**: `--title`
- **Description**: Override generated README title.

### `description`

- **Type**: string
- **Default**: generated summary text
- **Env**: `README_GEN_DESCRIPTION`
- **Flag**: `--description`
- **Description**: Override generated introductory description.

### `include_tree`

- **Type**: boolean
- **Default**: `true`
- **Env**: `README_GEN_INCLUDE_TREE`
- **Flag**: `--include-tree`
- **Description**: Include or omit filesystem snapshot section.

### `max_depth`

- **Type**: positive integer
- **Default**: `2`
- **Env**: `README_GEN_MAX_DEPTH`
- **Flag**: `--max-depth`
- **Description**: Depth for `find`-based project snapshot.

## Cross-References

- API contract: `references/api.md`
- Example configs in context: `references/examples.md`
