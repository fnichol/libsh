#!/usr/bin/env sh
# shellcheck disable=SC3043

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:=lib/mktemp_file.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testMktempFile() {
  run mktemp_file

  assertTrue 'mktemp_file failed' "$return_status"
  assertTrue 'result is not a file' "[ -f '$(cat "$stdout")' ]"
  assertStderrNull
  assertTrue 'temp file cannot be removed' "rm $(cat "$stdout")"
}

testMktempFileParentDir() {
  run mktemp_file "$tmppath"

  assertTrue 'mktemp_file failed' "$return_status"
  assertTrue 'result is not a file' "[ -f '$(cat "$stdout")' ]"
  assertTrue 'parent dir not is tmppath' \
    "[ '$(dirname "$stdout")' = '$tmppath' ]"
  assertStderrNull
  assertTrue 'temp file cannot be removed' "rm $(cat "$stdout")"
}

shell_compat "$0"

. "$shunit2"
