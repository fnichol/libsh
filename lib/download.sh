#!/usr/bin/env sh
# shellcheck disable=SC2039

. "lib/check_cmd.sh"
. "lib/info.sh"
. "lib/need_cmd.sh"
. "lib/warn.sh"

# Downloads the contents at the given URL to the given local file.
#
# This implementation attempts to use the `curl` program with a fallback to the
# `wget` program and a final fallback to the `ftp` program. The first download
# program to succeed is used and if all fail, this function returns a non-zero
# code.
#
# * `@param [String]` download URL
# * `@param [String]` destination file
# * `@return 0` if a download was successful
# * `@return 1` if a download was not successful
#
# # Notes
#
# At least one of `curl`, `wget`, or `ftp must be compiled with SSL/TLS support
# to be able to download from `https` sources.
#
# # Examples
#
# Basic usage:
#
# ```sh
# download http://example.com/file.txt /tmp/file.txt
# ```
download() {
  local _url _dst _code _orig_flags
  _url="$1"
  _dst="$2"

  need_cmd sed

  # Attempt to download with curl, if found. If successful, quick return
  if check_cmd curl; then
    info "Downloading $_url to $_dst (curl)"
    _orig_flags="$-"
    set +e
    curl -sSfL "$_url" -o "$_dst"
    code="$?"
    set "-$(echo "$_orig_flags" | sed s/s//g)"
    if [ $code -eq 0 ]; then
      unset _url _dst _code _orig_flags
      return 0
    else
      local _e
      _e="curl failed to download file, perhaps curl doesn't have"
      _e="$_e SSL support and/or no CA certificates are present?"
      warn "$_e"
      unset _e
    fi
  fi

  # Attempt to download with wget, if found. If successful, quick return
  if check_cmd wget; then
    info "Downloading $_url to $_dst (wget)"
    _orig_flags="$-"
    set +e
    wget -q -O "$_dst" "$_url"
    _code="$?"
    set "-$(echo "$_orig_flags" | sed s/s//g)"
    if [ $_code -eq 0 ]; then
      unset _url _dst _code _orig_flags
      return 0
    else
      local _e
      _e="wget failed to download file, perhaps wget doesn't have"
      _e="$_e SSL support and/or no CA certificates are present?"
      warn "$_e"
      unset _e
    fi
  fi

  # Attempt to download with ftp, if found. If successful, quick return
  if check_cmd ftp; then
    info "Downloading $_url to $_dst (ftp)"
    _orig_flags="$-"
    set +e
    ftp -o "$_dst" "$_url"
    _code="$?"
    set "-$(echo "$_orig_flags" | sed s/s//g)"
    if [ $_code -eq 0 ]; then
      unset _url _dst _code _orig_flags
      return 0
    else
      local _e
      _e="ftp failed to download file, perhaps ftp doesn't have"
      _e="$_e SSL support and/or no CA certificates are present?"
      warn "$_e"
      unset _e
    fi
  fi

  unset _url _dst _code _orig_flags
  # If we reach this point, curl, wget and ftp have failed and we're out of
  # options
  warn "Downloading requires SSL-enabled 'curl', 'wget', or 'ftp' on PATH"
  return 1
}
