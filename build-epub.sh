#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
OUTPUT="$ROOT_DIR/daily-notes.epub"
TITLE="Daily Notes"
AUTHOR=""

usage() {
  cat <<'EOF'
Usage: ./build-epub.sh [options] [markdown-file ...]

Build an EPUB from Markdown files. With no file arguments, all Markdown files
below the script directory are included in filename order, except README.md.

Options:
  -o, --output FILE   Output EPUB path (default: daily-notes.epub)
  -t, --title TITLE   Ebook title (default: Daily Notes)
  -a, --author NAME   Ebook author
  -h, --help          Show this help

The script uses a locally installed pandoc when available. Otherwise, it uses
Docker and the image specified by PANDOC_IMAGE (default: pandoc/core:latest).
EOF
}

declare -a requested_files=()
while (($#)); do
  case "$1" in
    -o|--output)
      [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 2; }
      OUTPUT=$2
      shift 2
      ;;
    -t|--title)
      [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 2; }
      TITLE=$2
      shift 2
      ;;
    -a|--author)
      [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 2; }
      AUTHOR=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      requested_files+=("$@")
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      requested_files+=("$1")
      shift
      ;;
  esac
done

declare -a files=()
if ((${#requested_files[@]})); then
  for file in "${requested_files[@]}"; do
    [[ $file = /* ]] || file="$PWD/$file"
    [[ -f $file ]] || { echo "Markdown file not found: $file" >&2; exit 1; }
    files+=("$(realpath -- "$file")")
  done
else
  mapfile -d '' files < <(
    find "$ROOT_DIR" \
      -path "$ROOT_DIR/.git" -prune -o \
      -type f -name '*.md' ! -name 'README.md' -print0 |
      sort -z
  )
fi

((${#files[@]})) || { echo "No Markdown files found." >&2; exit 1; }

[[ $OUTPUT = /* ]] || OUTPUT="$PWD/$OUTPUT"
mkdir -p -- "$(dirname -- "$OUTPUT")"

declare -a pandoc_args=(
  --from=gfm
  --to=epub3
  --standalone
  --toc
  --split-level=1
  --metadata "title=$TITLE"
  --metadata "lang=en"
)
[[ -z $AUTHOR ]] || pandoc_args+=(--metadata "author=$AUTHOR")

if command -v pandoc >/dev/null 2>&1; then
  pandoc "${pandoc_args[@]}" \
    --resource-path="$ROOT_DIR" \
    --output="$OUTPUT" \
    "${files[@]}"
else
  command -v docker >/dev/null 2>&1 || {
    echo "Neither pandoc nor Docker is installed." >&2
    exit 1
  }

  case "$OUTPUT" in
    "$ROOT_DIR"/*) ;;
    *)
      echo "Docker mode requires the output path to be inside $ROOT_DIR" >&2
      exit 1
      ;;
  esac

  declare -a container_files=()
  for file in "${files[@]}"; do
    case "$file" in
      "$ROOT_DIR"/*) container_files+=("/data/${file#"$ROOT_DIR"/}") ;;
      *)
        echo "Docker mode requires input files to be inside $ROOT_DIR: $file" >&2
        exit 1
        ;;
    esac
  done

  docker run --rm \
    --user "$(id -u):$(id -g)" \
    --volume "$ROOT_DIR:/data" \
    --workdir /data \
    "${PANDOC_IMAGE:-pandoc/core:latest}" \
    "${pandoc_args[@]}" \
    --resource-path=/data \
    --output="/data/${OUTPUT#"$ROOT_DIR"/}" \
    "${container_files[@]}"
fi

echo "Created: $OUTPUT (${#files[@]} Markdown files)"
