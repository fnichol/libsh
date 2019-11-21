#!/usr/bin/env sh
# shellcheck disable=SC2039

print_usage() {
  need_cmd sed

  local program="$1"
  local version="$2"
  local author="$3"

  echo "$program $version

    Installs libsh into a dedicated vendored file or inserted into an existing
    source file

    USAGE:
        $program [FLAGS] [OPTIONS] [--]

    FLAGS:
        -h, --help      Prints help information
        -V, --version   Prints version information
        -v, --verbose   Prints verbose output

    OPTIONS:
        -m, --mode=<MODE>       Install mode
                                [values: vendor, insert]
                                [default: vendor]
        -r, --release=<RELEASE> Release version
                                [examples: latest, 1.2.3, master]
                                [default: latest]
        -t, --target=<TARGET>   Target directory or file for installation
                                [examples: /tmp/libsh.sh, file.txt]
                                [default: ./vendor/lib/libsh.sh]

    EXAMPLES:
        # Vendor the latest release into ./vendor/lib/libsh.sh
        $program

        # Vendor a specific release into /tmp/libsh-0.0.1.sh
        $program --release=0.0.1 --target=/tmp/libsh-0.0.1.sh

        # Insert the latest release into myprog.sh at a line:
        # \`# INSERT: libsh.sh\`
        $program --mode=insert --target=myprog.sh

        # Update the inserted version with a specific release in cli.sh:
        $program --mode=insert --release=0.0.1 --target=cli.sh

    AUTHOR:
        $author
    " | sed 's/^ \{1,4\}//g'
}

main() {
  set -eu
  if [ -n "${DEBUG:-}" ]; then set -v; fi
  if [ -n "${TRACE:-}" ]; then set -xv; fi

  local program version author
  program="install.sh"
  version="0.1.0"
  author="Fletcher Nichol <fnichol@nichol.ca>"

  invoke_cli "$program" "$version" "$author" "$@"
}

invoke_cli() {
  local program version author mode release target
  program="$1"
  shift
  version="$1"
  shift
  author="$1"
  shift

  VERBOSE=""
  mode="vendor"
  release="latest"
  target="./vendor/lib/libsh.sh"

  OPTIND=1
  while getopts "hm:r:t:vV-:" arg; do
    case "$arg" in
      h)
        print_usage "$program" "$version" "$author"
        return 0
        ;;
      m)
        if is_mode_valid "$OPTARG"; then
          mode="$OPTARG"
        else
          print_usage "$program" "$version" "$author" >&2
          die "invalid mode name $OPTARG"
          return 1
        fi
        ;;
      r)
        release="$OPTARG"
        ;;
      t)
        target="$OPTARG"
        ;;
      v)
        VERBOSE=true
        ;;
      V)
        print_version "$program" "$version" "${VERBOSE:-}"
        return 0
        ;;
      -)
        long_optarg="${OPTARG#*=}"
        case "$OPTARG" in
          help)
            print_usage "$program" "$version" "$author"
            return 0
            ;;
          mode=?*)
            if is_mode_valid "$long_optarg"; then
              mode="$long_optarg"
            else
              print_usage "$program" "$version" "$author" >&2
              die "invalid mode name '$long_optarg'"
              return 1
            fi
            ;;
          mode*)
            print_usage "$program" "$version" "$author" >&2
            die "missing required argument for --$OPTARG option"
            return 1
            ;;
          release=?*)
            release="$long_optarg"
            ;;
          release*)
            print_usage "$program" "$version" "$author" >&2
            die "missing required argument for --$OPTARG option"
            return 1
            ;;
          target=?*)
            target="$long_optarg"
            ;;
          target*)
            print_usage "$program" "$version" "$author" >&2
            die "missing required argument for --$OPTARG option"
            return 1
            ;;
          verbose)
            VERBOSE=true
            ;;
          version)
            print_version "$program" "$version" "${VERBOSE:-}"
            return 0
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

  setup_traps

  if [ "$release" = "latest" ]; then
    release="$(latest_release)"
  fi

  case "$mode" in
    insert)
      insert_libsh "$release" "$target"
      ;;
    vendor)
      vendor_libsh "$release" "$target"
      ;;
    *)
      die "invalid mode value; mode=$mode"
      ;;
  esac
}

download_and_extract() {
  need_cmd tar

  local release="$1"
  local target="$2"

  local archive
  archive="$(mktemp_file)"
  cleanup_file "$archive"

  download \
    "https://github.com/fnichol/libsh/archive/v${release}.tar.gz" \
    "$archive"

  tar xOf "$archive" --strip-components 1 "libsh-$release/libsh.sh" >"$target"
}

