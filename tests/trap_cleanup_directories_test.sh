#!/usr/bin/env sh
# shellcheck disable=SC2039

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:=lib/trap_cleanup_directories.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testTrapCleanupDirectories() {
  local alpha bravo charlie
  __CLEANUP_DIRECTORIES__="$tmppath/testTrapCleanupDirectories.cleanup"
  alpha="$tmppath/testTrapCleanupDirectories/alpha"
  mkdir -p "$alpha"
  echo "$alpha" >>"$__CLEANUP_DIRECTORIES__"
  bravo="$tmppath/testTrapCleanupDirectories/bravo"
  mkdir -p "$bravo"
  echo "$bravo" >>"$__CLEANUP_DIRECTORIES__"
  charlie="$tmppath/testTrapCleanupDirectories/charlie"
  mkdir -p "$charlie"
  echo "$charlie" >>"$__CLEANUP_DIRECTORIES__"

  assertTrue 'cleanup directories does not exist' \
    "[ -f '$__CLEANUP_DIRECTORIES__' ]"
  assertTrue 'alpha does not exist' "[ -d '$alpha' ]"
  assertTrue 'bravo does not exist' "[ -d '$bravo' ]"
  assertTrue 'charlie does not exist' "[ -d '$charlie' ]"

  assertTrue 'trap_cleanup_directories does not fail' trap_cleanup_directories

  assertTrue 'cleanup files exists' "[ ! -f '$__CLEANUP_DIRECTORIES__' ]"
  assertTrue 'alpha exists' "[ ! -d '$alpha' ]"
  assertTrue 'bravo exists' "[ ! -d '$bravo' ]"
  assertTrue 'charlie exists' "[ ! -d '$charlie' ]"

  assertStdoutNull
  assertStderrNull

  unset alpha bravo charlie
}

testTrapCleanupDirectoriesNoVar() {
  unset __CLEANUP_DIRECTORIES__

  assertTrue 'trap_cleanup_directories does not fail' trap_cleanup_directories

  assertStdoutNull
  assertStderrNull
}

testTrapCleanupDirectoriesNoFile() {
  __CLEANUP_DIRECTORIES__="$tmppath/testTrapCleanupDirectoriesNoFile.cleanup"
  rm -f "$__CLEANUP_DIRECTORIES__"

  assertTrue 'trap_cleanup_directories does not fail' trap_cleanup_directories

  assertStdoutNull
  assertStderrNull
}

shell_compat "$0"

. "$shunit2"
