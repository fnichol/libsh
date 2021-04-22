#!/usr/bin/env sh
# shellcheck disable=SC3043

# shellcheck source=tests/test_helpers.sh
. "${0%/*}/test_helpers.sh"

. "${0%/*}/../lib/_ksh_local.sh"

. "${SRC:=lib/download.sh}"

oneTimeSetUp() {
  commonOneTimeSetUp
}

setUp() {
  commonSetUp
}

testDownloadReal() {
  local url
  # a stable, generally available, consistent, and small file to download
  url="https://raw.githubusercontent.com/fnichol/libsh/636e5de/.gitignore"
  printf -- "tmp/\n" >"$expected"

  run download "$url" "$actual"

  assertTrue 'download failed' "$return_status"
  assertStderrNull
  assertStdoutStripAnsiContains "Downloading $url to $actual"
  assertEquals "content isn't equal" "$(cat "$expected")" "$(cat "$actual")"
}

testDownloadFakeSucceedingCurl() {
  local url file
  url="http://example.com"
  file="/not/important"

  isolatedPathFor sh grep sed printf
  touch "$isolated_path/curl"
  chmod 0755 "$isolated_path/curl"
  {
    echo '#!/usr/bin/env sh'
    echo 'echo "curl $@" >&2'
    echo 'exit 0'
  } >>"$isolated_path/curl"

  # Clear `PATH` so the real `curl`, `wget`, and `ftp` programs cannot be found
  export PATH="$isolated_path"
  run download "$url" "$file"
  # Restore `PATH`
  export PATH="$__ORIG_PATH"

  assertTrue 'download failed' "$return_status"
  assertStdoutStripAnsiContains "Downloading $url to $file"
  assertStdoutStripAnsiContains "curl"
  assertStderrEquals "curl -sSfL $url -o $file"
}

testDownloadFakeFailingCurlWithFakeSucceedingWget() {
  local url file
  url="http://example.com"
  file="/not/important"

  isolatedPathFor sh grep sed printf
  touch "$isolated_path/curl"
  chmod 0755 "$isolated_path/curl"
  {
    echo '#!/usr/bin/env sh'
    echo 'exit 1'
  } >>"$isolated_path/curl"
  touch "$isolated_path/wget"
  chmod 0755 "$isolated_path/wget"
  {
    echo '#!/usr/bin/env sh'
    echo 'echo "wget $@" >&2'
    echo 'exit 0'
  } >>"$isolated_path/wget"

  # Clear `PATH` so the real `curl`, `wget`, and `ftp` programs cannot be found
  export PATH="$isolated_path"
  run download "$url" "$file"
  # Restore `PATH`
  export PATH="$__ORIG_PATH"

  assertTrue 'download failed' "$return_status"
  assertStdoutStripAnsiContains "Downloading $url to $file"
  assertStdoutStripAnsiContains "curl failed to download file"
  assertStdoutStripAnsiContains "wget"
  assertStderrEquals "wget -q -O $file $url"
}

testDownloadFakeSucceedingWget() {
  local url file
  url="http://example.com"
  file="/not/important"

  isolatedPathFor sh grep sed printf
  touch "$isolated_path/wget"
  chmod 0755 "$isolated_path/wget"
  {
    echo '#!/usr/bin/env sh'
    echo 'echo "wget $@" >&2'
    echo 'exit 0'
  } >>"$isolated_path/wget"

  # Clear `PATH` so the real `curl`, `wget`, and `ftp` programs cannot be found
  export PATH="$isolated_path"
  run download "$url" "$file"
  # Restore `PATH`
  export PATH="$__ORIG_PATH"

  assertTrue 'download failed' "$return_status"
  assertStdoutStripAnsiContains "Downloading $url to $file"
  assertStdoutStripAnsiContains "wget"
  assertStderrEquals "wget -q -O $file $url"
}

