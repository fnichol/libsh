#!/usr/bin/env sh
# shellcheck disable=SC3043

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:=lib/setup_cleanups.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testSetupCleanups() {
  unset __CLEANUP_FILES__
  unset __CLEANUP_DIRECTORIES__
  run setup_cleanups

  assertTrue 'setup_cleanups failed' "$return_status"
  assertStdoutNull
  assertStderrNull
  assertTrue 'cleanup files does not exist' "[ -f '$__CLEANUP_FILES__' ]"
  assertTrue 'cleanup directories does not exist' \
    "[ -f '$__CLEANUP_DIRECTORIES__' ]"
}

testSetupCleanupFilesWithVarSet() {
  local original_value_f
  local original_value_d
  original_value_f="$tmppath/testSetupCleanupFiles.cleanup"
  __CLEANUP_FILES__="$original_value_f"
  original_value_d="$tmppath/testSetupCleanupDirectories.cleanup"
  __CLEANUP_DIRECTORIES__="$original_value_d"
  run setup_cleanup_files

  assertTrue 'setup_cleanup_files failed' "$return_status"
  assertStdoutNull
  assertStderrNull
  assertEquals 'clean files variable changed' \
    "$original_value_f" "$__CLEANUP_FILES__"
  assertEquals 'clean directories variable changed' \
    "$original_value_d" "$__CLEANUP_DIRECTORIES__"
}

shell_compat "$0"

. "$shunit2"
