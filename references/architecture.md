# Architecture

> Internal structure and data flow for `codebase-readme-generator`.

## Overview

The implementation is a single `bash` script with modular functions. It follows
documentation-driven design: CLI contract and precedence rules are defined first,
then implemented in a deterministic pipeline.

## Data Flow

```text
args/env/config
    |
    v
resolve precedence
    |
    v
validate inputs
    |
    v
detect project traits
  (language, build system, scripts, structure)
    |
    v
render markdown sections
    |
    v
stdout (--dry-run) or output file
```

## Major Components

### Input Resolution

- Two-pass argument scan to locate project/config early.
- Config file load (`key=value`) with comment support.
- Environment overlay.
- Final CLI parse with highest precedence.

### Detection Layer

- Manifest-based language and build system inference.
- Optional `jq` parsing for Node `package.json` scripts.
- Common directory and key-file inventory.
- `find`-based project snapshot with ignore filters.

### Rendering Layer

- Emits stable README sections in markdown.
- Uses defaults when no language/build hints are found.
- Produces actionable starter commands for common ecosystems.

## Design Trade-Offs

- **Single script** keeps portability high and setup minimal.
- **Heuristic detection** is fast, but should be reviewed by users.
- **Generated README** is intentionally a scaffold, not final docs.

## Cross-References

- CLI definition: `references/api.md`
- Config model: `references/configuration.md`