# TODO: add to libsh.sh
download() {
  local _url _dst _code _orig_flags
  _url="$1"
  _dst="$2"

  need_cmd sed

  # Attempt to download with wget, if found. If successful, quick return
  if command -v wget >/dev/null; then
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

  # Attempt to download with curl, if found. If successful, quick return
  if command -v curl >/dev/null; then
    info "Downlading $_url to $_dst (curl)"
    _orig_flags="$-"
    set +e
    curl -sSfL "$_url" -o "$_dst"
    code="$?"
    set "-$(echo "$_orig_flags" | sed s/s//g)"
    if [ $code -eq 0 ]; then
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

  unset _url _dst _code _orig_flags
  # If we reach this point, wget and curl have failed and we're out of options
  die "Downloading requires SSL-enabled 'curl' or 'wget' on PATH"
}

insert_libsh() {
  local release="$1"
  local target="$2"

  local libsh rendered
  libsh="$(mktemp_file)"
  cleanup_file "$libsh"
  rendered="$(mktemp_file)"
  cleanup_file "$rendered"

  section "Inserting libsh.sh '$release' into $target"

  download_and_extract "$release" "$libsh"

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

is_mode_valid() {
  local mode="$1"

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
  need_cmd awk
  need_cmd git

  {
    # The `--sort` option on `git ls-remote` was introduced in Git 2.18.0, so
    # if it's older then we'll have to use GNU/sort's `--version-sort` to help.
    # Oi
    local version
    version="$(git --version | awk '{ print $NF }')"
    if version_ge "$version" 2 18; then
      git ls-remote --tags --sort=version:refname \
        https://github.com/fnichol/libsh.git
    else
      need_cmd sort

      git ls-remote --tags https://github.com/fnichol/libsh.git \
        | sort --field-separator='/' --key=3 --version-sort
    fi
  } | awk -F/ '
        ($NF ~ /^v[0-9]+\./ && $NF !~ /\^\{\}$/) {
          last = $NF
        }

        END {
          sub(/^v/, "", last)
          print last
        }
      '
}

# TODO: add to libsh.sh
setup_traps() {
  local _sig
  # Very nice, portable signal handling thanks to:
  # https://unix.stackexchange.com/a/240736
  for _sig in HUP INT QUIT ALRM TERM; do
    trap "
      trap_cleanup_files
      trap - $_sig EXIT
      kill -s $_sig "'"$$"' "$_sig"
  done
  trap trap_cleanup_files EXIT

  unset _sig
}

vendor_libsh() {
  need_cmd cat
  need_cmd touch
  need_cmd dirname
  need_cmd mkdir

  local release="$1"
  local target="$2"

  local tmpfile
  tmpfile="$(mktemp_file)"
  cleanup_file "$tmpfile"

  section "Vendoring libsh.sh '$release' to $target"

  download_and_extract "$release" "$tmpfile"

  info "Copying libsh to $target"
  mkdir -p "$(dirname "$target")"
  touch "$target"
  cat "$tmpfile" >"$target"
}

version_ge() {
  need_cmd awk

  local version="$1"
  local maj="$2"
  local min="$3"

  [ "$(echo "$version" | awk -F'.' '{ print $1 }')" -ge "$maj" ] \
    && [ "$(echo "$version" | awk -F'.' '{ print $2 }')" -ge "$min" ]
}

# TODO: add to libsh.sh
warn() {
  local _msg
  _msg="$1"

  case "${TERM:-}" in
    *term | xterm-* | rxvt | screen | screen-*)
      printf -- "\033[1;31;40m!!! \033[1;37;40m%s\033[0m\n" "$_msg"
      ;;
    *)
      printf -- "!!! %s\n" "$_msg"
      ;;
  esac

  unset _msg
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
# version: 0.1.0
# source: https://github.com/fnichol/libsh/tree/0.1.0
# archive: https://github.com/fnichol/libsh/archive/0.1.0.tar.gz
#

if [ -n "${KSH_VERSION:-}" ]; then
  # Evil, nasty, wicked hack to ignore calls to `local <var>`, on the strict
  # assumption that no initialization will take place, i.e. `local
  # <var>=<value>`. If this assumption holds, this implementation fakes a
  # `local` keyword for ksh. The `eval` is used as some versions of dash will
  # error with "Syntax error: Bad function name" whether or not it's in a
  # conditional (likely in the parser/ast phase) (src:
  # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=619786). Also, `shfmt`
  # does *not* like a function called `local` so...another dodge here. TBD on
  # this one, folks...
  eval "local() { return 0; }"
