#!/usr/bin/env sh
# shellcheck disable=SC2039

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:=lib/mktemp_directory.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testMktempDirectory() {
  run mktemp_directory

  assertTrue 'mktemp_directory failed' "$return_status"
  assertTrue 'result is not a directory' "[ -d '$(cat "$stdout")' ]"
  assertStderrNull
  assertTrue 'temp directory cannot be removed' "rmdir $(cat "$stdout")"
}

testMktempDirectoryParentDir() {
  run mktemp_directory "$tmppath"

  assertTrue 'mktemp_directory failed' "$return_status"
  assertTrue 'result is not a directory' "[ -d '$(cat "$stdout")' ]"
  assertTrue 'parent dir not is tmppath' \
    "[ '$(dirname "$stdout")' = '$tmppath' ]"
  assertStderrNull
  assertTrue 'temp directory cannot be removed' "rmdir $(cat "$stdout")"
}

shell_compat "$0"

. "$shunit2"
