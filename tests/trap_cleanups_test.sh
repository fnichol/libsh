#!/usr/bin/env sh
# shellcheck disable=SC3043

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:=lib/trap_cleanups.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testTrapCleanups() {
  local f_alpha f_bravo f_charlie
  local d_alpha d_bravo d_charlie
  __CLEANUP_FILES__="$tmppath/testTrapCleanupFiles.cleanup"
  __CLEANUP_DIRECTORIES__="$tmppath/testTrapCleanupDirectories.cleanup"

  mkdir "$tmppath/testTrapCleanupDirectories"
  f_alpha="$tmppath/testTrapCleanupDirectories/f_alpha"
  touch "$f_alpha"
  echo "$f_alpha" >>"$__CLEANUP_FILES__"
  f_bravo="$tmppath/testTrapCleanupDirectories/f_bravo"
  touch "$f_bravo"
  echo "$f_bravo" >>"$__CLEANUP_FILES__"
  f_charlie="$tmppath/testTrapCleanupDirectories/f_charlie"
  touch "$f_charlie"
  echo "$f_charlie" >>"$__CLEANUP_FILES__"

  d_alpha="$tmppath/testTrapCleanupDirectories/d_alpha"
  mkdir -p "$d_alpha"
  echo "$d_alpha" >>"$__CLEANUP_DIRECTORIES__"
  d_bravo="$tmppath/testTrapCleanupDirectories/d_bravo"
  mkdir -p "$d_bravo"
  echo "$d_bravo" >>"$__CLEANUP_DIRECTORIES__"
  d_charlie="$tmppath/testTrapCleanupDirectories/d_charlie"
  mkdir -p "$d_charlie"
  echo "$d_charlie" >>"$__CLEANUP_DIRECTORIES__"

  assertTrue 'cleanup files does not exist' "[ -f '$__CLEANUP_FILES__' ]"
  assertTrue 'f_alpha does not exist' "[ -f '$f_alpha' ]"
  assertTrue 'f_bravo does not exist' "[ -f '$f_bravo' ]"
  assertTrue 'f_charlie does not exist' "[ -f '$f_charlie' ]"

  assertTrue 'cleanup directories does not exist' \
    "[ -f '$__CLEANUP_DIRECTORIES__' ]"
  assertTrue 'd_alpha does not exist' "[ -d '$d_alpha' ]"
  assertTrue 'd_bravo does not exist' "[ -d '$d_bravo' ]"
  assertTrue 'd_charlie does not exist' "[ -d '$d_charlie' ]"

  assertTrue 'trap_cleanups does not fail' trap_cleanups

  assertTrue 'cleanup files exists' "[ ! -f '$__CLEANUP_FILES__' ]"
  assertTrue 'f_alpha exists' "[ ! -f '$f_alpha' ]"
  assertTrue 'f_bravo exists' "[ ! -f '$f_bravo' ]"
  assertTrue 'f_charlie exists' "[ ! -f '$f_charlie' ]"

  assertTrue 'cleanup files exists' "[ ! -f '$__CLEANUP_DIRECTORIES__' ]"
  assertTrue 'd_alpha exists' "[ ! -d '$d_alpha' ]"
  assertTrue 'd_bravo exists' "[ ! -d '$d_bravo' ]"
  assertTrue 'd_charlie exists' "[ ! -d '$d_charlie' ]"

  assertStdoutNull
  assertStderrNull

  unset f_alpha f_bravo f_charlie
  unset d_alpha d_bravo d_charlie
}

testTrapCleanupsNoVar() {
  unset __CLEANUP_FILES__
  unset __CLEANUP_DIRECTORIES__

  assertTrue 'trap_cleanups does not fail' trap_cleanups

  assertStdoutNull
  assertStderrNull
}

testTrapCleanupFilesNoFile() {
  __CLEANUP_FILES__="$tmppath/testTrapCleanupFilesNoFile.cleanup"
  rm -f "$__CLEANUP_FILES__"
  __CLEANUP_DIRECTORIES__="$tmppath/testTrapCleanupDirectoriesNoFile.cleanup"
  rm -f "$__CLEANUP_DIRECTORIES__"

  assertTrue 'trap_cleanups does not fail' trap_cleanups

  assertStdoutNull
  assertStderrNull
}

shell_compat "$0"

. "$shunit2"
