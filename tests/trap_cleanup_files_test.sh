#!/usr/bin/env sh
# shellcheck disable=SC3043

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:=lib/trap_cleanup_files.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testTrapCleanupFiles() {
  local alpha bravo charlie
  __CLEANUP_FILES__="$tmppath/testTrapCleanupFiles.cleanup"
  mkdir "$tmppath/testTrapCleanupDirectories"
  alpha="$tmppath/testTrapCleanupDirectories/alpha"
  touch "$alpha"
  echo "$alpha" >>"$__CLEANUP_FILES__"
  bravo="$tmppath/testTrapCleanupDirectories/bravo"
  touch "$bravo"
  echo "$bravo" >>"$__CLEANUP_FILES__"
  charlie="$tmppath/testTrapCleanupDirectories/charlie"
  touch "$charlie"
  echo "$charlie" >>"$__CLEANUP_FILES__"

  assertTrue 'cleanup files does not exist' "[ -f '$__CLEANUP_FILES__' ]"
  assertTrue 'alpha does not exist' "[ -f '$alpha' ]"
  assertTrue 'bravo does not exist' "[ -f '$bravo' ]"
  assertTrue 'charlie does not exist' "[ -f '$charlie' ]"

  assertTrue 'trap_cleanup_files does not fail' trap_cleanup_files

  assertTrue 'cleanup files exists' "[ ! -f '$__CLEANUP_FILES__' ]"
  assertTrue 'alpha exists' "[ ! -f '$alpha' ]"
  assertTrue 'bravo exists' "[ ! -f '$bravo' ]"
  assertTrue 'charlie exists' "[ ! -f '$charlie' ]"

  assertStdoutNull
  assertStderrNull

  unset alpha bravo charlie
}

testTrapCleanupFilesNoVar() {
  unset __CLEANUP_FILES__

  assertTrue 'trap_cleanup_files does not fail' trap_cleanup_files

  assertStdoutNull
  assertStderrNull
}

testTrapCleanupFilesNoFile() {
  __CLEANUP_FILES__="$tmppath/testTrapCleanupFilesNoFile.cleanup"
  rm -f "$__CLEANUP_FILES__"

  assertTrue 'trap_cleanup_files does not fail' trap_cleanup_files

  assertStdoutNull
  assertStderrNull
}

shell_compat "$0"

. "$shunit2"
