#!/usr/bin/env sh
# shellcheck disable=SC2039

# Prints an informational, detailed step to standard out.
#
# * `@param [String]` informational text
# * `@stdout` informational heading text
# * `@return 0` if successful
#
# # Environment Variables
#
# * `TERM` used to determine whether or not the terminal is capable of printing
#   colored output.
#
# # Examples
#
# Basic usage:
#
# ```sh
# info "Downloading tarball"
# ```
info() {
  case "${TERM:-}" in
    *term | alacritty | rxvt | screen | screen-* | tmux | tmux-* | xterm-*)
      printf -- "\033[1;36;40m  - \033[1;37;40m%s\033[0m\n" "$1"
      ;;
    *)
      printf -- "  - %s\n" "$1"
      ;;
  esac
}
