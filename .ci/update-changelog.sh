#!/usr/bin/env sh
# shellcheck disable=SC3043

print_usage() {
  local program="$1"

  echo "$program

    Updates a CHANGELOG.md for a new release

    USAGE:
        $program [FLAGS] [--] <REPO> <VERSION> <TAG_NAME> <CHANGELOG>

    FLAGS:
        -h, --help      Prints help information

    ARGS:
        <REPO>      GitHub repository url [ex: https://github.com/fnichol/libsh]
        <VERSION>   Version for the new release [ex: 1.2.0]
        <TAG_NAME>  Tag name for the new release [ex: v1.2.0]
        <CHANGELOG> Path to a Markdown CHANGELOG [default: CHANGELOG.md]
    " | sed 's/^ \{1,4\}//g'
}

main() {
  set -eu
  if [ -n "${DEBUG:-}" ]; then set -v; fi
  if [ -n "${TRACE:-}" ]; then set -xv; fi

  local program
  program="$(basename "$0")"

  local changelog=CHANGELOG.md

  OPTIND=1
  while getopts "h-:" arg; do
    case "$arg" in
      h)
        print_usage "$program"
        return 0
        ;;
      -)
        case "$OPTARG" in
          help)
            print_usage "$program"
            return 0
            ;;
          '')
            # "--" terminates argument processing
            break
            ;;
          *)
            print_usage "$program" >&2
            die "invalid argument --$OPTARG"
            ;;
        esac
        ;;
      \?)
        print_usage "$program" >&2
        die "invalid argument; arg=-$OPTARG"
        ;;
    esac
  done
  shift "$((OPTIND - 1))"

  if [ -z "${1:-}" ]; then
    print_usage "$program" >&2
    die "missing <REPO> argument"
  fi
  local repo="$1"
  shift
  if [ -z "${1:-}" ]; then
    print_usage "$program" >&2
    die "missing <VERSION> argument"
  fi
  local version="$1"
  shift
  if [ -z "${1:-}" ]; then
    print_usage "$program" >&2
    die "missing <TAG_NAME> argument"
  fi
  local tag_name="$1"
  shift
  if [ -n "${1:-}" ]; then
    changelog="$1"
    shift
  fi
  if [ ! -f "$changelog" ]; then
    print_usage "$program" >&2
    die "changelog '$changelog' not found"
  fi

  update_changelog "$repo" "$version" "$tag_name" "$changelog"
}

update_changelog() {
  local repo="$1"
  local version="$2"
  local tag_name="$3"
  local changelog="$4"

  need_cmd date
  need_cmd rm
  need_cmd sed

  local date
  date="$(date -u +%F)"
  local nl='
'

  sed -i.bak -E \
    -e 's,[Uu]nreleased,'"${version}"',g' \
    -e 's,\.\.\.HEAD,...'"${tag_name}"',g' \
    -e 's,ReleaseDate,'"${date}"',g' \
    -e 's,(<!-- next-header -->),\1'"\\${nl}\\${nl}"'## [Unreleased] - ReleaseDate,g' \
    -e 's,(<!-- next-url -->),\1'"\\${nl}\\${nl}"'[unreleased]: '"${repo}"'/compare/'"${tag_name}"'...HEAD,g' \
    "$changelog"
  rm -f "$changelog.bak"
}

die() {
  echo "" >&2
  echo "xxx $1" >&2
  echo "" >&2
  return 1
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    die "Required command '$1' not found on PATH"
  fi
}

main "$@"
