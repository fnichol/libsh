#!/usr/bin/env sh
# shellcheck disable=SC3043

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:=lib/die.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testDieStripAnsi() {
  printf -- '\nxxx I give up\n\n' >"$expected"
  run_with_sh_script die 'I give up'

  stripAnsi <"$stderr" >"$actual"

  assertFalse 'fail did not fail' "$return_status"
  # Shell string equals has issues trailing newlines, so let's use `cmp` to
  # compare byte by byte
  assertTrue 'ANSI stderr not equal' "cmp '$expected' '$actual'"
  assertStdoutNull
}

testDieAnsi() {
  printf -- '\n\033[1;31;40mxxx \033[1;37;40mI give up\033[0m\n\n' >"$expected"
  export TERM=xterm
  run_with_sh_script die 'I give up'

  assertFalse 'fail did not fail' "$return_status"
  # Shell string equals has issues with ANSI escapes, so let's use `cmp` to
  # compare byte by byte
  assertTrue 'ANSI stderr not equal' "cmp '$expected' '$stderr'"
  assertStdoutNull
}

shell_compat "$0"

. "$shunit2"
