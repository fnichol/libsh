#!/usr/bin/env sh
# shellcheck disable=SC2039

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:-lib/print_version.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
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
  dir="$tmppath/testPrintVersionNoGitRepo"
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

shell_compat "$0"

. "$shunit2"
