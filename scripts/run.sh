#!/usr/bin/env bash
set -euo pipefail

VERSION="0.1.0"

die() {
  printf '%s\n' "$1" >&2
  exit "${2:-1}"
}

print_help() {
  cat <<'EOF'
Usage:
  ./scripts/run.sh [OPTIONS] [PROJECT_DIR]

Options:
  --project <path>        Target project directory (default: .)
  --output <path>         Output file path (default: <project>/README.generated.md)
  --overwrite             Allow replacing an existing output file
  --title <text>          Override generated README title
  --description <text>    Override generated README description
  --include-tree <bool>   Include filesystem snapshot (true/false, default: true)
  --max-depth <n>         Snapshot depth (positive integer, default: 2)
  --config <path>         Config file path (key=value format)
  --dry-run               Print markdown to stdout only
  --help, -h              Show this help message
  --version               Show version
EOF
}

trim() {
  printf '%s' "$1" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g'
}

to_bool() {
  local v
  v="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$v" in
    true|1|yes|y) printf 'true' ;;
    false|0|no|n) printf 'false' ;;
    *) return 1 ;;
  esac
}

is_positive_int() {
  printf '%s' "$1" | grep -Eq '^[1-9][0-9]*$'
}

load_config_file() {
  local file="$1"
  [ -n "$file" ] || return 0
  [ -f "$file" ] || die "Config file not found: $file" 2

  while IFS= read -r raw || [ -n "$raw" ]; do
    local line key value
    line="${raw%%#*}"
    line="$(trim "$line")"
    [ -n "$line" ] || continue
    key="$(trim "${line%%=*}")"
    value="$(trim "${line#*=}")"

    case "$key" in
      project) PROJECT_DIR="$value" ;;
      output) OUTPUT="$value" ;;
      overwrite) OVERWRITE="$(to_bool "$value")" || die "Invalid overwrite in config: $value" 2 ;;
      title) TITLE="$value" ;;
      description) DESCRIPTION="$value" ;;
      include_tree) INCLUDE_TREE="$(to_bool "$value")" || die "Invalid include_tree in config: $value" 2 ;;
      max_depth)
        is_positive_int "$value" || die "Invalid max_depth in config: $value" 2
        MAX_DEPTH="$value"
        ;;
      *) ;;
    esac
  done < "$file"
}

