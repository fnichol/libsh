#!/usr/bin/env sh
# shellcheck disable=SC2039

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../libsh.sh"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testCheckCmdPresent() {
  # The `ls` command should almost always be in `$PATH` as a program
  run check_cmd ls

  assertTrue 'check_cmd failed' "$return_status"
  assertStdoutNull
  assertStderrNull
}

testCheckCmdMissing() {
  run check_cmd __not_a_great_chance_this_will_exist__

  assertFalse 'check_cmd succeeded' "$return_status"
  assertStdoutNull
  assertStderrNull
}

testCleanupFile() {
  local file
  __CLEANUP_FILES__="$(mktemp_file)"
  file="$(mktemp_file)"
  run cleanup_file "$file"

  assertTrue 'cleanup_file failed' "$return_status"
  assertEquals "$(cat "$__CLEANUP_FILES__")" "$file"
  assertTrue 'files could not be removed' "rm '$__CLEANUP_FILES__' '$file'"

  assertStdoutNull
  assertStderrNull

  unset file
}

testCleanupFileNoVar() {
  local file
  unset __CLEANUP_FILES__
  file="$(mktemp_file)"
  run cleanup_file "$file"

  assertTrue 'cleanup_file failed' "$return_status"
  assertEquals "$(cat "$__CLEANUP_FILES__")" "$file"
  assertTrue 'files could not be removed' "rm '$__CLEANUP_FILES__' '$file'"

  assertStdoutNull
  assertStderrNull

  unset file
}

testDieStripAnsi() {
  printf -- '\nxxx I give up\n\n' >"$expected"
  run_with_sh_script die 'I give up'

  stripAnsi <"$stderr" >"$actual"

  assertFalse 'fail did not fail' "$return_status"
  # Shell string equals has issues trailing newlines, so let's use `cmp` to
  # compare byte by byte
  assertTrue 'ANSI stderr not equal' "cmp '$expected' '$actual'"
  assertStdoutNull
}

testDieAnsi() {
  printf -- '\n\033[1;31;40mxxx \033[1;37;40mI give up\033[0m\n\n' >"$expected"
  export TERM=xterm
  run_with_sh_script die 'I give up'

  assertFalse 'fail did not fail' "$return_status"
  # Shell string equals has issues with ANSI escapes, so let's use `cmp` to
  # compare byte by byte
  assertTrue 'ANSI stderr not equal' "cmp '$expected' '$stderr'"
  assertStdoutNull
}

testInfoStripAnsi() {
  run info 'something is happening'

  assertTrue 'info failed' "$return_status"
  assertStdoutStripAnsiEquals '  - something is happening'
  assertStderrNull
}

testInfoAnsi() {
  printf -- '\033[1;36;40m  - \033[1;37;40msomething is happening\033[0m\n' \
    >"$expected"
  export TERM=xterm
  run info 'something is happening'

  assertTrue 'info failed' "$return_status"
  # Shell string equals has issues with ANSI escapes, so let's use $(cmp) to
  # compare byte by byte
  assertTrue 'ANSI stdout not equal' "cmp '$expected' '$stdout'"
  assertStderrNull
}

testMktempFile() {
  run mktemp_file

  assertTrue 'mktemp_file failed' "$return_status"
  assertTrue 'result is not a file' "[ -f '$(cat "$stdout")' ]"
  assertStderrNull
  assertTrue 'temp file cannot be removed' "rm $(cat "$stdout")"
}

testNeedCmdPresent() {
  # The `ls` command should almost always be in `$PATH` as a program
  run need_cmd ls

  assertTrue 'need_cmd failed' "$return_status"
  assertStdoutNull
  assertStderrNull
}

testNeedCmdMissing() {
  run_with_sh_script need_cmd __not_a_great_chance_this_will_exist__

  assertFalse 'need_cmd succeeded' "$return_status"
  assertStderrStripAnsiContains 'xxx Required command'
  assertStderrStripAnsiContains 'not found on PATH'
  assertStdoutNull
}

