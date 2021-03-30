#!/usr/bin/env sh

. "lib/check_cmd.sh"
. "lib/die.sh"

# Prints an error message and exits with a non-zero code if the program is not
# available on the system PATH.
#
# * `@param [String] program name
# * `@stderr` a warning message is printed if program cannot be found
#
# # Environment Variables
#
# * `PATH` indirectly used to search for the program
#
# # Notes
#
# If the program is not found, this function calls `exit` and will **not**
# return.
#
# # Examples
#
# Basic usage, when used as a guard or pre-requisite in a function:
#
# ```sh
# need_cmd git
# ```
need_cmd() {
  if ! check_cmd "$1"; then
    die "Required command '$1' not found on PATH"
  fi
}
