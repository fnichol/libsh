# Changelog

<!-- next-header -->

## [Unreleased] - ReleaseDate

## [0.8.0] - 2021-04-11

### Added

- add an API page, fully documenting all functions in one place
- complete sections in Readme
- add optional support for provided Git info in `print_version` function
- add `install.sh` support for installing distributions
- release a new `install.sh` script on each release

### Fixed

- update errant local variable `code` in `download` function

## [0.7.0] - 2021-03-23

### Added

- add support for multiple distributions of libsh

### Changed

- remove locals in functions taking 1 argument
- update default branch to `main`
- upgrade CI workflow & introduce bors for merging

## [0.6.0] - 2020-12-30

### Added

- add `info_start` function
- add `info_end` function

## [0.5.0] - 2020-05-27

### Added

- add `mktemp_directory` function
- add `cleanup_directory` function
- add `trap_cleanup_directories` function

## [0.4.0] - 2020-05-26

### Added

- add coloring for `alacritty`, `tmux`, & `tmux-*` terminals

### Fixed

- split all `local` declarations onto their own lines in `install.sh`

## [0.3.0] - 2020-05-13

### Added

- add `indent` function
- add `ftp` program support to `download`, primarily for OpenBSD

## [0.2.0] - 2019-11-26

### Added

- add `install.sh` to remotely install libsh from GitHub releases
- add `download` function
- add `check_cmd` function
- add `warn` function
- add `setup_traps` function
- add support for macOS 10.10 and older

### Changed

- **breaking:** update `die` function to exit on failure
- **breaking:** update `need_cmd` function to exit on failure

### Removed

- remove `libbash.sh`

### Fixed

- remove errant `s` from `set` if it exists

## [0.1.0] - 2019-11-25

- the initial release

<!-- next-url -->

[unreleased]: https://github.com/fnichol/libsh/compare/v0.8.0...HEAD

[0.8.0]: https://github.com/fnichol/libsh/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/fnichol/libsh/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/fnichol/libsh/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/fnichol/libsh/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/fnichol/libsh/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/fnichol/libsh/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/fnichol/libsh/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/fnichol/libsh/compare/636e5de...v0.1.0
