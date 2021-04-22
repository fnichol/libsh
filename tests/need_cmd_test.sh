#!/usr/bin/env sh
# shellcheck disable=SC3043

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:=lib/need_cmd.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testNeedCmdPresent() {
  # The `ls` command should almost always be in `$PATH` as a program
  run need_cmd ls

  assertTrue 'need_cmd failed' "$return_status"
  assertStdoutNull
  assertStderrNull
}

testNeedCmdMissing() {
  run_with_sh_script need_cmd __not_a_great_chance_this_will_exist__

  assertFalse 'need_cmd succeeded' "$return_status"
  assertStderrStripAnsiContains 'xxx Required command'
  assertStderrStripAnsiContains 'not found on PATH'
  assertStdoutNull
}

shell_compat "$0"

. "$shunit2"
