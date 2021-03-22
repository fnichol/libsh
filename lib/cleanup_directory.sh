#!/usr/bin/env sh
# shellcheck disable=SC2039

. "lib/mktemp_file.sh"

# Tracks a directory for later cleanup in a trap handler.
#
# This function can be called immediately after a temp directory is created,
# before a directory is created, or long after a directory exists. When used in
# combination with [`trap_cleanup_directories`], all directories registered by
# calling `cleanup_directory` will be removed if they exist when
# `trap_cleanup_directories` is invoked.
#
# * `@param [String]` path to directory
# * `@return 0` if successful
# * `@return 1` if a temp file could not be created
#
# [`trap_cleanup_directories`]: #function.trap_cleanup_directories
#
# # Global Variables
#
# * `__CLEANUP_DIRECTORIES__` used to track the collection of directories to
#   clean up whose value is a file. If not declared or set, this function will
#   set it up.
#
# # Examples
#
# Basic usage:
#
# ```sh
# dir="$(mktemp_directory)"
# cleanup_directory "$dir"
# # do work on directory, etc.
# ```
cleanup_directory() {
  # If a tempfile hasn't been setup yet, create it
  if [ -z "${__CLEANUP_DIRECTORIES__:-}" ]; then
    __CLEANUP_DIRECTORIES__="$(mktemp_file)"

    # If the result string is empty, tempfile wasn't created so report failure
    if [ -z "$__CLEANUP_DIRECTORIES__" ]; then
      return 1
    fi
  fi

  echo "$1" >>"$__CLEANUP_DIRECTORIES__"
}
