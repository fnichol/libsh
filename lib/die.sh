#!/usr/bin/env sh
# shellcheck disable=SC2039

# Prints an error message to standard error and exits with a non-zero exit
# code.
#
# * `@param [String]` warning text
# * `@stderr` warning text message
#
# # Environment Variables
#
# * `TERM` used to determine whether or not the terminal is capable of printing
#   colored output.
#
# # Notes
#
# This function calls `exit` and will **not** return.
#
# # Examples
#
# Basic usage:
#
# ```sh
# die "No program to download tarball"
# ```
die() {
  case "${TERM:-}" in
    *term | alacritty | rxvt | screen | screen-* | tmux | tmux-* | xterm-*)
      printf -- "\n\033[1;31;40mxxx \033[1;37;40m%s\033[0m\n\n" "$1" >&2
      ;;
    *)
      printf -- "\nxxx %s\n\n" "$1" >&2
      ;;
  esac

  exit 1
}
