#!/usr/bin/env sh
# shellcheck disable=SC2039

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:-lib/info_start.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testInfoStartStripAnsi() {
  run info_start 'something is happening'

  assertTrue 'info_start failed' "$return_status"
  assertStdoutStripAnsiEquals '  - something is happening ... '
  assertStderrNull
}

testInfoStartAnsi() {
  printf -- '\033[1;36;40m  - \033[1;37;40msomething ... \033[0m' \
    >"$expected"
  export TERM=xterm
  run info_start 'something'

  assertTrue 'info_start failed' "$return_status"
  # Shell string equals has issues with ANSI escapes, so let's use $(cmp) to
  # compare byte by byte
  assertTrue 'ANSI stdout not equal' "cmp '$expected' '$stdout'"
  assertStderrNull
}

shell_compat "$0"

. "$shunit2"
