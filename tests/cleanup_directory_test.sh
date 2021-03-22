#!/usr/bin/env sh
# shellcheck disable=SC2039

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:-lib/cleanup_directory.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testCleanupDirectory() {
  local directory
  __CLEANUP_DIRECTORIES__="$(mktemp_file)"
  directory="$tmppath/testCleanupDirectory"
  mkdir -p "$directory"
  run cleanup_directory "$directory"

  assertTrue 'cleanup_directory failed' "$return_status"
  assertEquals "$(cat "$__CLEANUP_DIRECTORIES__")" "$directory"
  assertTrue 'directories could not be removed' \
    "rm -rf '$__CLEANUP_DIRECTORIES__' '$directory'"

  assertStdoutNull
  assertStderrNull

  unset directory
}

testCleanupDirectoryNoVar() {
  local directory
  unset __CLEANUP_DIRECTORIES__
  directory="$tmppath/testCleanupDirectoryNoVar"
  mkdir -p "$directory"
  run cleanup_directory "$directory"

  assertTrue 'cleanup_directory failed' "$return_status"
  assertEquals "$(cat "$__CLEANUP_DIRECTORIES__")" "$directory"
  assertTrue 'directories could not be removed' \
    "rm -rf '$__CLEANUP_DIRECTORIES__' '$directory'"

  assertStdoutNull
  assertStderrNull

  unset directory
}

shell_compat "$0"

. "$shunit2"
