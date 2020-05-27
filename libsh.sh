#!/usr/bin/env sh
# shellcheck disable=SC2039

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
# version: @@version@@
# commit-hash: @@commit_hash@@
# commit-date: @@commit_date@@
# source: https://github.com/fnichol/libsh/tree/v@@version@@
# archive: https://github.com/fnichol/libsh/archive/v@@version@@.tar.gz
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

# Determines whether or not a program is available on the system PATH.
#
# * `@param [String] program name
# * `@return 0` if program is found on system PATH
# * `@return 1` if program is not found
#
# # Environment Variables
#
# * `PATH` indirectly used to search for the program
#
# # Examples
#
# Basic usage, when used as a conditional check:
#
# ```sh
# if check_cmd git; then
#   echo "Found Git"
# fi
check_cmd() {
  local _cmd
  _cmd="$1"

  if ! command -v "$_cmd" >/dev/null 2>&1; then
    unset _cmd
    return 1
  else
    unset _cmd
    return 0
  fi
}

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

# Prints an error message to standard error and exits with a non-zero exit
# code.
#
# * `@param [String]` warning text
# * `@stderr` warning text message
#
# # Environment Variables
#
# * `TERM` used to determine whether or not the terminal is capable of printing
#   colored output.
#
# # Notes
#
# This function calls `exit` and will **not** return.
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
    *term | alacritty | rxvt | screen | screen-* | tmux | tmux-* | xterm-*)
      printf -- "\n\033[1;31;40mxxx \033[1;37;40m%s\033[0m\n\n" "$_msg" >&2
      ;;
    *)
      printf -- "\nxxx %s\n\n" "$_msg" >&2
      ;;
  esac

  unset _msg
  exit 1
}

# Downloads the contents at the given URL to the given local file.
#
# This implementation attempts to use the `curl` program with a fallback to the
# `wget` program and a final fallback to the `ftp` program. The first download
# program to succeed is used and if all fail, this function returns a non-zero
# code.
#
# * `@param [String]` download URL
# * `@param [String]` destination file
# * `@return 0` if a download was successful
# * `@return 1` if a download was not successful
#
# # Notes
#
# At least one of `curl`, `wget`, or `ftp must be compiled with SSL/TLS support
# to be able to download from `https` sources.
#
# # Examples
#
# Basic usage:
#
# ```sh
# download http://example.com/file.txt /tmp/file.txt
# ```
download() {
  local _url _dst _code _orig_flags
  _url="$1"
  _dst="$2"

  need_cmd sed

  # Attempt to download with curl, if found. If successful, quick return
  if check_cmd curl; then
    info "Downloading $_url to $_dst (curl)"
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

  # Attempt to download with wget, if found. If successful, quick return
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

  # Attempt to download with ftp, if found. If successful, quick return
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
  # If we reach this point, curl, wget and ftp have failed and we're out of
  # options
  warn "Downloading requires SSL-enabled 'curl', 'wget', or 'ftp' on PATH"
  return 1
}

# Indents the output from a command while preserving the command's exit code.
#
# In minimal/POSIX shells there is no support for `set -o pipefail` which means
# that the exit code of the first command in a shell pipeline won't be
# addressable in an easy way. This implementation uses a temp file to ferry the
# original command's exit code from a subshell back into the main function. The
# output can be aligned with a pipe to `sed` as before but now we have an
# implementation which mimicks a `set -o pipefail` which should work on all
# Bourne shells. Note that the `set -o errexit` is disabled during the
# command's invocation so that its exit code can be captured.
#
# Based on implementation from: https://stackoverflow.com/a/54931544
#
# * `@param [String[]]` command and arguments
# * `@return` the exit code of the command which was executed
#
# # Notes
#
# In order to preserve the output order of the command, the `stdout` and
# `stderr` streams are combined, so the command will not emit its `stderr`
# output to the caller's `stderr` stream.
#
# # Examples
#
# Basic usage:
#
# ```sh
# indent cat /my/file
# ```
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

# Prints an informational, detailed step to standard out.
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
    *term | alacritty | rxvt | screen | screen-* | tmux | tmux-* | xterm-*)
      printf -- "\033[1;36;40m  - \033[1;37;40m%s\033[0m\n" "$_msg"
      ;;
    *)
      printf -- "  - %s\n" "$_msg"
      ;;
  esac

  unset _msg
}

