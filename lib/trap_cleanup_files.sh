#!/usr/bin/env sh
# shellcheck disable=SC2039

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
    local _file
    while read -r _file; do
      rm -f "$_file"
    done <"$__CLEANUP_FILES__"
    unset _file
    rm -f "$__CLEANUP_FILES__"
  fi
}