testDownloadFakeFailingCurlWithFakeFailingWgetWithFakeSucceedingFtp() {
  local url file
  url="http://example.com"
  file="/not/important"

  isolatedPathFor sh grep sed printf
  touch "$isolated_path/curl"
  chmod 0755 "$isolated_path/curl"
  {
    echo '#!/usr/bin/env sh'
    echo 'exit 1'
  } >>"$isolated_path/curl"
  touch "$isolated_path/wget"
  chmod 0755 "$isolated_path/wget"
  {
    echo '#!/usr/bin/env sh'
    echo 'exit 1'
  } >>"$isolated_path/wget"
  touch "$isolated_path/ftp"
  chmod 0755 "$isolated_path/ftp"
  {
    echo '#!/usr/bin/env sh'
    echo 'echo "ftp $@" >&2'
    echo 'exit 0'
  } >>"$isolated_path/ftp"

  # Clear `PATH` so the real `curl`, `wget`, and `ftp` programs cannot be found
  export PATH="$isolated_path"
  run download "$url" "$file"
  # Restore `PATH`
  export PATH="$__ORIG_PATH"

  assertTrue 'download failed' "$return_status"
  assertStdoutStripAnsiContains "Downloading $url to $file"
  assertStdoutStripAnsiContains "curl failed to download file"
  assertStdoutStripAnsiContains "wget failed to download file"
  assertStdoutStripAnsiContains "ftp"
  assertStderrEquals "ftp -o $file $url"
}

testDownloadFakeFailingCurlWithFakeFailingWgetWithFakeFailingFtp() {
  local url file
  url="http://example.com"
  file="/not/important"

  isolatedPathFor sh grep sed printf
  touch "$isolated_path/curl"
  chmod 0755 "$isolated_path/curl"
  {
    echo '#!/usr/bin/env sh'
    echo 'exit 1'
  } >>"$isolated_path/curl"
  touch "$isolated_path/wget"
  chmod 0755 "$isolated_path/wget"
  {
    echo '#!/usr/bin/env sh'
    echo 'exit 1'
  } >>"$isolated_path/wget"
  touch "$isolated_path/ftp"
  chmod 0755 "$isolated_path/ftp"
  {
    echo '#!/usr/bin/env sh'
    echo 'exit 1'
  } >>"$isolated_path/ftp"

  # Clear `PATH` so the real `curl`, `wget`, and `ftp` programs cannot be found
  export PATH="$isolated_path"
  run download "$url" "$file"
  # Restore `PATH`
  export PATH="$__ORIG_PATH"

  assertFalse 'download succeeded' "$return_status"
  assertStdoutStripAnsiContains "Downloading $url to $file"
  assertStdoutStripAnsiContains "curl failed to download file"
  assertStdoutStripAnsiContains "wget failed to download file"
  assertStdoutStripAnsiContains "ftp failed to download file"
  assertStdoutStripAnsiContains "Downloading requires SSL-enabled"
  assertStderrNull
}

testDownloadFakeSucceedingFtp() {
  local url file
  url="http://example.com"
  file="/not/important"

  isolatedPathFor sh grep sed printf
  touch "$isolated_path/ftp"
  chmod 0755 "$isolated_path/ftp"
  {
    echo '#!/usr/bin/env sh'
    echo 'echo "ftp $@" >&2'
    echo 'exit 0'
  } >>"$isolated_path/ftp"

  # Clear `PATH` so the real `curl`, `wget`, and `ftp` programs cannot be found
  export PATH="$isolated_path"
  run download "$url" "$file"
  # Restore `PATH`
  export PATH="$__ORIG_PATH"

  assertTrue 'download failed' "$return_status"
  assertStdoutStripAnsiContains "Downloading $url to $file"
  assertStdoutStripAnsiContains "ftp"
  assertStderrEquals "ftp -o $file $url"
}

testDownloadNoWgetOrCurlOrFtp() {
  isolatedPathFor grep sed printf
  # Clear `PATH` so the real `curl`, `wget`, and `ftp` programs cannot be found
  export PATH="$isolated_path"
  run download "http://example.com" "/not/important"
  # Restore `PATH`
  export PATH="$__ORIG_PATH"

  assertFalse 'download succeeded' "$return_status"
  assertStdoutStripAnsiContains "Downloading requires SSL-enabled"
  assertStderrNull
}

shell_compat "$0"

. "$shunit2"
