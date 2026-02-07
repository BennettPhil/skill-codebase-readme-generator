# API Reference

> Complete CLI interface documentation for `codebase-readme-generator`.

## Overview

`scripts/run.sh` scans a project directory and writes a generated README skeleton.
It infers language, build system, common directories, and starter commands.

## Command

### `run.sh`

**Description**: Generate README content for a project.

**Usage**:
```bash
./scripts/run.sh [OPTIONS] [PROJECT_DIR]
```

**Arguments**:
| Argument | Required | Description |
|----------|----------|-------------|
| `PROJECT_DIR` | No | Target directory to analyze (default: `.`). |

**Options**:
| Option | Default | Description |
|--------|---------|-------------|
| `--project <path>` | `.` | Target project directory. |
| `--output <path>` | `<project>/README.generated.md` | Output file path when not in dry run. |
| `--overwrite` | `false` | Allow replacing an existing output file. |
| `--title <text>` | Project folder name | Override generated H1 title. |
| `--description <text>` | Auto text | Override generated description paragraph. |
| `--include-tree <bool>` | `true` | Include a max-depth filesystem snapshot. |
| `--max-depth <n>` | `2` | Depth used for the snapshot (`n >= 1`). |
| `--config <path>` | Auto-detected | Load key-value config file. |
| `--dry-run` | `false` | Print README to stdout instead of writing a file. |
| `--help`, `-h` | n/a | Show usage help. |
| `--version` | n/a | Print tool version. |

**Exit Codes**:
| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | General runtime error |
| `2` | Invalid arguments or option values |
| `3` | Target project directory does not exist |
| `4` | Output file already exists and `--overwrite` is not set |

## Output Behavior

- `--dry-run`: Writes generated markdown to stdout only.
- Without `--dry-run`: Writes to `--output` (or default path).
- Generated content includes:
1. Project title and summary
2. Inferred language/build-system overview
3. Common directory and key-file inventory
4. Starter install/build/test/run command suggestions

## Detection Heuristics

- **Language**: inferred from files like `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`.
- **Build system**: inferred from lockfiles and build manifests.
- **Node scripts**: if `jq` is installed, `package.json` scripts refine suggested commands.

## Cross-References

- See `references/usage-guide.md` for task-oriented walkthroughs.
- See `references/configuration.md` for precedence and config keys.
- See `references/examples.md` for concrete copy-paste scenarios.