testPrintVersionDefault() {
  createGitRepo repo
  run print_version "cool" "1.2.3"

  assertStdoutEquals "cool 1.2.3 ($short_sha 2000-01-02)"
  assertStderrNull
}

testPrintVersionVerbose() {
  createGitRepo repo
  run print_version "cool" "1.2.3" "true"

  assertStdoutEquals "cool 1.2.3 ($short_sha 2000-01-02)
release: 1.2.3
commit-hash: $long_sha
commit-date: 2000-01-02"
  assertStderrNull
}

testPrintVersionExplicitNonverbose() {
  createGitRepo repo
  run print_version "cool" "1.2.3" "" # setting non-verbose with empty arg

  assertStdoutEquals "cool 1.2.3 ($short_sha 2000-01-02)"
  assertStderrNull
}

testPrintVersionNoGitRepo() {
  local dir
  dir="$(mktemp_file)"
  rm -f "$dir"
  mkdir -p "$dir"
  cd "$dir" || return 1
  run print_version "cool" "1.2.3"

  assertStdoutEquals "cool 1.2.3"
  assertStderrNull
  cd - >/dev/null || return 1
  rm -rf "$dir"

  unset dir
}

testPrintVersionDirty() {
  createGitRepo repo
  echo 'Uh oh' >README.md
  run print_version "cool" "1.2.3"

  assertStdoutEquals "cool 1.2.3 (${short_sha}-dirty 2000-01-02)"
  assertStderrNull
}

testPrintVersionDirtyVerbose() {
  createGitRepo repo
  echo 'Uh oh' >README.md
  run print_version "cool" "1.2.3" "true"

  assertStdoutEquals "cool 1.2.3 (${short_sha}-dirty 2000-01-02)
release: 1.2.3
commit-hash: ${long_sha}-dirty
commit-date: 2000-01-02"
  assertStderrNull
}

testPrintVersionNoGit() {
  createGitRepo repo
  # Save full path to `grep`
  GREP="$(command -v grep)"
  export GREP
  # Temporarily clear PATH so the `git` program cannot be found
  export PATH=""
  run print_version "cool" "1.2.3"
  # Restore PATH and unset GREP
  export PATH="$__ORIG_PATH"
  unset GREP

  assertStdoutEquals "cool 1.2.3"
  assertStderrNull
}

testPrintVersionNoGitVerbose() {
  createGitRepo repo
  # Save full path to `grep`
  GREP="$(command -v grep)"
  export GREP
  # Temporarily clear PATH so the `git` program cannot be found
  export PATH=""
  run print_version "cool" "1.2.3" "true"
  # Restore PATH and unset GREP
  export PATH="$__ORIG_PATH"
  unset GREP

  assertStdoutEquals "cool 1.2.3
release: 1.2.3"
  assertStderrNull
}

testSectionStripAnsi() {
  run section 'hello there'

  assertTrue 'section failed' "$return_status"
  assertStdoutStripAnsiEquals '--- hello there'
  assertStderrNull
}

testSectionAnsi() {
  printf -- '\033[1;36;40m--- \033[1;37;40mhello there\033[0m\n' >"$expected"
  export TERM=xterm
  run section 'hello there'

  assertTrue 'section failed' "$return_status"
  # Shell string equals has issues with ANSI escapes, so let's use $(cmp) to
  # compare byte by byte
  assertTrue 'ANSI stdout not equal' "cmp '$expected' '$stdout'"
  assertStderrNull
}

testSetupTrapsSimple() {
  run_in_sh_script <<'EOF'
    echo "start"
    setup_traps "echo 'trap fired'"
    echo "end"
EOF

  assertTrue 'setup_traps failed' "$return_status"
  assertStdoutEquals "start
end
trap fired"
  assertStderrNull
}