detect_language() {
  local p="$1"
  if [ -f "$p/package.json" ]; then
    if ls "$p"/tsconfig*.json >/dev/null 2>&1; then
      printf 'TypeScript'
    else
      printf 'JavaScript'
    fi
  elif [ -f "$p/pyproject.toml" ] || [ -f "$p/requirements.txt" ] || [ -f "$p/setup.py" ]; then
    printf 'Python'
  elif [ -f "$p/Cargo.toml" ]; then
    printf 'Rust'
  elif [ -f "$p/go.mod" ]; then
    printf 'Go'
  elif [ -f "$p/pom.xml" ] || [ -f "$p/build.gradle" ] || [ -f "$p/build.gradle.kts" ]; then
    printf 'Java/Kotlin'
  elif [ -f "$p/Gemfile" ]; then
    printf 'Ruby'
  elif [ -f "$p/composer.json" ]; then
    printf 'PHP'
  elif ls "$p"/*.csproj >/dev/null 2>&1; then
    printf '.NET'
  else
    printf 'Unknown'
  fi
}

detect_build_system() {
  local p="$1"
  if [ -f "$p/pnpm-lock.yaml" ]; then
    printf 'pnpm'
  elif [ -f "$p/yarn.lock" ]; then
    printf 'yarn'
  elif [ -f "$p/package-lock.json" ]; then
    printf 'npm'
  elif [ -f "$p/package.json" ]; then
    printf 'npm-compatible'
  elif [ -f "$p/pyproject.toml" ]; then
    if grep -qi 'poetry' "$p/pyproject.toml"; then
      printf 'poetry'
    else
      printf 'pip/pyproject'
    fi
  elif [ -f "$p/requirements.txt" ]; then
    printf 'pip'
  elif [ -f "$p/Cargo.toml" ]; then
    printf 'cargo'
  elif [ -f "$p/go.mod" ]; then
    printf 'go modules'
  elif [ -f "$p/pom.xml" ]; then
    printf 'maven'
  elif [ -f "$p/build.gradle" ] || [ -f "$p/build.gradle.kts" ]; then
    printf 'gradle'
  elif [ -f "$p/Gemfile" ]; then
    printf 'bundler'
  else
    printf 'unknown'
  fi
}

detect_commands() {
  local p="$1"
  local bs="$2"

  INSTALL_CMD="TODO: add install command"
  BUILD_CMD="TODO: add build command"
  TEST_CMD="TODO: add test command"
  RUN_CMD="TODO: add run command"

  case "$bs" in
    pnpm)
      INSTALL_CMD="pnpm install"
      BUILD_CMD="pnpm build"
      TEST_CMD="pnpm test"
      RUN_CMD="pnpm start"
      ;;
    yarn)
      INSTALL_CMD="yarn install"
      BUILD_CMD="yarn build"
      TEST_CMD="yarn test"
      RUN_CMD="yarn start"
      ;;
    npm|npm-compatible)
      INSTALL_CMD="npm install"
      BUILD_CMD="npm run build"
      TEST_CMD="npm test"
      RUN_CMD="npm run start"
      ;;
    poetry)
      INSTALL_CMD="poetry install"
      BUILD_CMD="poetry run python -m build"
      TEST_CMD="poetry run pytest"
      RUN_CMD="poetry run python -m <module>"
      ;;
    pip|pip/pyproject)
      INSTALL_CMD="python -m pip install -r requirements.txt"
      BUILD_CMD="python -m build"
      TEST_CMD="pytest"
      RUN_CMD="python -m <module>"
      ;;
    cargo)
      INSTALL_CMD="cargo fetch"
      BUILD_CMD="cargo build"
      TEST_CMD="cargo test"
      RUN_CMD="cargo run"
      ;;
    "go modules")
      INSTALL_CMD="go mod tidy"
      BUILD_CMD="go build ./..."
      TEST_CMD="go test ./..."
      RUN_CMD="go run ./..."
      ;;
    maven)
      INSTALL_CMD="mvn dependency:resolve"
      BUILD_CMD="mvn clean package"
      TEST_CMD="mvn test"
      RUN_CMD="mvn exec:java"
      ;;
    gradle)
      INSTALL_CMD="./gradlew dependencies"
      BUILD_CMD="./gradlew build"
      TEST_CMD="./gradlew test"
      RUN_CMD="./gradlew run"
      ;;
    bundler)
      INSTALL_CMD="bundle install"
      BUILD_CMD="bundle exec rake build"
      TEST_CMD="bundle exec rspec"
      RUN_CMD="bundle exec ruby main.rb"
      ;;
    *)
      ;;
  esac

  if [ -f "$p/package.json" ] && command -v jq >/dev/null 2>&1; then
    local cmd_prefix script
    cmd_prefix="npm run"
    if [ "$bs" = "pnpm" ]; then
      cmd_prefix="pnpm"
    elif [ "$bs" = "yarn" ]; then
      cmd_prefix="yarn"
    fi

    script="$(jq -r '.scripts.build // empty' "$p/package.json" 2>/dev/null || true)"
    [ -n "$script" ] && BUILD_CMD="$cmd_prefix build"

    script="$(jq -r '.scripts.test // empty' "$p/package.json" 2>/dev/null || true)"
    [ -n "$script" ] && TEST_CMD="$cmd_prefix test"

    script="$(jq -r '.scripts.start // .scripts.dev // empty' "$p/package.json" 2>/dev/null || true)"
    if [ -n "$script" ]; then
      if [ "$cmd_prefix" = "npm run" ]; then
        if jq -e '.scripts.start' "$p/package.json" >/dev/null 2>&1; then
          RUN_CMD="npm run start"
        else
          RUN_CMD="npm run dev"
        fi
      elif [ "$cmd_prefix" = "yarn" ]; then
        if jq -e '.scripts.start' "$p/package.json" >/dev/null 2>&1; then
          RUN_CMD="yarn start"
        else
          RUN_CMD="yarn dev"
        fi
      else
        if jq -e '.scripts.start' "$p/package.json" >/dev/null 2>&1; then
          RUN_CMD="pnpm start"
        else
          RUN_CMD="pnpm dev"
        fi
      fi
    fi
  fi
}

common_directories() {
  local p="$1"
  local found=0
  local d
  for d in src app lib cmd pkg internal tests test spec docs scripts config .github; do
    if [ -d "$p/$d" ]; then
      printf -- '- `%s/`\n' "$d"
      found=1
    fi
  done
  [ "$found" -eq 1 ] || printf -- '- No common source directories detected.\n'
}

key_files() {
  local p="$1"
  local found=0
  local f
  for f in package.json pyproject.toml requirements.txt Cargo.toml go.mod pom.xml \
    build.gradle build.gradle.kts Gemfile composer.json Dockerfile LICENSE; do
    if [ -f "$p/$f" ]; then
      printf -- '- `%s`\n' "$f"
      found=1
    fi
  done
  [ "$found" -eq 1 ] || printf -- '- No common manifest files detected.\n'
}

project_snapshot() {
  local p="$1"
  local depth="$2"
  local has_items=0

  while IFS= read -r path; do
    local rel slash_count indent_width indent name
    has_items=1
    rel="${path#$p/}"
    slash_count="$(printf '%s' "$rel" | awk -F'/' '{print NF-1}')"
    indent_width=$((slash_count * 2))
    indent="$(printf '%*s' "$indent_width" '')"
    name="$(basename "$rel")"
    if [ -d "$path" ]; then
      name="$name/"
    fi
    printf '%s- %s\n' "$indent" "$name"
  done < <(
    find "$p" -mindepth 1 -maxdepth "$depth" \
      -not -path '*/.git/*' \
      -not -path '*/node_modules/*' \
      -not -path '*/.venv/*' \
      -not -path '*/dist/*' \
      -not -path '*/build/*' \
      -not -path '*/target/*' \
      -not -path '*/__pycache__/*' \
      | sort
  )

  [ "$has_items" -eq 1 ] || printf -- '- No files found within max depth.\n'
}

generate_readme() {
  local p="$1"
  local language="$2"
  local build_system="$3"
  local project_name title_line description_line

  project_name="$(basename "$(cd "$p" && pwd)")"
  title_line="$TITLE"
  description_line="$DESCRIPTION"
  [ -n "$title_line" ] || title_line="$project_name"
  [ -n "$description_line" ] || description_line="Auto-generated README scaffold for $project_name."

  printf '# %s\n\n' "$title_line"
  printf '%s\n\n' "$description_line"
  printf '## Overview\n\n'
  printf 'This project appears to be primarily **%s** and uses **%s**.\n\n' "$language" "$build_system"
  printf 'This README was generated automatically and should be reviewed before publishing.\n\n'
  printf '## Project Structure\n\n'
  printf '### Common Directories\n'
  common_directories "$p"
  printf '\n### Key Files\n'
  key_files "$p"

  if [ "$INCLUDE_TREE" = "true" ]; then
    printf '\n### Snapshot (max depth: %s)\n\n```text\n' "$MAX_DEPTH"
    project_snapshot "$p" "$MAX_DEPTH"
    printf '```\n'
  fi

  printf '\n## Getting Started\n\n'
  printf '### Install\n\n```bash\n%s\n```\n\n' "$INSTALL_CMD"
  printf '### Build\n\n```bash\n%s\n```\n\n' "$BUILD_CMD"
  printf '### Test\n\n```bash\n%s\n```\n\n' "$TEST_CMD"
  printf '### Run\n\n```bash\n%s\n```\n\n' "$RUN_CMD"
  printf '## Development Notes\n\n'
  printf -- '- Replace placeholder commands if your project uses custom workflows.\n'
  printf -- '- Expand setup details (secrets, services, local infra) as needed.\n\n'
  printf '## License\n\n'
  printf 'Add your project license information here.\n'
}

# Defaults
PROJECT_DIR="."
OUTPUT=""
OVERWRITE="false"
TITLE=""
DESCRIPTION=""
INCLUDE_TREE="true"
MAX_DEPTH="2"
CONFIG_PATH=""
DRY_RUN="false"

ORIGINAL_ARGS=("$@")
INITIAL_PROJECT="."
INITIAL_CONFIG=""
PASS1_POSITIONAL_SEEN="false"

i=0
while [ "$i" -lt "${#ORIGINAL_ARGS[@]}" ]; do
  arg="${ORIGINAL_ARGS[$i]}"
  case "$arg" in
    --project)
      i=$((i + 1))
      [ "$i" -lt "${#ORIGINAL_ARGS[@]}" ] && INITIAL_PROJECT="${ORIGINAL_ARGS[$i]}"
      ;;
    --project=*)
      INITIAL_PROJECT="${arg#*=}"
      ;;
    --config)
      i=$((i + 1))
      [ "$i" -lt "${#ORIGINAL_ARGS[@]}" ] && INITIAL_CONFIG="${ORIGINAL_ARGS[$i]}"
      ;;
    --config=*)
      INITIAL_CONFIG="${arg#*=}"
      ;;
    --output|--title|--description|--include-tree|--max-depth)
      i=$((i + 1))
      ;;
    --*)
      ;;
    *)
      if [ "$PASS1_POSITIONAL_SEEN" = "false" ]; then
        INITIAL_PROJECT="$arg"
        PASS1_POSITIONAL_SEEN="true"
      fi
      ;;
  esac
  i=$((i + 1))
done

if [ -n "$INITIAL_CONFIG" ]; then
  CONFIG_PATH="$INITIAL_CONFIG"
elif [ -n "${README_GEN_CONFIG:-}" ]; then
  CONFIG_PATH="$README_GEN_CONFIG"
elif [ -f "$INITIAL_PROJECT/.readme-generator.conf" ]; then
  CONFIG_PATH="$INITIAL_PROJECT/.readme-generator.conf"
fi

load_config_file "$CONFIG_PATH"

if [ -n "${README_GEN_PROJECT:-}" ]; then
  PROJECT_DIR="$README_GEN_PROJECT"
fi
if [ -n "${README_GEN_OUTPUT:-}" ]; then
  OUTPUT="$README_GEN_OUTPUT"
fi
if [ -n "${README_GEN_OVERWRITE:-}" ]; then
  OVERWRITE="$(to_bool "$README_GEN_OVERWRITE")" || die "Invalid README_GEN_OVERWRITE value" 2
fi
if [ -n "${README_GEN_TITLE:-}" ]; then
  TITLE="$README_GEN_TITLE"
fi
if [ -n "${README_GEN_DESCRIPTION:-}" ]; then
  DESCRIPTION="$README_GEN_DESCRIPTION"
fi
if [ -n "${README_GEN_INCLUDE_TREE:-}" ]; then
  INCLUDE_TREE="$(to_bool "$README_GEN_INCLUDE_TREE")" || die "Invalid README_GEN_INCLUDE_TREE value" 2
fi
if [ -n "${README_GEN_MAX_DEPTH:-}" ]; then
  is_positive_int "$README_GEN_MAX_DEPTH" || die "Invalid README_GEN_MAX_DEPTH value" 2
  MAX_DEPTH="$README_GEN_MAX_DEPTH"
fi

set -- "${ORIGINAL_ARGS[@]}"
POSITIONAL=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --help|-h)
      print_help
      exit 0
      ;;
    --version)
      printf '%s\n' "$VERSION"
      exit 0
      ;;
    --project)
      [ "$#" -ge 2 ] || die "Missing value for --project" 2
      PROJECT_DIR="$2"
      shift 2
      ;;
    --project=*)
      PROJECT_DIR="${1#*=}"
      shift
      ;;
    --output)
      [ "$#" -ge 2 ] || die "Missing value for --output" 2
      OUTPUT="$2"
      shift 2
      ;;
    --output=*)
      OUTPUT="${1#*=}"
      shift
      ;;
    --overwrite)
      OVERWRITE="true"
      shift
      ;;
    --title)
      [ "$#" -ge 2 ] || die "Missing value for --title" 2
      TITLE="$2"
      shift 2
      ;;
    --title=*)
      TITLE="${1#*=}"
      shift
      ;;
    --description)
      [ "$#" -ge 2 ] || die "Missing value for --description" 2
      DESCRIPTION="$2"
      shift 2
      ;;
    --description=*)
      DESCRIPTION="${1#*=}"
      shift
      ;;
    --include-tree)
      [ "$#" -ge 2 ] || die "Missing value for --include-tree" 2
      INCLUDE_TREE="$(to_bool "$2")" || die "Invalid value for --include-tree: $2" 2
      shift 2
      ;;
    --include-tree=*)
      INCLUDE_TREE="$(to_bool "${1#*=}")" || die "Invalid value for --include-tree: ${1#*=}" 2
      shift
      ;;
    --max-depth)
      [ "$#" -ge 2 ] || die "Missing value for --max-depth" 2
      is_positive_int "$2" || die "Invalid value for --max-depth: $2" 2
      MAX_DEPTH="$2"
      shift 2
      ;;
    --max-depth=*)
      is_positive_int "${1#*=}" || die "Invalid value for --max-depth: ${1#*=}" 2
      MAX_DEPTH="${1#*=}"
      shift
      ;;
    --config)
      [ "$#" -ge 2 ] || die "Missing value for --config" 2
      shift 2
      ;;
    --config=*)
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        POSITIONAL+=("$1")
        shift
      done
      ;;
    -*)
      die "Unknown option: $1" 2
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

if [ "${#POSITIONAL[@]}" -gt 1 ]; then
  die "Too many positional arguments." 2
fi
if [ "${#POSITIONAL[@]}" -eq 1 ]; then
  PROJECT_DIR="${POSITIONAL[0]}"
fi

[ -d "$PROJECT_DIR" ] || die "Project directory not found: $PROJECT_DIR" 3
[ -n "$OUTPUT" ] || OUTPUT="$PROJECT_DIR/README.generated.md"

LANGUAGE="$(detect_language "$PROJECT_DIR")"
BUILD_SYSTEM="$(detect_build_system "$PROJECT_DIR")"
detect_commands "$PROJECT_DIR" "$BUILD_SYSTEM"

README_CONTENT="$(generate_readme "$PROJECT_DIR" "$LANGUAGE" "$BUILD_SYSTEM")"

if [ "$DRY_RUN" = "true" ]; then
  printf '%s\n' "$README_CONTENT"
  exit 0
fi

if [ -f "$OUTPUT" ] && [ "$OVERWRITE" != "true" ]; then
  die "Output file already exists: $OUTPUT" 4
fi

mkdir -p "$(dirname "$OUTPUT")"
printf '%s\n' "$README_CONTENT" > "$OUTPUT"
printf 'README generated at %s\n' "$OUTPUT"
