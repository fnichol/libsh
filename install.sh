#!/usr/bin/env sh
# shellcheck disable=SC2039

print_usage() {
  local program version author
  program="$1"
  version="$2"
  author="$3"

  need_cmd sed

  echo "$program $version

    Installs libsh into a dedicated vendored file or inserted into an existing
    source file

    USAGE:
        $program [FLAGS] [OPTIONS] [--]

    FLAGS:
        -h, --help      Prints help information
        -V, --version   Prints version information

    OPTIONS:
        -d, --distribution=<DISTRIB>  Distribution format
                                      [values: full, full-minified,
                                      minimal, minimal-minified]
                                      [default: full]
        -m, --mode=<MODE>             Install mode
                                      [values: vendor, insert]
                                      [default: vendor]
        -r, --release=<RELEASE>       Release version
                                      [examples: latest, 1.2.3, main]
                                      [default: latest]
        -t, --target=<TARGET>         Target directory or file for installation
                                      [examples: /tmp/libsh.sh, file.txt]
                                      [default: ./vendor/lib/libsh.<DISTRIB>.sh]

    EXAMPLES:
        # Vendor the latest full release into ./vendor/lib/libsh.sh
        $program

        # Vendor a specific minimal release into /tmp/libsh-0.0.1.sh
        $program --release=0.0.1 --distribution=minimal \\
            --target=/tmp/libsh-0.0.1.sh

        # Insert the latest full release into myprog.sh at a line:
        # \`# INSERT: libsh.sh\`
        $program --mode=insert --target=myprog.sh

        # Update the inserted version with a specific minimal/minified
        # release in cli.sh:
        $program --mode=insert --release=0.0.1 \\
            --distribution=minimal-minified --target=cli.sh

    AUTHOR:
        $author
    " | sed 's/^ \{1,4\}//g'
}

main() {
  set -eu
  if [ -n "${DEBUG:-}" ]; then set -v; fi
  if [ -n "${TRACE:-}" ]; then set -xv; fi

  local program version author sha sha_long date
  program="install.sh"
  version="0.8.0"
  author="Fletcher Nichol <fnichol@nichol.ca>"
  sha="0daf997"
  sha_long="0daf997ec5026389d31461dd19f1d21082be737e"
  date="2021-04-11"

  # Parse CLI arguments and set local variables
  parse_cli_args "$program" "$version" "$author" "$sha" "$sha_long" "$date" "$@"
  local distrib mode release target
  distrib="$DISTRIB"
  mode="$MODE"
  release="$RELEASE"
  target="$TARGET"
  unset DISTRIB MODE RELEASE TARGET

  setup_traps trap_cleanup_files

  if [ "$release" = "latest" ]; then
    release="$(latest_release fnichol/libsh)"
  fi

  case "$mode" in
    insert)
      insert_libsh "$release" "$distrib" "$target"
      ;;
    vendor)
      vendor_libsh "$release" "$distrib" "$target"
      ;;
    *)
      die "invalid mode value; mode=$mode"
      ;;
  esac
}