fi

# Tracks a file for later cleanup in a trap handler.
#
# This function can be called immediately after a temp file is created, before
# a file is created, or long after a file exists. When used in combination with
# [`trap_cleanup_files`], all files registered by calling `cleanup_file` will
# be removed if they exist when `trap_cleanup_files` is invoked.
#
# * `@param [String]` path to file
# * `@return 0` if successful
# * `@return 1` if a temp file could not be created
#
# [`trap_cleanup_files`]: #function.trap_cleanup_files
#
# # Global Variables
#
# * `__CLEANUP_FILES__` used to track the collection of files to clean up whose
#   value is a file. If not declared or set, this function will set it up.
#
# # Examples
#
# Basic usage:
#
# ```sh
# file="$(mktemp_file)"
# cleanup_file "$file"
# # do work on file, etc.
# ```
cleanup_file() {
  local _file
  _file="$1"

  # If a tempfile hasn't been setup yet, create it
  if [ -z "${__CLEANUP_FILES__:-}" ]; then
    __CLEANUP_FILES__="$(mktemp_file)"

    # If the result string is empty, tempfile wasn't created so report failure
    if [ -z "$__CLEANUP_FILES__" ]; then
      return 1
    fi
  fi

  echo "$_file" >>"$__CLEANUP_FILES__"
  unset _file
}

# Prints an error message to standard error and returns a non-zero exit code.
#
# * `@param [String]` warning text
# * `@stderr` warning text message
# * `@return 1` to signal user intended a failure
#
# # Environment Variables
#
# * `TERM` used to determine whether or not the terminal is capable of printing
#   colored output.
#
# # Examples
#
# Basic usage:
#
# ```sh
# die "No program to download tarball"
# ```
die() {
  local _msg
  _msg="$1"

  case "${TERM:-}" in
    *term | xterm-* | rxvt | screen | screen-*)
      printf -- "\n\033[1;31;40mxxx \033[1;37;40m%s\033[0m\n\n" "$_msg" >&2
      ;;
    *)
      printf -- "\nxxx %s\n\n" "$_msg" >&2
      ;;
  esac

  unset _msg
  return 1
}

# Prints an information, detailed step to standard out.
#
# * `@param [String]` informational text
# * `@stdout` informational heading text
# * `@return 0` if successful
#
# # Environment Variables
#
# * `TERM` used to determine whether or not the terminal is capable of printing
#   colored output.
#
# # Examples
#
# Basic usage:
#
# ```sh
# info "Downloading tarball"
# ```
info() {
  local _msg
  _msg="$1"

  case "${TERM:-}" in
    *term | xterm-* | rxvt | screen | screen-*)
      printf -- "\033[1;36;40m  - \033[1;37;40m%s\033[0m\n" "$_msg"
      ;;
    *)
      printf -- "  - %s\n" "$_msg"
      ;;
  esac

  unset _msg
}

# Creates a temporary file and prints the name to standard output.
#
# It looks like the maximally portable way of calling `mktemp` to create a file
# is to provide no arguments (therefore having no control over the naming). All
# tested invocations will create a file in each platform's suitable temporary
# directory.
#
# * `@stdout` path to temporary file
# * `@return 0` if successful
#
# # Examples
#
# Basic usage:
#
# ```sh
# file="$(mktemp_file)"
# # use file
# ```
mktemp_file() {
  mktemp
}

# Determines whether or not a program is available on the system PATH.
#
# * `@param [String] program name
# * `@stderr` a warning message is printed if program cannot be found
# * `@return 0` if program is found on system PATH
# * `@return 1` if program is not found
#
# # Environment Variables
#
# * `PATH` indirectly used to search for the program
#
# # Examples
#
# Basic usage, when used as a guard or pre-requisite in a function:
#
# ```sh
# need_cmd git
# ```
#
# This function can also be used as a conditional check, however the standard
# error may have to be redirected:
#
# ```sh
# if need_cmd git 2>/dev/null; then
#   echo "Found Git"
# fi
# ```
need_cmd() {
  local _cmd
  _cmd="$1"

  if ! command -v "$_cmd" >/dev/null 2>&1; then
    die "Required command '$_cmd' not found on PATH"
    return 1
  fi

  unset _cmd
}

