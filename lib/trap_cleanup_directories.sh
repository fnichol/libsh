#!/usr/bin/env sh
# shellcheck disable=SC2039

# Removes any tracked directories registered via [`cleanup_directory`].
#
# * `@return 0` whether or not an error has occurred
#
# [`cleanup_directory`]: #function.cleanup_directory
#
# # Global Variables
#
# * `__CLEANUP_DIRECTORIES__` used to track the collection of files to clean up
#   whose value is a file. If not declared or set, this function will assume
#   there is no work to do.
#
# # Examples
#
# Basic usage:
#
# ```sh
# trap trap_cleanup_directories 1 2 3 15 ERR EXIT
#
# dir="$(mktemp_directory)"
# cleanup_directory "$dir"
# # do work on directory, etc.
# ```
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
