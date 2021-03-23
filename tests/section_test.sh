#!/usr/bin/env sh
# shellcheck disable=SC2039

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:=lib/section.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testSectionStripAnsi() {
  run section 'hello there'

  assertTrue 'section failed' "$return_status"
  assertStdoutStripAnsiEquals '--- hello there'
  assertStderrNull
}

testSectionAnsi() {
  printf -- '\033[1;36;40m--- \033[1;37;40mhello there\033[0m\n' >"$expected"
  export TERM=xterm
  run section 'hello there'

  assertTrue 'section failed' "$return_status"
  # Shell string equals has issues with ANSI escapes, so let's use $(cmp) to
  # compare byte by byte
  assertTrue 'ANSI stdout not equal' "cmp '$expected' '$stdout'"
  assertStderrNull
}

shell_compat "$0"

. "$shunit2"
