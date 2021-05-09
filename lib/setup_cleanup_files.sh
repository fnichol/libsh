#!/usr/bin/env sh

. "lib/mktemp_file.sh"

# Sets up state to track files for later cleanup in a trap handler.
#
# This function is typically used in combination with [`cleanup_file`] and
# [`trap_cleanup_files`].
#
# * `@return 0` if successful
# * `@return 1` if a temp file could not be created
#
# # Global Variables
#
# * `__CLEANUP_FILES__` used to track the collection of files to clean up whose
#   value is a file. If not declared or set, this function will set it up.
# * `__CLEANUP_FILES_SETUP__` used to track if the `__CLEANUP_FILES__`
# variable has been set up for the current process
#
# # Examples
#
# Basic usage:
#
# ```sh
# setup_cleanup_files
# ```
#
# Used with [`cleanup_file`], [`setup_traps`], and [`trap_cleanup_files`]:
#
# ```sh
# setup_cleanup_files
# setup_traps trap_cleanup_files
#
# file="$(mktemp_file)"
# cleanup_file "$file"
# # do work on file, etc.
# ```
#
# [`cleanup_file`]: #cleanup_file
# [`setup_traps`]: #setup_traps
# [`trap_cleanup_files`]: #trap_cleanup_files
setup_cleanup_files() {
  if [ "${__CLEANUP_FILES_SETUP__:-}" != "$$" ]; then
    unset __CLEANUP_FILES__
    __CLEANUP_FILES_SETUP__="$$"
    export __CLEANUP_FILES_SETUP__
  fi

  # If a tempfile hasn't been setup yet, create it
  if [ -z "${__CLEANUP_FILES__:-}" ]; then
    __CLEANUP_FILES__="$(mktemp_file)"

    # If the result string is empty, tempfile wasn't created so report failure
    if [ -z "$__CLEANUP_FILES__" ]; then
      return 1
    fi

    export __CLEANUP_FILES__
  fi
}
