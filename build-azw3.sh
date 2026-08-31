#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DEFAULT_NAME="daily-notes"
OUTPUT=""
TITLE=""
AUTHOR=""
KEEP_EPUB=0

usage() {
  cat <<'EOF'
Usage: ./build-azw3.sh [options] [markdown-file ...]

Build an AZW3 (Kindle) ebook from Markdown files. With no file arguments, all
Markdown files below the script directory are included in filename order,
except README.md.

The Markdown is first converted to EPUB with ./build-epub.sh, then converted to
AZW3 with Calibre's ebook-convert.

Output path and title default to the name of the first Markdown file given
(e.g. dbt-agenda-book.md -> dbt-agenda-book.azw3, titled "Dbt Agenda Book").
With no file arguments they fall back to daily-notes.azw3 / "Daily Notes".

Options:
  -o, --output FILE   Output AZW3 path (default: <first input file>.azw3)
  -t, --title TITLE   Ebook title (default: name of the first input file)
  -a, --author NAME   Ebook author
  -k, --keep-epub     Keep the intermediate EPUB next to the output
  -h, --help          Show this help

The script uses a locally installed ebook-convert when available. Otherwise, it
uses Docker and the image specified by CALIBRE_IMAGE (default:
linuxserver/calibre:latest).
EOF
}

# "dbt-agenda-book" -> "Dbt Agenda Book"
title_from_name() {
  local words=${1//[-_]/ } word out=""
  for word in $words; do
    out+="${out:+ }${word^}"
  done
  printf '%s' "$out"
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
    -k|--keep-epub)
      KEEP_EPUB=1
      shift
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

[[ -x $ROOT_DIR/build-epub.sh ]] || {
  echo "Required helper not found or not executable: $ROOT_DIR/build-epub.sh" >&2
  exit 1
}

if ((${#requested_files[@]})); then
  BASE_NAME=$(basename -- "${requested_files[0]}")
  BASE_NAME=${BASE_NAME%.*}
else
  BASE_NAME=$DEFAULT_NAME
fi
[[ -n $OUTPUT ]] || OUTPUT="$ROOT_DIR/$BASE_NAME.azw3"
[[ -n $TITLE ]] || TITLE=$(title_from_name "$BASE_NAME")

[[ $OUTPUT = /* ]] || OUTPUT="$PWD/$OUTPUT"
mkdir -p -- "$(dirname -- "$OUTPUT")"

# The intermediate EPUB must live inside ROOT_DIR so the Docker fallbacks in
# both this script and build-epub.sh can reach it through the /data mount.
if ((KEEP_EPUB)); then
  EPUB="${OUTPUT%.*}.epub"
  case "$EPUB" in
    "$ROOT_DIR"/*) ;;
    *) EPUB="$ROOT_DIR/$(basename -- "${OUTPUT%.*}").epub" ;;
  esac
else
  EPUB="$ROOT_DIR/.build-azw3-$$.epub"
  trap 'rm -f -- "$EPUB"' EXIT
fi

declare -a epub_args=(--output "$EPUB" --title "$TITLE")
[[ -z $AUTHOR ]] || epub_args+=(--author "$AUTHOR")
((${#requested_files[@]} == 0)) || epub_args+=(-- "${requested_files[@]}")

"$ROOT_DIR/build-epub.sh" "${epub_args[@]}"

declare -a convert_args=(
  --title "$TITLE"
  --output-profile kindle_pw3
  --share-not-sync
)
[[ -z $AUTHOR ]] || convert_args+=(--authors "$AUTHOR")

if command -v ebook-convert >/dev/null 2>&1; then
  ebook-convert "$EPUB" "$OUTPUT" "${convert_args[@]}"
else
  command -v docker >/dev/null 2>&1 || {
    echo "Neither ebook-convert (Calibre) nor Docker is installed." >&2
    exit 1
  }

  case "$OUTPUT" in
    "$ROOT_DIR"/*) ;;
    *)
      echo "Docker mode requires the output path to be inside $ROOT_DIR" >&2
      exit 1
      ;;
  esac

  docker run --rm \
    --user "$(id -u):$(id -g)" \
    --volume "$ROOT_DIR:/data" \
    --workdir /data \
    --env HOME=/tmp \
    --entrypoint ebook-convert \
    "${CALIBRE_IMAGE:-linuxserver/calibre:latest}" \
    "/data/${EPUB#"$ROOT_DIR"/}" \
    "/data/${OUTPUT#"$ROOT_DIR"/}" \
    "${convert_args[@]}"
fi

((KEEP_EPUB == 0)) || echo "Kept intermediate EPUB: $EPUB"
echo "Created: $OUTPUT"
