#!/usr/bin/env sh

. "lib/mktemp_file.sh"

# Sets up state to track directories for later cleanup in a trap handler.
#
# This function is typically used in combination with [`cleanup_directory`] and
# [`trap_cleanup_directories`].
#
# * `@return 0` if successful
# * `@return 1` if a temp file could not be created
#
# # Global Variables
#
# * `__CLEANUP_DIRECTORIES__` used to track the collection of directories to
# clean up whose value is a file. If not declared or set, this function will
# set it up.
#
# # Examples
#
# Basic usage:
#
# ```sh
# setup_cleanup_directories
# ```
#
# Used with [`cleanup_directory`], [`setup_traps`], and
# [`trap_cleanup_directories`]:
#
# ```sh
# setup_cleanup_directories
# setup_traps trap_cleanup_directories
#
# dir="$(mktemp_directory)"
# cleanup_directory "$dir"
# # do work on directory, etc.
# ```
#
# [`cleanup_file`]: #cleanup_file
# [`setup_traps`]: #setup_traps
# [`trap_cleanup_directories`]: #trap_cleanup_directories
setup_cleanup_directories() {
  # If a tempfile hasn't been setup yet, create it
  if [ -z "${__CLEANUP_DIRECTORIES__:-}" ]; then
    __CLEANUP_DIRECTORIES__="$(mktemp_file)"

    # If the result string is empty, tempfile wasn't created so report failure
    if [ -z "$__CLEANUP_DIRECTORIES__" ]; then
      return 1
    fi

    export __CLEANUP_DIRECTORIES__
  fi
}
