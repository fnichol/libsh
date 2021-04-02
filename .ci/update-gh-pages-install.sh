#!/usr/bin/env sh
# shellcheck shell=sh disable=SC2039

print_usage() {
  local program="$1"

  echo "$program

    Updates a vendored install.sh in a repo's GitHub pages Git branch

    USAGE:
        $program [FLAGS] [--] <INSTALL_SCRIPT> [<REPO>]

    FLAGS:
        -h, --help      Prints help information

    ARGS:
        <INSTALL_SCRIPT>  Path to install script
        <REPO>            GitHub repository [default: fnichol/libsh]
    " | sed 's/^ \{1,4\}//g'
}

main() {
  set -eu
  if [ -n "${DEBUG:-}" ]; then set -v; fi
  if [ -n "${TRACE:-}" ]; then set -xv; fi

  local program
  program="$(basename "$0")"

  . "lib/cleanup_directory.sh"
  . "lib/die.sh"
  . "lib/mktemp_directory.sh"
  . "lib/need_cmd.sh"

  local repo git_name git_email
  repo=fnichol/libsh
  git_name="Fletcher Nichol"
  git_email="fnichol@nichol.ca"

  OPTIND=1
  while getopts "h-:" arg; do
    case "$arg" in
      h)
        print_usage "$program"
        return 0
        ;;
      -)
        case "$OPTARG" in
          help)
            print_usage "$program"
            return 0
            ;;
          '')
            # "--" terminates argument processing
            break
            ;;
          *)
            print_usage "$program" >&2
            die "invalid argument --$OPTARG"
            ;;
        esac
        ;;
      \?)
        print_usage "$program" >&2
        die "invalid argument; arg=-$OPTARG"
        ;;
    esac
  done
  shift "$((OPTIND - 1))"

  if [ -z "${1:-}" ]; then
    print_usage "$program" >&2
    die "missing <INSTALL_SCRIPT> argument"
  fi
  local install_script="$1"
  shift
  if [ ! -f "$install_script" ]; then
    print_usage "$program" >&2
    die "install script '$install_script' not found"
  fi
  if [ -n "${1:-}" ]; then
    repo="$1"
    shift
  fi

  if [ -z "${GITHUB_TOKEN:-}" ]; then
    die "missing required environment variable: GITHUB_TOKEN"
  fi

  need_cmd chmod
  need_cmd cp
  need_cmd git

  local workdir
  workdir="$(mktemp_directory)"
  cleanup_directory "$workdir"

  cp "$install_script" "$workdir/install.sh"
  chmod 755 "$workdir/install.sh"

  git clone \
    "https://${GITHUB_TOKEN}:x-oauth-basic@github.com/$repo.git" "$workdir/repo"
  cd "$workdir/repo"
  git config --local user.name "$git_name"
  git config --local user.email "$git_email"
  git checkout gh-pages
  mv ../install.sh install.sh
  git add install.sh
  git commit --message="chore: update released install.sh [ci skip]"
  git push origin gh-pages
}

main "$@"
