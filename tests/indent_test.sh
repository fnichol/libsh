#!/usr/bin/env sh
# shellcheck disable=SC2039

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:=lib/indent.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testIndent() {
  run indent echo 'hello, world'

  assertTrue 'indent failed' "$return_status"
  assertStdoutStripAnsiEquals '       hello, world'
  assertStderrNull
}

testIndentPropagatesCommandExitCode() {
  touch "$tmppath/exiter"
  chmod 0755 "$tmppath/exiter"
  {
    echo '#!/usr/bin/env sh'
    echo 'exit 19'
  } >>"$tmppath/exiter"

  run indent "$tmppath/exiter"

  assertEquals "exit code isn't equal" "19" "$return_status"
}

testIndentCombinesOutputStreams() {
  printf -- '       stdout1\n' >"$expected"
  printf -- '       stderr1\n' >>"$expected"
  printf -- '       stdout2\n' >>"$expected"
  touch "$tmppath/streamer"
  chmod 0755 "$tmppath/streamer"
  {
    echo '#!/usr/bin/env sh'
    echo 'echo "stdout1"'
    echo 'echo "stderr1" >&2'
    echo 'echo "stdout2"'
    echo 'exit 0'
  } >>"$tmppath/streamer"

  run indent "$tmppath/streamer"

  assertTrue 'indent failed' "$return_status"
  # Shell string equals has issues trailing newlines, so let's use `cmp` to
  # compare byte by byte
  assertTrue 'stdout not equal' "cmp '$expected' '$stdout'"
  assertStderrNull
}

shell_compat "$0"

. "$shunit2"
