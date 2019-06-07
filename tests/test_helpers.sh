#!/usr/bin/env sh

# shellcheck disable=SC2034
commonOneTimeSetUp() {
  set -u

  __ORIG_FLAGS="$-"
  __ORIG_PATH="$PATH"
  __ORIG_TERM="$TERM"
  __ORIG_PWD="$(pwd)"

  tmppath="$SHUNIT_TMPDIR/tmp"

  stdout="$tmppath/stdout"
  stderr="$tmppath/stderr"
  expected="$tmppath/expected"
  actual="$tmppath/actual"
  template="$tmppath/template"

  fakebinpath="$SHUNIT_TMPDIR/fakebin"
}

commonSetUp() {
  # Reset set flags to its original value
  set "-$__ORIG_FLAGS"
  # Reset the value of `$PATH` to its original value
  PATH="$__ORIG_PATH"
  # Reset the value of `$TERM` to its original value
  TERM="$__ORIG_TERM"
  # Restore the original working directory
  cd "$__ORIG_PWD" || return 1
  # Clean any prior test file/directory state
  rm -rf "$tmppath" "$fakebinpath"
  # Unset any prior test variable state
  unset return_status
  # Unset any prior cleanup file variable
  unset __CLEANUP_FILES__
  # Create a scratch directory that will be removed on every test
  mkdir -p "$tmppath"
}

assertStdoutEquals() {
  if [ "$#" -eq 2 ]; then
    assertEquals "$1" "$2" "$(cat "$stdout")"
  else
    assertEquals 'stdout not equal' "$1" "$(cat "$stdout")"
  fi
}

assertStdoutStripAnsiEquals() {
  if [ "$#" -eq 2 ]; then
    assertEquals "$1" "$2" "$(stripAnsi <"$stdout")"
  else
    assertEquals 'stdout (strip ANSI) not equal' "$1" "$(stripAnsi <"$stdout")"
  fi
}

assertStdoutContains() {
  if [ "$#" -eq 2 ]; then
    assertTrue "$1" "grep -E '$2' <'$stdout'"
  else
    assertTrue 'stdout does not contain' "grep -E '$1' <'$stdout'"
  fi
}

assertStdoutStripAnsiContains() {
  stripAnsi <"$stdout" >"$tmppath/stdout_no_ansi"

  if [ "$#" -eq 2 ]; then
    assertTrue "$1" "grep -E '$2' <'$tmppath/stderr_no_ansi'"
  else
    assertTrue 'stdout does not contain' "grep -E '$1' <'$tmppath/stderr_no_ansi'"
  fi
}

assertStdoutNull() {
  assertTrue 'stdout is not empty' "[ ! -s '$stdout' ]"
}

assertStderrEquals() {
  if [ "$#" -eq 2 ]; then
    assertEquals "$1" "$2" "$(cat "$stderr")"
  else
    assertEquals 'stderr not equal' "$1" "$(cat "$stderr")"
  fi
}

assertStderrStripAnsiEquals() {
  if [ "$#" -eq 2 ]; then
    assertEquals "$1" "$2" "$(stripAnsi <"$stderr")"
  else
    assertEquals 'stderr (strip ANSI) not equal' "$1" "$(stripAnsi <"$stderr")"
  fi
}

assertStderrContains() {
  if [ "$#" -eq 2 ]; then
    assertTrue "$1" "grep -E '$2' <'$stderr'"
  else
    assertTrue 'stderr does not contain' "grep -E '$1' <'$stderr'"
  fi
}

assertStderrStripAnsiContains() {
  stripAnsi <"$stderr" >"$tmppath/stderr_no_ansi"

  if [ "$#" -eq 2 ]; then
    assertTrue "$1" "grep -E '$2' <'$tmppath/stderr_no_ansi'"
  else
    assertTrue 'stderr does not contain' "grep -E '$1' <'$tmppath/stderr_no_ansi'"
  fi
}

assertStderrNull() {
  assertTrue 'stderr is not empty' "[ ! -s '$stderr' ]"
}

run() {
  # Implementation inspired by `run` in bats
  # See: https://git.io/fjCcr
  _origFlags="$-"
  set +e
  # functrace is not supported by all shells, eg: dash
  if set -o | "${GREP:-grep}" -q '^functrace'; then
    set +T
  fi
  # errtrace is not supported by all shells, eg: ksh
  if set -o | "${GREP:-grep}" -q '^errtrace'; then
    set +E
  fi
  "$@" >"$stdout" 2>"$stderr"
  return_status=$?
  set "-$_origFlags"
  unset _origFlags

  return "$return_status"
}

run_in_sh_script() {
  cat "${0%/*}/../libsh.sh" >"$tmppath/sh_script.sh"
  echo >>"$tmppath/sh_script.sh"
  echo '"$@"' >>"$tmppath/sh_script.sh"

  run sh "$tmppath/sh_script.sh" "$@"
}

stripAnsi() {
  # The `sed` implementation on macOS does not support either `\x1b` nor the
  # `-r` flag, therefore we'll emit the correct byte with a `printf` subshell.
  sed 's,'"$(printf "\x1b")"'\[[0-9;]*[a-zA-Z],,g'
}

shell_compat() {
  if [ -n "${ZSH_VERSION:-}" ]; then
    set -o shwordsplit
    SHUNIT_PARENT="$1"
  fi
}

# shellcheck disable=SC2034
shunit2="${0%/*}/../tmp/shunit2/shunit2"
