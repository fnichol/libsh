#!/usr/bin/env sh
# shellcheck disable=SC2039

print_usage() {
  local program version author
  program="$1"
  version="$2"
  author="$3"

  need_cmd sed

  echo "$program $version

    Installs libsh into a dedicated vendored file or inserted into an existing
    source file

    USAGE:
        $program [FLAGS] [OPTIONS] [--]

    FLAGS:
        -h, --help      Prints help information
        -V, --version   Prints version information

    OPTIONS:
        -d, --distribution=<DISTRIB>  Distribution format
                                      [values: full, full-minified,
                                      minimal, minimal-minified]
                                      [default: full]
        -m, --mode=<MODE>             Install mode
                                      [values: vendor, insert]
                                      [default: vendor]
        -r, --release=<RELEASE>       Release version
                                      [examples: latest, 1.2.3, main]
                                      [default: latest]
        -t, --target=<TARGET>         Target directory or file for installation
                                      [examples: /tmp/libsh.sh, file.txt]
                                      [default: ./vendor/lib/libsh.<DISTRIB>.sh]

    EXAMPLES:
        # Vendor the latest full release into ./vendor/lib/libsh.sh
        $program

        # Vendor a specific minimal release into /tmp/libsh-0.0.1.sh
        $program --release=0.0.1 --distribution=minimal \\
            --target=/tmp/libsh-0.0.1.sh

        # Insert the latest full release into myprog.sh at a line:
        # \`# INSERT: libsh.sh\`
        $program --mode=insert --target=myprog.sh

        # Update the inserted version with a specific minimal/minified
        # release in cli.sh:
        $program --mode=insert --release=0.0.1 \\
            --distribution=minimal-minified --target=cli.sh

    AUTHOR:
        $author
    " | sed 's/^ \{1,4\}//g'
}

main() {
  set -eu
  if [ -n "${DEBUG:-}" ]; then set -v; fi
  if [ -n "${TRACE:-}" ]; then set -xv; fi

  local program version author sha sha_long date
  program="install.sh"
  version="@@version@@"
  author="Fletcher Nichol <fnichol@nichol.ca>"
  sha="@@commit_hash_short@@"
  sha_long="@@commit_hash@@"
  date="@@commit_date@@"

  # Parse CLI arguments and set local variables
  parse_cli_args "$program" "$version" "$author" "$sha" "$sha_long" "$date" "$@"
  local distrib mode release target
  distrib="$DISTRIB"
  mode="$MODE"
  release="$RELEASE"
  target="$TARGET"
  unset DISTRIB MODE RELEASE TARGET

  setup_traps trap_cleanup_files

  if [ "$release" = "latest" ]; then
    release="$(latest_release fnichol/libsh)"
  fi

  case "$mode" in
    insert)
      insert_libsh "$release" "$distrib" "$target"
      ;;
    vendor)
      vendor_libsh "$release" "$distrib" "$target"
      ;;
    *)
      die "invalid mode value; mode=$mode"
      ;;
  esac
}

parse_cli_args() {
  local program version author sha sha_long date mode release target
  program="$1"
  shift
  version="$1"
  shift
  author="$1"
  shift
  sha="$1"
  shift
  sha_long="$1"
  shift
  date="$1"
  shift

  DISTRIB="full"
  MODE="vendor"
  RELEASE="latest"
  TARGET=

  OPTIND=1
  while getopts "hd:m:r:t:V-:" arg; do
    case "$arg" in
      h)
        print_usage "$program" "$version" "$author"
        exit 0
        ;;
      d)
        if is_distrib_valid "$OPTARG"; then
          DISTRIB="$OPTARG"
        else
          print_usage "$program" "$version" "$author" >&2
          die "invalid distribution name $OPTARG"
        fi
        ;;
      m)
        if is_mode_valid "$OPTARG"; then
          MODE="$OPTARG"
        else
          print_usage "$program" "$version" "$author" >&2
          die "invalid mode name $OPTARG"
        fi
        ;;
      r)
        RELEASE="$OPTARG"
        ;;
      t)
        TARGET="$OPTARG"
        ;;
      V)
        print_version "$program" "$version" "true" "$sha" "$sha_long" "$date"
        exit 0
        ;;
      -)
        long_optarg="${OPTARG#*=}"
        case "$OPTARG" in
          distribution=?*)
            if is_distrib_valid "$long_optarg"; then
              DISTRIB="$long_optarg"
            else
              print_usage "$program" "$version" "$author" >&2
              die "invalid distribution name '$long_optarg'"
            fi
            ;;
          distribution*)
            print_usage "$program" "$version" "$author" >&2
            die "missing required argument for --$OPTARG option"
            ;;
          help)
            print_usage "$program" "$version" "$author"
            exit 0
            ;;
          mode=?*)
            if is_mode_valid "$long_optarg"; then
              MODE="$long_optarg"
            else
              print_usage "$program" "$version" "$author" >&2
              die "invalid mode name '$long_optarg'"
            fi
            ;;
          mode*)
            print_usage "$program" "$version" "$author" >&2
            die "missing required argument for --$OPTARG option"
            ;;
          release=?*)
            RELEASE="$long_optarg"
            ;;
          release*)
            print_usage "$program" "$version" "$author" >&2
            die "missing required argument for --$OPTARG option"
            ;;
          target=?*)
            TARGET="$long_optarg"
            ;;
          target*)
            print_usage "$program" "$version" "$author" >&2
            die "missing required argument for --$OPTARG option"
            ;;
          version)
            print_version "$program" "$version" "true" \
              "$sha" "$sha_long" "$date"
            exit 0
            ;;
          '')
            # "--" terminates argument processing
            break
            ;;
          *)
            print_usage "$program" "$version" "$author" >&2
            die "invalid argument --$OPTARG"
            ;;
        esac
        ;;
      \?)
        print_usage "$program" "$version" "$author" >&2
        die "invalid argument; arg=-$OPTARG"
        ;;
    esac
  done
  shift "$((OPTIND - 1))"

  if [ -z "$TARGET" ]; then
    TARGET="./vendor/lib/libsh.${DISTRIB}.sh"
  fi
}