parse_cli_args() {
  local program version author sha sha_long date mode release target
  program="$1"
  shift
  version="$1"
  shift
  author="$1"
  shift
  sha="$1"
  shift
  sha_long="$1"
  shift
  date="$1"
  shift

  DISTRIB="full"
  MODE="vendor"
  RELEASE="latest"
  TARGET=

  OPTIND=1
  while getopts "hd:m:r:t:V-:" arg; do
    case "$arg" in
      h)
        print_usage "$program" "$version" "$author"
        exit 0
        ;;
      d)
        if is_distrib_valid "$OPTARG"; then
          DISTRIB="$OPTARG"
        else
          print_usage "$program" "$version" "$author" >&2
          die "invalid distribution name $OPTARG"
        fi
        ;;
      m)
        if is_mode_valid "$OPTARG"; then
          MODE="$OPTARG"
        else
          print_usage "$program" "$version" "$author" >&2
          die "invalid mode name $OPTARG"
        fi
        ;;
      r)
        RELEASE="$OPTARG"
        ;;
      t)
        TARGET="$OPTARG"
        ;;
      V)
        print_version "$program" "$version" "true" "$sha" "$sha_long" "$date"
        exit 0
        ;;
      -)
        long_optarg="${OPTARG#*=}"
        case "$OPTARG" in
          distribution=?*)
            if is_distrib_valid "$long_optarg"; then
              DISTRIB="$long_optarg"
            else
              print_usage "$program" "$version" "$author" >&2
              die "invalid distribution name '$long_optarg'"
            fi
            ;;
          distribution*)
            print_usage "$program" "$version" "$author" >&2
            die "missing required argument for --$OPTARG option"
            ;;
          help)
            print_usage "$program" "$version" "$author"
            exit 0
            ;;
          mode=?*)
            if is_mode_valid "$long_optarg"; then
              MODE="$long_optarg"
            else
              print_usage "$program" "$version" "$author" >&2
              die "invalid mode name '$long_optarg'"
            fi
            ;;
          mode*)
            print_usage "$program" "$version" "$author" >&2
            die "missing required argument for --$OPTARG option"
            ;;
          release=?*)
            RELEASE="$long_optarg"
            ;;
          release*)
            print_usage "$program" "$version" "$author" >&2
            die "missing required argument for --$OPTARG option"
            ;;
          target=?*)
            TARGET="$long_optarg"
            ;;
          target*)
            print_usage "$program" "$version" "$author" >&2
            die "missing required argument for --$OPTARG option"
            ;;
          version)
            print_version "$program" "$version" "true" \
              "$sha" "$sha_long" "$date"
            exit 0
            ;;
          '')
            # "--" terminates argument processing
            break
            ;;
          *)
            print_usage "$program" "$version" "$author" >&2
            die "invalid argument --$OPTARG"
            ;;
        esac
        ;;
      \?)
        print_usage "$program" "$version" "$author" >&2
        die "invalid argument; arg=-$OPTARG"
        ;;
    esac
  done
  shift "$((OPTIND - 1))"

  if [ -z "$TARGET" ]; then
    TARGET="./vendor/lib/libsh.${DISTRIB}.sh"
  fi
}

download_libsh() {
  local release distrib target repo
  release="$1"
  distrib="$2"
  target="$3"
  repo="https://github.com/fnichol/libsh"

  download \
    "$repo/releases/download/v${release}/libsh.${distrib}.sh" \
    "$target"
}

insert_libsh() {
  local release distrib target
  release="$1"
  distrib="$2"
  target="$3"

  need_cmd awk
  need_cmd cat

  local libsh rendered
  libsh="$(mktemp_file)"
  cleanup_file "$libsh"
  rendered="$(mktemp_file)"
  cleanup_file "$rendered"

  section "Inserting libsh.sh '$release' ($distrib) into $target"

  download_libsh "$release" "$distrib" "$libsh"

  info "Inlining libsh into $target"
  awk -v libsh="$libsh" '
    BEGIN {
      tgtprint = 1
      libprint = 0
    }

    # Stop printing from BEGIN line
    /^# BEGIN: libsh.sh$/ {
      tgtprint = 0
    }
    # Insert libsh at BEGIN or INSERT lines
    /^# BEGIN: libsh.sh$/ || /^# INSERT: libsh.sh$/ {
      while ((getline libshln < libsh) > 0) {
        if (libshln == "# BEGIN: libsh.sh") {
          # Start printing libsh contents starting with BEGIN line
          libprint = 1
          print libshln
        } else if (libshln == "# END: libsh.sh") {
          # Stop printing libsh contents after printing END line
          libprint = 0
          print libshln
        } else if (libprint == 1) {
          # If libshprint mode is enabled, print line
          print libshln
        }
      }
      close(libsh)
    }
    # Do not print INSERT line
    /^# INSERT: libsh.sh$/ {
      next
    }
    # Resume printing after END line
    /^# END: libsh.sh$/ {
      tgtprint = 1
      next
    }
    # If target print mode is enabled, print line
    tgtprint == 1 {
      print
    }
  ' "$target" >"$rendered"
  cat "$rendered" >"$target"
}

