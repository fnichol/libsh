#!/usr/bin/env sh
# shellcheck disable=SC2039

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:-lib/cleanup_file.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testCleanupFile() {
  local file
  __CLEANUP_FILES__="$(mktemp_file)"
  file="$(mktemp_file)"
  run cleanup_file "$file"

  assertTrue 'cleanup_file failed' "$return_status"
  assertEquals "$(cat "$__CLEANUP_FILES__")" "$file"
  assertTrue 'files could not be removed' "rm '$__CLEANUP_FILES__' '$file'"

  assertStdoutNull
  assertStderrNull

  unset file
}

testCleanupFileNoVar() {
  local file
  unset __CLEANUP_FILES__
  file="$(mktemp_file)"
  run cleanup_file "$file"

  assertTrue 'cleanup_file failed' "$return_status"
  assertEquals "$(cat "$__CLEANUP_FILES__")" "$file"
  assertTrue 'files could not be removed' "rm '$__CLEANUP_FILES__' '$file'"

  assertStdoutNull
  assertStderrNull

  unset file
}

shell_compat "$0"

. "$shunit2"
