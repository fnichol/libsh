#!/usr/bin/env sh
# shellcheck disable=SC3043

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:=lib/setup_cleanup_files.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testSetupCleanupFiles() {
  unset __CLEANUP_FILES__
  run setup_cleanup_files

  assertTrue 'setup_cleanup_files failed' "$return_status"
  assertStdoutNull
  assertStderrNull
  assertTrue 'cleanup files does not exist' "[ -f '$__CLEANUP_FILES__' ]"
}

testSetupCleanupFilesWithVarSet() {
  local original_value
  original_value="$tmppath/testSetupCleanupFiles.cleanup"
  __CLEANUP_FILES__="$original_value"
  run setup_cleanup_files

  assertTrue 'setup_cleanup_files failed' "$return_status"
  assertStdoutNull
  assertStderrNull
  assertEquals 'clean files variable changed' \
    "$original_value" "$__CLEANUP_FILES__"
}

shell_compat "$0"

. "$shunit2"