is_distrib_valid() {
  local distrib
  distrib="$1"

  case "$distrib" in
    full | full-minified | minimal | minimal-minified)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_mode_valid() {
  local mode
  mode="$1"

  case "$mode" in
    vendor | insert)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

latest_release() {
  local gh_repo
  gh_repo="$1"

  need_cmd awk

  local tmpfile
  tmpfile="$(mktemp_file)"
  cleanup_file "$tmpfile"

  download \
    "https://api.github.com/repos/$gh_repo/releases/latest" \
    "$tmpfile" \
    >/dev/null
  awk '
    BEGIN { FS="\""; RS="," }
    $2 == "tag_name" { sub(/^v/, "", $4); print $4 }
  ' "$tmpfile"
}

vendor_libsh() {
  local release distrib target
  release="$1"
  distrib="$2"
  target="$3"

  need_cmd cat
  need_cmd touch
  need_cmd dirname
  need_cmd mkdir

  local tmpfile
  tmpfile="$(mktemp_file)"
  cleanup_file "$tmpfile"

  section "Vendoring libsh.sh '$release' ($distrib) to $target"

  download_libsh "$release" "$distrib" "$tmpfile"

  info "Copying libsh to $target"
  mkdir -p "$(dirname "$target")"
  touch "$target"
  cat "$tmpfile" >"$target"
}

version_ge() {
  local version maj min
  version="$1"
  maj="$2"
  min="$3"

  need_cmd awk

  [ "$(echo "$version" | awk -F'.' '{ print $1 }')" -ge "$maj" ] \
    && [ "$(echo "$version" | awk -F'.' '{ print $2 }')" -ge "$min" ]
}

# BEGIN: libsh.sh

#
# Copyright 2019 Fletcher Nichol and/or applicable contributors.
#
# Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
# http://www.apache.org/licenses/LICENSE-2.0> or the MIT license (see
# <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your option. This
# file may not be copied, modified, or distributed except according to those
# terms.
#
# libsh.sh
# --------
# project: https://github.com/fnichol/libsh
# author: Fletcher Nichol <fnichol@nichol.ca>
# version: 0.8.0
# distribution: libsh.full-minified.sh
# commit-hash: 0daf997ec5026389d31461dd19f1d21082be737e
# commit-date: 2021-04-11
# artifact: https://github.com/fnichol/libsh/releases/download/v0.8.0/libsh.full.sh
# source: https://github.com/fnichol/libsh/tree/v0.8.0
# archive: https://github.com/fnichol/libsh/archive/v0.8.0.tar.gz
#
if [ -n "${KSH_VERSION:-}" ]; then
  eval "local() { return 0; }"
