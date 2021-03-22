#!/usr/bin/env sh
# shellcheck disable=SC2039

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:-lib/setup_traps.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
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
