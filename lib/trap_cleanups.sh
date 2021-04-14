#!/usr/bin/env sh

. "lib/trap_cleanup_directories.sh"
. "lib/trap_cleanup_files.sh"

# Removes any tracked files and directories registered via [`cleanup_file`]
# and [`cleanup_directory`] respectively.
#
# * `@return 0` whether or not an error has occurred
#
# [`cleanup_directory`]: #cleanup_directory
# [`cleanup_file`]: #cleanup_file
#
# # Examples
#
# Basic usage:
#
# ```sh
# trap trap_cleanups 1 2 3 15 ERR EXIT
# ```
#
# Used with [`setup_traps`]:
#
# ```sh
# setup_traps trap_cleanups
# ```
#
# [`setup_traps`]: #setup_traps
trap_cleanups() {
  set +e

  trap_cleanup_directories
  trap_cleanup_files
}
