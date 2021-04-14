#!/usr/bin/env sh
# shellcheck disable=SC2039

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:=lib/setup_cleanup_directories.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testSetupCleanupDirectories() {
  unset __CLEANUP_DIRECTORIES__
  run setup_cleanup_directories

  assertTrue 'setup_cleanup_directories failed' "$return_status"
  assertStdoutNull
  assertStderrNull
  assertTrue 'cleanup directories does not exist' \
    "[ -f '$__CLEANUP_DIRECTORIES__' ]"
}

testSetupCleanupFilesWithVarSet() {
  local original_value
  original_value="$tmppath/testSetupCleanupDirectories.cleanup"
  __CLEANUP_DIRECTORIES__="$original_value"
  run setup_cleanup_directories

  assertTrue 'setup_cleanup_directories failed' "$return_status"
  assertStdoutNull
  assertStderrNull
  assertEquals 'clean directories variable changed' \
    "$original_value" "$__CLEANUP_DIRECTORIES__"
}

shell_compat "$0"

. "$shunit2"
