#!/usr/bin/env sh

# Completes printing an informational, detailed step to standard out which has
# no output, started with `info_start`
#
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
# info_end
# ```
info_end() {
  case "${TERM:-}" in
    *term | alacritty | rxvt | screen | screen-* | tmux | tmux-* | xterm-*)
      printf -- "\033[1;37;40m%s\033[0m\n" "done."
      ;;
    *)
      printf -- "%s\n" "done."
      ;;
  esac
}
