#!/usr/bin/env sh
# shellcheck disable=SC2039

. "lib/check_cmd.sh"

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
