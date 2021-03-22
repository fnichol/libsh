#!/usr/bin/env sh
# shellcheck disable=SC2039

. "lib/need_cmd.sh"

# Creates a temporary directory and prints the name to standard output.
#
# Most system use the first no-argument version, however Mac OS X 10.10
# (Yosemite) and older don't allow the no-argument version, hence the second
# fallback version.
#
# All tested invocations will create a file in each platform's suitable
# temporary directory.
#
# * `@param [optional, String] parent directory
# * `@stdout` path to temporary directory
# * `@return 0` if successful
#
# # Examples
#
# Basic usage:
#
# ```sh
# dir="$(mktemp_directory)"
# # use directory
# ```
#
# With a custom parent directory:
#
# ```sh
# dir="$(mktemp_directory $HOME)"
# # use directory
# ```

# shellcheck disable=SC2120
mktemp_directory() {
  need_cmd mktemp

  if [ -n "${1:-}" ]; then
    mktemp -d "$1/tmp.XXXXXX"
  else
    mktemp -d 2>/dev/null || mktemp -d -t tmp
  fi
}
