#!/usr/bin/env sh

. "lib/setup_cleanup_files.sh"

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
# [`trap_cleanup_files`]: #trap_cleanup_files
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
  setup_cleanup_files
  echo "$1" >>"$__CLEANUP_FILES__"
}
