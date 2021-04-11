<h1 align="center">
  <br/>
  libsh
  <br/>
</h1>

<h4 align="center">
  A library of common, reusable, and portable
  <a href="http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html">POSIX shell</a>
  functions.
</h4>

|                  |                                                                                 |
| ---------------: | ------------------------------------------------------------------------------- |
|               CI | [![CI Status][badge-overall]][ci] [![Bors enabled][badge-bors]][bors-dashboard] |
|   Latest Version | [![Latest version][badge-version]][github]                                      |
| GitHub Downloads | [![GitHub downloads][badge-github-dl]][github-releases]                         |
|          License | [![License][badge-license]][license]                                            |

<details>
<summary><strong>Table of Contents</strong></summary>

<!-- toc -->

- [What is libsh?](#what-is-libsh)
- [Motivation](#motivation)
- [Usage](#usage)
- [Installation](#installation)
  - [install.sh](#installsh)
  - [GitHub Releases](#github-releases)
  - [Bespoke](#bespoke)
- [Code of Conduct](#code-of-conduct)
- [Issues](#issues)
- [Contributing](#contributing)
- [Release History](#release-history)
- [Authors](#authors)
- [License](#license)
  - [Contribution](#contribution)

<!-- tocstop -->

</details>

## What is libsh?

libsh is a collection is small, single purpose shell functions that help
developers write consistent, well-formatted, portable scripts and programs
without having to re-implement common tasks such as section printing, file
downloading, trap handling, etc.

The project is actively run and tested against several shell implementations,
including but not limited to:

- [Bash]
- [BusyBox ash]
- [DASH]
- [KornShell]
- [Zsh]
- [sh]

Additionally, several operating systems and distributions are tested and
targeting including:

- [FreeBSD]
- [Linux distributions]
- [OpenBSD]
- [macOS]

To help increase its use cases, several alternative bundles are provided called
"distributions" which allow a user to consume the full library or a smaller
subset. Currently, there are 2 main distributions, each with a comments included
and a minified version:

- full
- full-minified
- minimal
- minimal-minified

The details for each distribution can be found in the [`distrib/`] directory.

[sh]: https://en.wikipedia.org/wiki/Almquist_shell
[bash]: https://www.gnu.org/software/bash/
[zsh]: https://www.zsh.org/
[dash]: http://gondor.apana.org.au/~herbert/dash/
[kornshell]: http://www.kornshell.org/
[busybox ash]: https://www.busybox.net/
[linux distributions]: https://en.wikipedia.org/wiki/List_of_Linux_distributions
[macos]: https://www.apple.com/macos/
[freebsd]: https://www.freebsd.org/
[openbsd]: https://www.openbsd.org/
[`distrib/`]: https://github.com/fnichol/libsh/tree/main/distrib

## Motivation

Writing scripts and programs in shell code can be both rapid and responsive
while at the same time being arcane and intensely error-prone. Add to that there
is little ability to re-use ideas and implementations short of copy/pasting
bodies of code around. libsh was born out of a desire to write some of these
common solutions for the **last time**.

As time moves forward, these snippets of code are used in a new environment,
whether that is unintentionally a new shell implementation (for example, running
a script for the first time on Ubuntu which uses DASH as its `/bin/sh` or in an
Alpine Linux container which uses BusyBox's `ash`) or on a new system (for
example, on macOS which now defaults to Zsh vs. a BSD variant which may default
to KornShell). Likely something breaks and the resulting lesson is "this code is
not portable" or "I need to install a full Bash to make this work properly".
libsh also has a goal here to run with the same behavior in as many places as
possible to ensure that a solution to a problem can truly be re-used.

In an attempt to solve for the "copy/paste" and version drift issues, an
installer is provided that will install releases of this library into your
project as a standalone file or in-lined into a script with an insertion
directive comment. This allows a user to update their codebases when new
versions of libsh are released in as painless a way as possible. If the full
library is more than is needed or if the file size becomes an issue, several
"distributions" are provided as a way to consume no more than you need.

If you have been nodding along so far, we hope you can use some of our
collective knowledge rolled into libsh in your shell-based projects!

## Usage

There are multiple ways to consume libsh, but the provided `install.sh` is the
quickest to get started. Here's how to download the latest release of the full
and minified version of libsh, which will be written to
`./vendor/lib/libsh.full-minified.sh`:

```sh
curl -sSf https://fnichol.github.io/libsh/install.sh | sh -s -- -d full-minified
```

More installations options are described in the [Installation](#installation)
section.

What follows is an example of a program installer script which downloads a
tarball from a website, extracts, and installs it. As is often the case, what
starts out seemingly an easy task, quickly becomes complex when dealing with
error conditions such as required programs not being found, temporary files and
directories not getting cleaned up, etc. Here's how libsh's library can help:

```sh
#!/usr/bin/env sh
set -eu

# source/import library functions into script or alternatively insert a
# distribution directly into the script with the `install.sh` program and a
# line in the script containing only `# INSERT: libsh.sh`
. "vendor/lib/libsh.full-minified.sh"

# add traps to automatically cleanup an directories on exit/abort/etc
setup_traps trap_cleanup_directories

# write a heading style section banner to start off the script with color if
# the terminal supports it
section "Downloading program"

# create a temporary directory in the system's appropriate TEMPDIR
tmpdir="$(mktemp_directory)"
# defer cleaning up this directory until the end of the program, on success or
# failure, making use of the traps set above
cleanup_directory "$tmpdir"

# download a file use curl, wget, of ftp (on OpenBSD), whichever is found and
# terminate the program if a suitable download program cannot be found
download https://example.com/program.tar.gz "$tmpdir/program.tar.gz" \
  || die "no download program found"

# write a progress, sub task of the above section, again with color if supported
info "Extracting program"
# check and ensure that the `tar` program is found and terminate the program if
# it is not found
need_cmd tar
tar xvzf $tmpdir/program.tar.gz -C "$tmpdir"

# write an info style line that will do some work without writing any output
info_start "Installing program"
install "$tmpdir/program" "$HOME/bin/program"
# write an ending to the above info line with "done."
info_end

info "Program installed"
# indent the output of the program's version output at a level to fall
# "inside" the info banner
indent "$HOME/bin/program --version"
```

The full documented set of functions can be found on the [API] page.

## Installation

There are various ways of consuming libsh, depending on needs, automation, etc.

### install.sh

An installer is provided at <https://fnichol.github.io/libsh/install.sh> which
can help install an initial version libsh or to upgrade a preexisting version.
It can be downloaded and run locally or piped into a shell interpreter in the
"curl-bash" style as shown below. Note that if you're opposed to this idea, no
problem, download it, read it and use it (or not). Otherwise check out some of
the alternatives below.

Vendor the latest full release into `./vendor/lib/libsh.full.sh`:

```sh
curl -sSf https://fnichol.github.io/libsh/install.sh | sh
```

Vendor a specific minimal release into `/tmp/common-functions.sh`:

```sh
curl -sSf https://fnichol.github.io/libsh/install.sh | sh -s -- \
  --release=0.0.1 --distribution=minimal --target=/tmp/common-functions.sh
```

Insert the latest full release into `myprog.sh` at a line that contains only
`# INSERT: libsh.sh`:

```sh
curl -sSf https://fnichol.github.io/libsh/install.sh | sh -s -- \
  --mode=insert --target=myprog.sh
```

Update the inserted version with a specific minimal/minified release in
`cli.sh`:

```sh
curl -sSf https://fnichol.github.io/libsh/install.sh | sh -s -- \
  --mode=insert --release=0.0.1 --distribution=minimal-minified --target=cli.sh
```

### GitHub Releases

Each release of libsh comes with release artifacts published in [GitHub
Releases][github-releases]. The `install.sh` program downloads its artifacts
from this location so, this amounts to a manual/alternative way to consume
libsh. Each artifact is also provided with MD5 and SHA256 checksums to help
verify the artifact on a target system.

### Bespoke

While a full distribution of libsh does not live in a single file in [source
control][github], each function lives in its own source file and imports its own
direct function dependencies (example:
[download.sh](https://github.com/fnichol/libsh/blob/main/lib/download.sh)). It
is very doable to import/vendor/combine various functions for use in other
programs without having to consume the entire library nor even a slimmer
distribution, however this remains an exercise for the reader.

## Code of Conduct

This project adheres to the Contributor Covenant [code of
conduct][code-of-conduct]. By participating, you are expected to uphold this
code. Please report unacceptable behavior to fnichol@nichol.ca.

## Issues

If you have any problems with or questions about this image, please contact us
through a [GitHub issue][issues].

## Contributing

You are invited to contribute to new features, fixes, or updates, large or
small; we are always thrilled to receive pull requests, and do our best to
process them as fast as we can.

Before you start to code, we recommend discussing your plans through a [GitHub
issue][issues], especially for more ambitious contributions. This gives other
contributors a chance to point you in the right direction, give you feedback on
your design, and help you find out if someone else is working on the same thing.

## Release History

See the [changelog] for a full release history.

## Authors

Created and maintained by [Fletcher Nichol][fnichol] (<fnichol@nichol.ca>).

## License

Licensed under either of

- The Apache License, Version 2.0 ([LICENSE-APACHE][license-apachev2] or
  <http://www.apache.org/licenses/LICENSE-2.0>)
- The MIT license ([LICENSE-MIT][license-mit] or
  <http://opensource.org/licenses/MIT>)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in the work by you, as defined in the Apache-2.0 license, shall be
dual licensed as above, without any additional terms or conditions.

[api]: https://github.com/fnichol/libsh/blob/main/API.md
[badge-bors]: https://bors.tech/images/badge_small.svg
[badge-github-dl]:
  https://img.shields.io/github/downloads/fnichol/libsh/total.svg
[badge-license]:
  https://img.shields.io/badge/License-Apache%202.0%20%2F%20MIT-blue.svg
[badge-overall]: https://api.cirrus-ci.com/github/fnichol/libsh.svg
[badge-version]: https://img.shields.io/github/tag/fnichol/libsh.svg
[bors-dashboard]: https://app.bors.tech/repositories/32312
[changelog]: https://github.com/fnichol/libsh/blob/main/CHANGELOG.md
[ci]: https://cirrus-ci.com/github/fnichol/libsh
[code-of-conduct]: https://github.com/fnichol/libsh/blob/main/CODE_OF_CONDUCT.md
[fnichol]: https://github.com/fnichol
[github-releases]: https://github.com/fnichol/libsh/releases
[github]: https://github.com/fnichol/libsh
[issues]: https://github.com/fnichol/libsh/issues
[license]: #license
[license-apachev2]: https://github.com/fnichol/libsh/blob/main/LICENSE-APACHE
[license-mit]: https://github.com/fnichol/libsh/blob/main/LICENSE-MIT
