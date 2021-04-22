#!/usr/bin/env sh

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:=lib/check_cmd.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testCheckCmdPresent() {
  # The `ls` command should almost always be in `$PATH` as a program
  run check_cmd ls

  assertTrue 'check_cmd failed' "$return_status"
  assertStdoutNull
  assertStderrNull
}

testCheckCmdMissing() {
  run check_cmd __not_a_great_chance_this_will_exist__

  assertFalse 'check_cmd succeeded' "$return_status"
  assertStdoutNull
  assertStderrNull
}

shell_compat "$0"

. "$shunit2"