# Prints program version information to standard out.
#
# The minimal implementation will output the program name and version,
# separated with a space, such as `my-program 1.2.3`. However, if the Git
# program is detected and the current working directory is under a Git
# repository, then more information will be displayed. Namely, the short Git
# SHA and author commit date will be appended in parenthesis at end of the
# line. For example, `my-program 1.2.3 (abc123 2000-01-02)`.
#
# If verbose mode is enable by setting the optional third argument to a
# non-empty value, then a detailed version report will be appended to the
# single line "simple mode". Assuming that the Git program is available and the
# current working directory is under a Git repository, then three extra lines
# will be emitted:
#
# 1. `release: 1.2.3` the version string
# 2. `commit-hash: abc...` the full Git SHA of the current commit
# 3. `commit-date: 2000-01-02` the author commit date of the current commit
#
# If Git is not found, then only the `release: 1.2.3` line will be emitted for
# verbose mode.
#
# Finally, if the Git repository is not "clean", that is if it contains
# uncommitted or modified files, a `-dirty` suffix will be added to the short
# and long Git SHA refs to signal that the implementation may not perfectly
# correspond to a SHA commit.
#
# * `@param [String] program name
# * `@param [String] version string
# * `@param [optional, String] verbose mode set if non-empty
# * `@stdout` version information
# * `@return 0` if successful
#
# Note that the implementation for this function was inspired by Rust's `cargo
# version`, see: https://git.io/fjsOh
#
# # Examples
#
# Basic usage:
#
# ```sh
# print_version "my-program" "1.2.3"
# ```
#
# A non-empty third argument puts the function in verbose mode and more detail
# is output to standard out:
#
# ```sh
# print_version "my-program" "1.2.3" "true"
# ```
#
# An empty third argument is the same as only providing two arguments (i.e.
# non-verbose):
#
# ```sh
# print_version "my-program" "1.2.3" ""
# ```
print_version() {
  local _program _version _verbose
  _program="$1"
  shift
  _version="$1"
  shift
  _verbose=""
  if [ -n "${1:-}" ]; then
    _verbose="$1"
  fi

  if need_cmd git 2>/dev/null \
    && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local _date _sha
    _date="$(git show -s --format=%ad --date=short)"
    _sha="$(git show -s --format=%h)"
    if ! git diff-index --quiet HEAD --; then
      _sha="${_sha}-dirty"
    fi

    echo "$_program $_version ($_sha $_date)"

    if [ -n "$_verbose" ]; then
      local _long_sha
      _long_sha="$(git show -s --format=%H)"
      case "$_sha" in
        *-dirty) _long_sha="${_long_sha}-dirty" ;;
      esac

      echo "release: $_version"
      echo "commit-hash: $_long_sha"
      echo "commit-date: $_date"

      unset _long_sha
    fi

    unset _date _sha
  else
    echo "$_program $_version"

    if [ -n "$_verbose" ]; then
      echo "release: $_version"
    fi
  fi

  unset _program _version _verbose
}

# Prints a section-delimiting header to standard out.
#
# * `@param [String]` section heading text
# * `@stdout` section heading text
# * `@return 0` if successful
#
# # Environment Variables
#
# * `TERM` used to determine whether or not the terminal is capable of printing
#   colored output.
#
# # Examples
#
# Basic usage:
#
# ```sh
# section "Building project"
# ```
section() {
  local _msg
  _msg="$1"

  case "${TERM:-}" in
    *term | xterm-* | rxvt | screen | screen-*)
      printf -- "\033[1;36;40m--- \033[1;37;40m%s\033[0m\n" "$_msg"
      ;;
    *)
      printf -- "--- %s\n" "$_msg"
      ;;
  esac

  unset _msg
}

# Removes any tracked files registered via [`cleanup_file`].
#
# * `@return 0` whether or not an error has occurred
#
# [`cleanup_file`]: #function.cleanup_file
#
# # Global Variables
#
# * `__CLEANUP_FILES__` used to track the collection of files to clean up whose
#   value is a file. If not declared or set, this function will assume there is
#   no work to do.
#
# # Examples
#
# Basic usage:
#
# ```sh
# trap trap_cleanup_files 1 2 3 15 ERR EXIT
#
# file="$(mktemp_file)"
# cleanup_file "$file"
# # do work on file, etc.
# ```
trap_cleanup_files() {
  set +e

  if [ -n "${__CLEANUP_FILES__:-}" ] && [ -f "$__CLEANUP_FILES__" ]; then
    while read -r file; do
      rm -f "$file"
    done <"$__CLEANUP_FILES__"
    rm -f "$__CLEANUP_FILES__"
  fi
}

# END: libsh.sh

main "$@"
