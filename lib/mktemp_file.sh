#!/usr/bin/env sh

. "lib/need_cmd.sh"

# Creates a temporary file and prints the name to standard output.
#
# Most systems use the first no-argument version, however Mac OS X 10.10
# (Yosemite) and older don't allow the no-argument version, hence the second
# fallback version.

# All tested invocations will create a file in each platform's suitable
# temporary directory.
#
# * `@param [optional, String]` parent directory
# * `@stdout` path to temporary file
# * `@return 0` if successful
#
# # Examples
#
# Basic usage:
#
# ```sh
# file="$(mktemp_file)"
# # use file
# ```
#
# With a custom parent directory:
#
# ```sh
# dir="$(mktemp_file $HOME)"
# # use file
# ```

# shellcheck disable=SC2120
mktemp_file() {
  need_cmd mktemp

  if [ -n "${1:-}" ]; then
    mktemp "$1/tmp.XXXXXX"
  else
    mktemp 2>/dev/null || mktemp -t tmp
  fi
}