fi
# shellcheck disable=SC2120
mktemp_directory() {
  need_cmd mktemp
  if [ -n "${1:-}" ]; then
    mktemp -d "$1/tmp.XXXXXX"
  else
    mktemp -d 2>/dev/null || mktemp -d -t tmp
  fi
}
# shellcheck disable=SC2120
mktemp_file() {
  need_cmd mktemp
  if [ -n "${1:-}" ]; then
    mktemp "$1/tmp.XXXXXX"
  else
    mktemp 2>/dev/null || mktemp -t tmp
  fi
}
need_cmd() {
  if ! check_cmd "$1"; then
    die "Required command '$1' not found on PATH"
  fi
}
print_version() {
  local _program _version _verbose _sha _long_sha _date
  _program="$1"
  _version="$2"
  _verbose="${3:-false}"
  _sha="${4:-}"
  _long_sha="${5:-}"
  _date="${6:-}"
  if [ -z "$_sha" ] || [ -z "$_long_sha" ] || [ -z "$_date" ]; then
    if check_cmd git \
      && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      if [ -z "$_sha" ]; then
        _sha="$(git show -s --format=%h)"
        if ! git diff-index --quiet HEAD --; then
          _sha="${_sha}-dirty"
        fi
      fi
      if [ -z "$_long_sha" ]; then
        _long_sha="$(git show -s --format=%H)"
        case "$_sha" in
          *-dirty) _long_sha="${_long_sha}-dirty" ;;
        esac
      fi
      if [ -z "$_date" ]; then
        _date="$(git show -s --format=%ad --date=short)"
      fi
    fi
  fi
  if [ -n "$_sha" ] && [ -n "$_date" ]; then
    echo "$_program $_version ($_sha $_date)"
  else
    echo "$_program $_version"
  fi
  if [ "$_verbose" = "true" ]; then
    echo "release: $_version"
    if [ -n "$_long_sha" ]; then
      echo "commit-hash: $_long_sha"
    fi
    if [ -n "$_date" ]; then
      echo "commit-date: $_date"
    fi
  fi
  unset _program _version _verbose _sha _long_sha _date
}
section() {
  case "${TERM:-}" in
    *term | alacritty | rxvt | screen | screen-* | tmux | tmux-* | xterm-*)
      printf -- "\033[1;36;40m--- \033[1;37;40m%s\033[0m\n" "$1"
      ;;
    *)
      printf -- "--- %s\n" "$1"
      ;;
  esac
}
setup_traps() {
  local _sig
  for _sig in HUP INT QUIT ALRM TERM; do
    trap "
      $1
      trap - $_sig EXIT
      kill -s $_sig "'"$$"' "$_sig"
  done
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval "zshexit() { eval '$1'; }"
  else
    # shellcheck disable=SC2064
    trap "$1" EXIT
  fi
  unset _sig
}
trap_cleanup_directories() {
  set +e
  if [ -n "${__CLEANUP_DIRECTORIES__:-}" ] \
    && [ -f "$__CLEANUP_DIRECTORIES__" ]; then
    local _dir
    while read -r _dir; do
      rm -rf "$_dir"
    done <"$__CLEANUP_DIRECTORIES__"
    unset _dir
    rm -f "$__CLEANUP_DIRECTORIES__"
  fi
}
trap_cleanup_files() {
  set +e
  if [ -n "${__CLEANUP_FILES__:-}" ] && [ -f "$__CLEANUP_FILES__" ]; then
    local _file
    while read -r _file; do
      rm -f "$_file"
    done <"$__CLEANUP_FILES__"
    unset _file
    rm -f "$__CLEANUP_FILES__"
  fi
}
warn() {
  case "${TERM:-}" in
    *term | alacritty | rxvt | screen | screen-* | tmux | tmux-* | xterm-*)
      printf -- "\033[1;31;40m!!! \033[1;37;40m%s\033[0m\n" "$1"
      ;;
    *)
      printf -- "!!! %s\n" "$1"
      ;;
  esac
}
check_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    return 1
  fi
}
cleanup_directory() {
  if [ -z "${__CLEANUP_DIRECTORIES__:-}" ]; then
    __CLEANUP_DIRECTORIES__="$(mktemp_file)"
    if [ -z "$__CLEANUP_DIRECTORIES__" ]; then
      return 1
    fi
  fi
  echo "$1" >>"$__CLEANUP_DIRECTORIES__"
}
cleanup_file() {
  if [ -z "${__CLEANUP_FILES__:-}" ]; then
    __CLEANUP_FILES__="$(mktemp_file)"
    if [ -z "$__CLEANUP_FILES__" ]; then
      return 1
    fi
  fi
  echo "$1" >>"$__CLEANUP_FILES__"
}
die() {
  case "${TERM:-}" in
    *term | alacritty | rxvt | screen | screen-* | tmux | tmux-* | xterm-*)
      printf -- "\n\033[1;31;40mxxx \033[1;37;40m%s\033[0m\n\n" "$1" >&2
      ;;
    *)
      printf -- "\nxxx %s\n\n" "$1" >&2
      ;;
  esac
  exit 1
}
download() {
  local _url _dst _code _orig_flags
  _url="$1"
  _dst="$2"
  need_cmd sed
  if check_cmd curl; then
    info "Downloading $_url to $_dst (curl)"
    _orig_flags="$-"
    set +e
    curl -sSfL "$_url" -o "$_dst"
    _code="$?"
    set "-$(echo "$_orig_flags" | sed s/s//g)"
    if [ $_code -eq 0 ]; then
      unset _url _dst _code _orig_flags
      return 0
    else
      local _e
      _e="curl failed to download file, perhaps curl doesn't have"
      _e="$_e SSL support and/or no CA certificates are present?"
      warn "$_e"
      unset _e
    fi
  fi
  if check_cmd wget; then
    info "Downloading $_url to $_dst (wget)"
    _orig_flags="$-"
    set +e
    wget -q -O "$_dst" "$_url"
    _code="$?"
    set "-$(echo "$_orig_flags" | sed s/s//g)"
    if [ $_code -eq 0 ]; then
      unset _url _dst _code _orig_flags
      return 0
    else
      local _e
      _e="wget failed to download file, perhaps wget doesn't have"
      _e="$_e SSL support and/or no CA certificates are present?"
      warn "$_e"
      unset _e
    fi
  fi
  if check_cmd ftp; then
    info "Downloading $_url to $_dst (ftp)"
    _orig_flags="$-"
    set +e
    ftp -o "$_dst" "$_url"
    _code="$?"
    set "-$(echo "$_orig_flags" | sed s/s//g)"
    if [ $_code -eq 0 ]; then
      unset _url _dst _code _orig_flags
      return 0
    else
      local _e
      _e="ftp failed to download file, perhaps ftp doesn't have"
      _e="$_e SSL support and/or no CA certificates are present?"
      warn "$_e"
      unset _e
    fi
  fi
  unset _url _dst _code _orig_flags
  warn "Downloading requires SSL-enabled 'curl', 'wget', or 'ftp' on PATH"
  return 1
}
indent() {
  local _ecfile _ec _orig_flags
  need_cmd cat
  need_cmd rm
  need_cmd sed
  _ecfile="$(mktemp_file)"
  _orig_flags="$-"
  set +e
  {
    "$@" 2>&1
    echo "$?" >"$_ecfile"
  } | sed 's/^/       /'
  set "-$(echo "$_orig_flags" | sed s/s//g)"
  _ec="$(cat "$_ecfile")"
  rm -f "$_ecfile"
  unset _ecfile _orig_flags
  return "${_ec:-5}"
}
info() {
  case "${TERM:-}" in
    *term | alacritty | rxvt | screen | screen-* | tmux | tmux-* | xterm-*)
      printf -- "\033[1;36;40m  - \033[1;37;40m%s\033[0m\n" "$1"
      ;;
    *)
      printf -- "  - %s\n" "$1"
      ;;
  esac
}
info_end() {
  case "${TERM:-}" in
    *term | alacritty | rxvt | screen | screen-* | tmux | tmux-* | xterm-*)
      printf -- "\033[1;37;40m%s\033[0m\n" "done."
      ;;
    *)
      printf -- "%s\n" "done."
      ;;
  esac
}
info_start() {
  case "${TERM:-}" in
    *term | alacritty | rxvt | screen | screen-* | tmux | tmux-* | xterm-*)
      printf -- "\033[1;36;40m  - \033[1;37;40m%s ... \033[0m" "$1"
      ;;
    *)
      printf -- "  - %s ... " "$1"
      ;;
  esac
}

# END: libsh.sh

main "$@"