testSetupTrapsHUP() {
  # TODO: Skip for pdksh--the setup script isn't handling the signal correctly
  # despite the trap implementation working with the sh_script.
  if echo "${KSH_VERSION:-}" | grep -q "PD KSH"; then
    return
  fi

  signalScript HUP

  assertTrue 'setup_traps failed' "$return_status"
  if [ -n "${ZSH_VERSION:-}" ]; then
    # Zsh will invoke the trap on `HUP` and again when the process exits via
    # the `zshexit()` hook
    assertStdoutEquals "start
trap fired
trap fired"
  else
    assertStdoutEquals "start
trap fired"
  fi
  # stderr may contain a message about the terminated process
}

testSetupTrapsALRM() {
  # TODO: Skip for pdksh--the setup script isn't handling the signal correctly
  # despite the trap implementation working with the sh_script.
  if echo "${KSH_VERSION:-}" | grep -q "PD KSH"; then
    return
  fi

  signalScript ALRM

  assertTrue 'setup_traps failed' "$return_status"
  assertStdoutEquals "start
trap fired"
  # stderr may contain a message about the terminated process
}

testSetupTrapsTERM() {
  # TODO: Skip for pdksh--the setup script isn't handling the signal correctly
  # despite the trap implementation working with the sh_script.
  if echo "${KSH_VERSION:-}" | grep -q "PD KSH"; then
    return
  fi

  signalScript TERM

  assertTrue 'setup_traps failed' "$return_status"
  assertStdoutEquals "start
trap fired"
  # stderr may contain a message about the terminated process
}

# testSetupTrapsINT - does not terminate script with test suite so is skipped

# testSetupTrapsQUIT - does not terminate script with test suite so is skipped

testTrapCleanupFiles() {
  local alpha bravo charlie
  __CLEANUP_FILES__="$(mktemp_file)"
  alpha="$(mktemp_file)"
  echo "$alpha" >>"$__CLEANUP_FILES__"
  bravo="$(mktemp_file)"
  echo "$bravo" >>"$__CLEANUP_FILES__"
  charlie="$(mktemp_file)"
  echo "$charlie" >>"$__CLEANUP_FILES__"

  assertTrue 'cleaup files does not exist' "[ -f '$__CLEANUP_FILES__' ]"
  assertTrue 'alpha does not exist' "[ -f '$alpha' ]"
  assertTrue 'bravo does not exist' "[ -f '$bravo' ]"
  assertTrue 'charlie does not exist' "[ -f '$charlie' ]"

  assertTrue 'trap_cleanup_files does not fail' trap_cleanup_files

  assertTrue 'cleaup files exists' "[ ! -f '$__CLEANUP_FILES__' ]"
  assertTrue 'alpha exists' "[ ! -f '$alpha' ]"
  assertTrue 'bravo exists' "[ ! -f '$bravo' ]"
  assertTrue 'charlie exists' "[ ! -f '$charlie' ]"

  assertStdoutNull
  assertStderrNull

  unset alpha bravo charlie
}

testTrapCleanupNoVar() {
  unset __CLEANUP_FILES__

  assertTrue 'trap_cleanup_files does not fail' trap_cleanup_files

  assertStdoutNull
  assertStderrNull
}

testTrapCleanupNoFile() {
  __CLEANUP_FILES__="$(mktemp_file)"
  rm -f "$__CLEANUP_FILES__"

  assertTrue 'trap_cleanup_files does not fail' trap_cleanup_files

  assertStdoutNull
  assertStderrNull
}

createGitRepo() {
  rm -rf "tmppath/$1"
  git init --quiet "$tmppath/$1"
  cd "$tmppath/$1" || return 1
  touch README.md
  git config user.name "Nobody"
  git config user.email "nobody@example.com"
  git add README.md
  git commit --quiet --message='First commit' --date=2000-01-02T03:04:05

  short_sha="$(git show -s --format=%h)"
  long_sha="$(git show -s --format=%H)"
}

signalScript() {
  run_in_sh_script_and_signal "$1" <<'EOF'
    echo "start"
    setup_traps "echo 'trap fired'"
    sleep 10 &
    wait $!
    echo "end"
EOF
}

shell_compat "$0"

. "$shunit2"
