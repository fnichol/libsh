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
  local file="$1"

  # If a tempfile hasn't been setup yet, create it
  if [ -z "${__CLEANUP_FILES__:-}" ]; then
    __CLEANUP_FILES__="$(mktemp_file)"

    # If the result string is empty, tempfile wasn't created so report failure
    if [ -z "$__CLEANUP_FILES__" ]; then
      return 1
    fi
  fi

  echo "$file" >>"$__CLEANUP_FILES__"
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
  local msg="$1"

  case "${TERM:-}" in
    *term | xterm-* | rxvt | screen | screen-*)
      printf -- "\n\033[1;31;40mxxx \033[1;37;40m%s\033[0m\n\n" "$msg" >&2
      ;;
    *)
      printf -- "\nxxx %s\n\n" "$msg" >&2
      ;;
  esac

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
  local msg="$1"

  case "${TERM:-}" in
    *term | xterm-* | rxvt | screen | screen-*)
      printf -- "\033[1;36;40m  - \033[1;37;40m%s\033[0m\n" "$msg"
      ;;
    *)
      printf -- "  - %s\n" "$msg"
      ;;
  esac
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
  local cmd="$1"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    die "Required command '$cmd' not found on PATH"
  fi
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
  local program="$1"
  shift
  local version="$1"
  shift
  local verbose=""
  if [ -n "${1:-}" ]; then
    verbose="$1"
  fi

  if need_cmd git 2>/dev/null \
    && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local date sha
    date="$(git show -s --format=%ad --date=short)"
    sha="$(git show -s --format=%h)"
    if ! git diff-index --quiet HEAD --; then
      sha="${sha}-dirty"
    fi

    echo "$program $version ($sha $date)"

    if [ -n "$verbose" ]; then
      local long_sha
      long_sha="$(git show -s --format=%H)"
      case "$sha" in
        *-dirty) long_sha="${long_sha}-dirty" ;;
      esac

      echo "release: $version"
      echo "commit-hash: $long_sha"
      echo "commit-date: $date"
    fi
  else
    echo "$program $version"

    if [ -n "$verbose" ]; then
      echo "release: $version"
    fi
  fi
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
  local msg="$1"

  case "${TERM:-}" in
    *term | xterm-* | rxvt | screen | screen-*)
      printf -- "\033[1;36;40m--- \033[1;37;40m%s\033[0m\n" "$msg"
      ;;
    *)
      printf -- "--- %s\n" "$msg"
      ;;
  esac
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
