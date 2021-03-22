#!/usr/bin/env sh
# shellcheck disable=SC2039

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:-lib/warn.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testWarnStripAnsi() {
  run warn 'something is questionable'

  assertTrue 'warn failed' "$return_status"
  assertStdoutStripAnsiEquals '!!! something is questionable'
  assertStderrNull
}

testWarnAnsi() {
  printf -- '\033[1;31;40m!!! \033[1;37;40msomething is questionable\033[0m\n' \
    >"$expected"
  export TERM=xterm
  run warn 'something is questionable'

  assertTrue 'warn failed' "$return_status"
  # Shell string equals has issues with ANSI escapes, so let's use $(cmp) to
  # compare byte by byte
  assertTrue 'ANSI stdout not equal' "cmp '$expected' '$stdout'"
  assertStderrNull
}

shell_compat "$0"

. "$shunit2"
