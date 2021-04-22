#!/usr/bin/env sh
# shellcheck disable=SC3043

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:=lib/info.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testInfoStripAnsi() {
  run info 'something is happening'

  assertTrue 'info failed' "$return_status"
  assertStdoutStripAnsiEquals '  - something is happening'
  assertStderrNull
}

testInfoAnsi() {
  printf -- '\033[1;36;40m  - \033[1;37;40msomething is happening\033[0m\n' \
    >"$expected"
  export TERM=xterm
  run info 'something is happening'

  assertTrue 'info failed' "$return_status"
  # Shell string equals has issues with ANSI escapes, so let's use $(cmp) to
  # compare byte by byte
  assertTrue 'ANSI stdout not equal' "cmp '$expected' '$stdout'"
  assertStderrNull
}

shell_compat "$0"

. "$shunit2"
