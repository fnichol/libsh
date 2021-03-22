#!/usr/bin/env sh
# shellcheck disable=SC2039

# Determines whether or not a program is available on the system PATH.
#
# * `@param [String] program name
# * `@return 0` if program is found on system PATH
# * `@return 1` if program is not found
#
# # Environment Variables
#
# * `PATH` indirectly used to search for the program
#
# # Examples
#
# Basic usage, when used as a conditional check:
#
# ```sh
# if check_cmd git; then
#   echo "Found Git"
# fi
check_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    return 1
  fi
}
