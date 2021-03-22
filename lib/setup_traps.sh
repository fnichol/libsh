#!/usr/bin/env sh
# shellcheck disable=SC2039

# Sets up traps for `EXIT` and common signals with the given cleanup function.
#
# In addition to `EXIT`, the `HUP`, `INT`, `QUIT`, `ALRM`, and `TERM` signals
# are also covered.
#
# This implementation was based on a very nice, portable signal handling thread
# thanks to: https://unix.stackexchange.com/a/240736
#
# * `@param [String]` name of function to run with traps
#
# # Examples
#
# Basic usage with a simple "hello world" cleanup function:
#
# ```sh
# hello_trap() {
#   echo "Hello, trap!"
# }
#
# setup_traps hello_trap
# ```
#
# If the cleanup is simple enough to be a one-liner, you can provide the
# command as the single argument:
#
# ```sh
# setup_traps "echo 'Hello, World!'"
# ```
setup_traps() {
  local _sig
  for _sig in HUP INT QUIT ALRM TERM; do
    trap "
      $1
      trap - $_sig EXIT
      kill -s $_sig "'"$$"' "$_sig"
  done

  if [ -n "${ZSH_VERSION:-}" ]; then
    # Zsh uses the `EXIT` trap for a function if declared in a function.
    # Instead, use the `zshexit()` hook function which targets the exiting of a
    # shell interpreter. Additionally, a function in Zsh is not a closure over
    # outer variables, so we'll use `eval` to construct the function body
    # containing the cleanup function to invoke.
    #
    # See:
    # * https://stackoverflow.com/a/22794374
    # * http://zsh.sourceforge.net/Doc/Release/Functions.html#Hook-Functions
    eval "zshexit() { eval '$1'; }"
  else
    # shellcheck disable=SC2064
    trap "$1" EXIT
  fi

  unset _sig
}
