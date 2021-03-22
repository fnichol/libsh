#!/usr/bin/env sh
# shellcheck disable=SC2039

. "lib/mktemp_file.sh"
. "lib/need_cmd.sh"

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