# Creates a temporary directory and prints the name to standard output.
#
# Most system use the first no-argument version, however Mac OS X 10.10
# (Yosemite) and older don't allow the no-argument version, hence the second
# fallback version.
#
# All tested invocations will create a file in each platform's suitable
# temporary directory.
#
# * `@stdout` path to temporary directory
# * `@return 0` if successful
#
# # Examples
#
# Basic usage:
#
# ```sh
# dir="$(mktemp_directory)"
# # use directory
# ```
mktemp_directory() {
  mktemp -d 2>/dev/null || mktemp -d -t tmp
}

# Creates a temporary file and prints the name to standard output.
#
# Most systems use the first no-argument version, however Mac OS X 10.10
# (Yosemite) and older don't allow the no-argument version, hence the second
# fallback version.

# All tested invocations will create a file in each platform's suitable
# temporary directory.
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
  mktemp 2>/dev/null || mktemp -t tmp
}

# Prints an error message and exits with a non-zero code if the program is not
# available on the system PATH.
#
# * `@param [String] program name
# * `@stderr` a warning message is printed if program cannot be found
#
# # Environment Variables
#
# * `PATH` indirectly used to search for the program
#
# # Notes
#
# If the program is not found, this function calls `exit` and will **not**
# return.
#
# # Examples
#
# Basic usage, when used as a guard or pre-requisite in a function:
#
# ```sh
# need_cmd git
# ```
need_cmd() {
  local _cmd
  _cmd="$1"

  if ! check_cmd "$_cmd"; then
    die "Required command '$_cmd' not found on PATH"
  fi

  unset _cmd
  return 0
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

  if check_cmd git \
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
    *term | alacritty | rxvt | screen | screen-* | tmux | tmux-* | xterm-*)
      printf -- "\033[1;36;40m--- \033[1;37;40m%s\033[0m\n" "$_msg"
      ;;
    *)
      printf -- "--- %s\n" "$_msg"
      ;;
  esac

  unset _msg
}

# Sets up traps for `EXIT` and common signals with the given cleanup function.
#
# In addition to `EXIT`, the `HUP`, `INT`, `QUIT`, `ALRM`, and `TERM` signals
# are also covered.
#
# This implementation was based on a very nice, portable signal handling thread
# thanks to: https://unix.stackexchange.com/a/240736
#
# * `@param [String]` name of function to run with traps
#
# # Examples
#
# Basic usage with a simple "hello world" cleanup function:
#
# ```sh
# hello_trap() {
#   echo "Hello, trap!"
# }
#
# setup_traps hello_trap
# ```
#
# If the cleanup is simple enough to be a one-liner, you can provide the
# command as the single argument:
#
# ```sh
# setup_traps "echo 'Hello, World!'"
# ```
setup_traps() {
  local _trap_fun
  _trap_fun="$1"

  local _sig
  for _sig in HUP INT QUIT ALRM TERM; do
    trap "
      $_trap_fun
      trap - $_sig EXIT
      kill -s $_sig "'"$$"' "$_sig"
  done

  if [ -n "${ZSH_VERSION:-}" ]; then
    # Zsh uses the `EXIT` trap for a function if declared in a function.
    # Instead, use the `zshexit()` hook function which targets the exiting of a
    # shell interpreter. Additionally, a function in Zsh is not a closure over
    # outer variables, so we'll use `eval` to construct the function body
    # containing the cleanup function to invoke.
    #
    # See:
    # * https://stackoverflow.com/a/22794374
    # * http://zsh.sourceforge.net/Doc/Release/Functions.html#Hook-Functions
    eval "zshexit() { eval '$_trap_fun'; }"
  else
    # shellcheck disable=SC2064
    trap "$_trap_fun" EXIT
  fi

  unset _trap_fun _sig
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

# Prints a warning message to standard out.
#
# * `@param [String]` warning text
# * `@stdout` warning heading text
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
# warn "Could not connect to service"
# ```
warn() {
  local _msg
  _msg="$1"

  case "${TERM:-}" in
    *term | alacritty | rxvt | screen | screen-* | tmux | tmux-* | xterm-*)
      printf -- "\033[1;31;40m!!! \033[1;37;40m%s\033[0m\n" "$_msg"
      ;;
    *)
      printf -- "!!! %s\n" "$_msg"
      ;;
  esac

  unset _msg
}

# END: libsh.sh
