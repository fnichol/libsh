#!/usr/bin/env sh

. "lib/setup_cleanup_directories.sh"
. "lib/setup_cleanup_files.sh"

# Sets up state to track files and directories for later cleanup in a trap
# handler.
#
# This function is typically used in combination with [`cleanup_file`] and
# [`cleanup_directory`] as well as [`trap_cleanups`].
#
# * `@return 0` if successful
# * `@return 1` if the setup was not successful
#
# # Examples
#
# Basic usage:
#
# ```sh
# setup_cleanups
# ```
#
# Used with [`cleanup_directory`], [`cleanup_file`], [`setup_traps`], and
# [`trap_cleanups`]:
#
# ```sh
# setup_cleanups
# setup_traps trap_cleanups
#
# file="$(mktemp_file)"
# cleanup_file "$file"
# # do work on file, etc.
#
# dir="$(mktemp_directory)"
# cleanup_directory "$dir"
# # do work on directory, etc.
# ```
#
# [`cleanup_directory`]: #cleanup_directory
# [`cleanup_file`]: #cleanup_file
# [`setup_traps`]: #setup_traps
# [`trap_cleanups`]: #trap_cleanups
setup_cleanups() {
  setup_cleanup_directories
  setup_cleanup_files
}