download_libsh() {
  local release distrib target repo
  release="$1"
  distrib="$2"
  target="$3"
  repo="https://github.com/fnichol/libsh"

  download \
    "$repo/releases/download/v${release}/libsh.${distrib}.sh" \
    "$target"
}

insert_libsh() {
  local release distrib target
  release="$1"
  distrib="$2"
  target="$3"

  need_cmd awk
  need_cmd cat

  local libsh rendered
  libsh="$(mktemp_file)"
  cleanup_file "$libsh"
  rendered="$(mktemp_file)"
  cleanup_file "$rendered"

  section "Inserting libsh.sh '$release' ($distrib) into $target"

  download_libsh "$release" "$distrib" "$libsh"

  info "Inlining libsh into $target"
  awk -v libsh="$libsh" '
    BEGIN {
      tgtprint = 1
      libprint = 0
    }

    # Stop printing from BEGIN line
    /^# BEGIN: libsh.sh$/ {
      tgtprint = 0
    }
    # Insert libsh at BEGIN or INSERT lines
    /^# BEGIN: libsh.sh$/ || /^# INSERT: libsh.sh$/ {
      while ((getline libshln < libsh) > 0) {
        if (libshln == "# BEGIN: libsh.sh") {
          # Start printing libsh contents starting with BEGIN line
          libprint = 1
          print libshln
        } else if (libshln == "# END: libsh.sh") {
          # Stop printing libsh contents after printing END line
          libprint = 0
          print libshln
        } else if (libprint == 1) {
          # If libshprint mode is enabled, print line
          print libshln
        }
      }
      close(libsh)
    }
    # Do not print INSERT line
    /^# INSERT: libsh.sh$/ {
      next
    }
    # Resume printing after END line
    /^# END: libsh.sh$/ {
      tgtprint = 1
      next
    }
    # If target print mode is enabled, print line
    tgtprint == 1 {
      print
    }
  ' "$target" >"$rendered"
  cat "$rendered" >"$target"
}

is_distrib_valid() {
  local distrib
  distrib="$1"

  case "$distrib" in
    full | full-minified | minimal | minimal-minified)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_mode_valid() {
  local mode
  mode="$1"

  case "$mode" in
    vendor | insert)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

latest_release() {
  local gh_repo
  gh_repo="$1"

  need_cmd awk

  local tmpfile
  tmpfile="$(mktemp_file)"
  cleanup_file "$tmpfile"

  download \
    "https://api.github.com/repos/$gh_repo/releases/latest" \
    "$tmpfile" \
    >/dev/null
  awk '
    BEGIN { FS="\""; RS="," }
    $2 == "tag_name" { sub(/^v/, "", $4); print $4 }
  ' "$tmpfile"
}

vendor_libsh() {
  local release distrib target
  release="$1"
  distrib="$2"
  target="$3"

  need_cmd cat
  need_cmd touch
  need_cmd dirname
  need_cmd mkdir

  local tmpfile
  tmpfile="$(mktemp_file)"
  cleanup_file "$tmpfile"

  section "Vendoring libsh.sh '$release' ($distrib) to $target"

  download_libsh "$release" "$distrib" "$tmpfile"

  info "Copying libsh to $target"
  mkdir -p "$(dirname "$target")"
  touch "$target"
  cat "$tmpfile" >"$target"
}

version_ge() {
  local version maj min
  version="$1"
  maj="$2"
  min="$3"

  need_cmd awk

  [ "$(echo "$version" | awk -F'.' '{ print $1 }')" -ge "$maj" ] \
    && [ "$(echo "$version" | awk -F'.' '{ print $2 }')" -ge "$min" ]
}

# INSERT: libsh.sh

main "$@"
