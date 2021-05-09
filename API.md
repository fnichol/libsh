# libsh Full API

<details>
<summary><strong>Table of Contents</strong></summary>

<!-- toc -->

- [check_cmd](#check_cmd)
  - [Environment Variables](#environment-variables)
  - [Examples](#examples)
- [cleanup_directory](#cleanup_directory)
  - [Global Variables](#global-variables)
  - [Examples](#examples-1)
- [cleanup_file](#cleanup_file)
  - [Global Variables](#global-variables-1)
  - [Examples](#examples-2)
- [die](#die)
  - [Environment Variables](#environment-variables-1)
  - [Notes](#notes)
  - [Examples](#examples-3)
- [download](#download)
  - [Notes](#notes-1)
  - [Examples](#examples-4)
- [indent](#indent)
  - [Notes](#notes-2)
  - [Examples](#examples-5)
- [info_end](#info_end)
  - [Environment Variables](#environment-variables-2)
  - [Examples](#examples-6)
- [info_start](#info_start)
  - [Environment Variables](#environment-variables-3)
  - [Examples](#examples-7)
- [info](#info)
  - [Environment Variables](#environment-variables-4)
  - [Examples](#examples-8)
- [mktemp_directory](#mktemp_directory)
  - [Examples](#examples-9)
- [mktemp_file](#mktemp_file)
  - [Examples](#examples-10)
- [need_cmd](#need_cmd)
  - [Environment Variables](#environment-variables-5)
  - [Notes](#notes-3)
  - [Examples](#examples-11)
- [print_version](#print_version)
  - [Examples](#examples-12)
- [section](#section)
  - [Environment Variables](#environment-variables-6)
  - [Examples](#examples-13)
- [setup_cleanup_directories](#setup_cleanup_directories)
  - [Global Variables](#global-variables-2)
  - [Examples](#examples-14)
- [setup_cleanup_files](#setup_cleanup_files)
  - [Global Variables](#global-variables-3)
  - [Examples](#examples-15)
- [setup_cleanups](#setup_cleanups)
  - [Examples](#examples-16)
- [setup_traps](#setup_traps)
  - [Examples](#examples-17)
- [trap_cleanup_directories](#trap_cleanup_directories)
  - [Global Variables](#global-variables-4)
  - [Examples](#examples-18)
- [trap_cleanup_files](#trap_cleanup_files)
  - [Global Variables](#global-variables-5)
  - [Examples](#examples-19)
- [trap_cleanups](#trap_cleanups)
  - [Examples](#examples-20)
- [warn](#warn)
  - [Environment Variables](#environment-variables-7)
  - [Examples](#examples-21)

<!-- tocstop -->

</details>

## check_cmd

Determines whether or not a program is available on the system PATH.

- `@param [String]` program name
- `@return 0` if program is found on system PATH
- `@return 1` if program is not found

### Environment Variables

- `PATH` indirectly used to search for the program

### Examples

Basic usage, when used as a conditional check:

```sh
if check_cmd git; then
  echo "Found Git"
fi
```

## cleanup_directory

Tracks a directory for later cleanup in a trap handler.

This function can be called immediately after a temp directory is created,
before a directory is created, or long after a directory exists. When used in
combination with [`trap_cleanup_directories`], all directories registered by
calling `cleanup_directory` will be removed if they exist when
`trap_cleanup_directories` is invoked.

- `@param [String]` path to directory
- `@return 0` if successful
- `@return 1` if a temp file could not be created

[`trap_cleanup_directories`]: #trap_cleanup_directories

### Global Variables

- `__CLEANUP_DIRECTORIES__` used to track the collection of directories to clean
  up whose value is a file. If not declared or set, this function will set it
  up.

### Examples

Basic usage:

```sh
dir="$(mktemp_directory)"
cleanup_directory "$dir"
# do work on directory, etc.
```

## cleanup_file

Tracks a file for later cleanup in a trap handler.

This function can be called immediately after a temp file is created, before a
file is created, or long after a file exists. When used in combination with
[`trap_cleanup_files`], all files registered by calling `cleanup_file` will be
removed if they exist when `trap_cleanup_files` is invoked.

- `@param [String]` path to file
- `@return 0` if successful
- `@return 1` if a temp file could not be created

[`trap_cleanup_files`]: #trap_cleanup_files

### Global Variables

- `__CLEANUP_FILES__` used to track the collection of files to clean up whose
  value is a file. If not declared or set, this function will set it up.

### Examples

Basic usage:

```sh
file="$(mktemp_file)"
cleanup_file "$file"
# do work on file, etc.
```

## die

Prints an error message to standard error and exits with a non-zero exit code.

- `@param [String]` warning text
- `@stderr` warning text message

### Environment Variables

- `TERM` used to determine whether or not the terminal is capable of printing
  colored output.

### Notes

This function calls `exit` and will **not** return.

### Examples

Basic usage:

```sh
die "No program to download tarball"
```

## download

Downloads the contents at the given URL to the given local file.

This implementation attempts to use the `curl` program with a fallback to the
`wget` program and a final fallback to the `ftp` program. The first download
program to succeed is used and if all fail, this function returns a non-zero
code.

- `@param [String]` download URL
- `@param [String]` destination file
- `@return 0` if a download was successful
- `@return 1` if a download was not successful

### Notes

At least one of `curl`, `wget`, or `ftp` must be compiled with SSL/TLS support
to be able to download from `https` sources.

### Examples

Basic usage:

```sh
download http://example.com/file.txt /tmp/file.txt
```

## indent

Indents the output from a command while preserving the command's exit code.

In minimal/POSIX shells there is no support for `set -o pipefail` which means
that the exit code of the first command in a shell pipeline won't be addressable
in an easy way. This implementation uses a temp file to ferry the original
command's exit code from a subshell back into the main function. The output can
be aligned with a pipe to `sed` as before but now we have an implementation
which mimics a `set -o pipefail` which should work on all Bourne shells. Note
that the `set -o errexit` is disabled during the command's invocation so that
its exit code can be captured.

Based on implementation from
[Stack Overflow](https://stackoverflow.com/a/54931544)

- `@param [String[]]` command and arguments
- `@return` the exit code of the command which was executed

### Notes

In order to preserve the output order of the command, the `stdout` and `stderr`
streams are combined, so the command will not emit its `stderr` output to the
caller's `stderr` stream.

### Examples

Basic usage:

```sh
indent cat /my/file
```

## info_end

Completes printing an informational, detailed step to standard out which has no
output, started with [`info_start`].

- `@stdout` informational heading text
- `@return 0` if successful

[`info_start`]: #info_start

### Environment Variables

- `TERM` used to determine whether or not the terminal is capable of printing
  colored output.

### Examples

Basic usage:

```sh
info_end
```

## info_start

Prints an informational, detailed step to standard out which has no output.

- `@param [String]` informational text
- `@stdout` informational heading text
- `@return 0` if successful

### Environment Variables

- `TERM` used to determine whether or not the terminal is capable of printing
  colored output.

### Examples

Basic usage:

```sh
info_start "Copying file"
```

## info

Prints an informational, detailed step to standard out.

- `@param [String]` informational text
- `@stdout` informational heading text
- `@return 0` if successful

### Environment Variables

- `TERM` used to determine whether or not the terminal is capable of printing
  colored output.

### Examples

Basic usage:

```sh
info "Downloading tarball"
```

## mktemp_directory

Creates a temporary directory and prints the name to standard output.

Most system use the first no-argument version, however Mac OS X 10.10 (Yosemite)
and older don't allow the no-argument version, hence the second fallback
version.

All tested invocations will create a file in each platform's suitable temporary
directory.

- `@param [optional, String]` parent directory
- `@stdout` path to temporary directory
- `@return 0` if successful

### Examples

Basic usage:

```sh
dir="$(mktemp_directory)"
# use directory
```

With a custom parent directory:

```sh
dir="$(mktemp_directory $HOME)"
# use directory
```

## mktemp_file

Creates a temporary file and prints the name to standard output.

Most systems use the first no-argument version, however Mac OS X 10.10
(Yosemite) and older don't allow the no-argument version, hence the second
fallback version.

All tested invocations will create a file in each platform's suitable temporary
directory.

- `@param [optional, String]` parent directory
- `@stdout` path to temporary file
- `@return 0` if successful

### Examples

Basic usage:

```sh
file="$(mktemp_file)"
# use file
```

With a custom parent directory:

```sh
dir="$(mktemp_file "$HOME")"
# use file
```

## need_cmd

Prints an error message and exits with a non-zero code if the program is not
available on the system PATH.

- `@param [String]` program name
- `@stderr` a warning message is printed if program cannot be found

### Environment Variables

- `PATH` indirectly used to search for the program

### Notes

If the program is not found, this function calls `exit` and will **not** return.

### Examples

Basic usage, when used as a guard or prerequisite in a function:

```sh
need_cmd git
```

## print_version

Prints program version information to standard out.

The minimal implementation will output the program name and version, separated
with a space, such as `my-program 1.2.3`. However, if the Git program is
detected and the current working directory is under a Git repository, then more
information will be displayed. Namely, the short Git SHA and author commit date
will be appended in parenthesis at end of the line. For example,
`my-program 1.2.3 (abc123 2000-01-02)`. Alternatively, if the Git commit
information is known ahead of time, it can be provided via optional arguments.

If verbose mode is enable by setting the optional third argument to a `true`,
then a detailed version report will be appended to the single line "simple
mode". Assuming that the Git program is available and the current working
directory is under a Git repository, then three extra lines will be emitted:

1. `release: 1.2.3` the version string
2. `commit-hash: abc...` the full Git SHA of the current commit
3. `commit-date: 2000-01-02` the author commit date of the current commit

If Git is not found and no additional optional arguments are provided, then only
the `release: 1.2.3` line will be emitted for verbose mode.

Finally, if the Git repository is not "clean", that is if it contains
uncommitted or modified files, a `-dirty` suffix will be added to the short and
long Git SHA refs to signal that the implementation may not perfectly correspond
to a SHA commit.

- `@param [String]` program name
- `@param [String]` version string
- `@param [optional, String]` verbose mode set if value if `"true"`
- `@param [optional, String]` short Git SHA
- `@param [optional, String]` long Git SHA
- `@param [optional, String]` commit/version date
- `@stdout` version information
- `@return 0` if successful

Note that the implementation for this function was inspired by Rust's
[`cargo version`](https://git.io/fjsOh).

### Examples

Basic usage:

```sh
print_version "my-program" "1.2.3"
```

An optional third argument puts the function in verbose mode and more detail is
output to standard out:

```sh
print_version "my-program" "1.2.3" "true"
```

An empty third argument is the same as only providing two arguments (i.e.
non-verbose):

```sh
print_version "my-program" "1.2.3" ""
```

## section

Prints a section-delimiting header to standard out.

- `@param [String]` section heading text
- `@stdout` section heading text
- `@return 0` if successful

### Environment Variables

- `TERM` used to determine whether or not the terminal is capable of printing
  colored output.

### Examples

Basic usage:

```sh
section "Building project"
```

## setup_cleanup_directories

Sets up state to track directories for later cleanup in a trap handler.

This function is typically used in combination with [`cleanup_directory`] and
[`trap_cleanup_directories`].

- `@return 0` if successful
- `@return 1` if a temp file could not be created

### Global Variables

- `__CLEANUP_DIRECTORIES__` used to track the collection of directories to clean
  up whose value is a file. If not declared or set, this function will set it
  up.
- `__CLEANUP_DIRECTORIES_SETUP__` used to track if the `__CLEANUP_DIRECTORIES__`
  variable has been set up for the current process

### Examples

Basic usage:

```sh
setup_cleanup_directories
```

Used with [`cleanup_directory`], [`setup_traps`], and
[`trap_cleanup_directories`]:

```sh
setup_cleanup_directories
setup_traps trap_cleanup_directories

dir="$(mktemp_directory)"
cleanup_directory "$dir"
# do work on directory, etc.
```

[`cleanup_file`]: #cleanup_file
[`setup_traps`]: #setup_traps
[`trap_cleanup_directories`]: #trap_cleanup_directories

## setup_cleanup_files

Sets up state to track files for later cleanup in a trap handler.

This function is typically used in combination with [`cleanup_file`] and
[`trap_cleanup_files`].

- `@return 0` if successful
- `@return 1` if a temp file could not be created

### Global Variables

- `__CLEANUP_FILES__` used to track the collection of files to clean up whose
  value is a file. If not declared or set, this function will set it up.
- `__CLEANUP_FILES_SETUP__` used to track if the `__CLEANUP_FILES__` variable
  has been set up for the current process

### Examples

Basic usage:

```sh
setup_cleanup_files
```

Used with [`cleanup_file`], [`setup_traps`], and [`trap_cleanup_files`]:

```sh
setup_cleanup_files
setup_traps trap_cleanup_files

file="$(mktemp_file)"
cleanup_file "$file"
# do work on file, etc.
```

[`cleanup_file`]: #cleanup_file
[`setup_traps`]: #setup_traps
[`trap_cleanup_files`]: #trap_cleanup_files

## setup_cleanups

Sets up state to track files and directories for later cleanup in a trap
handler.

This function is typically used in combination with [`cleanup_file`] and
[`cleanup_directory`] as well as [`trap_cleanups`].

- `@return 0` if successful
- `@return 1` if the setup was not successful

### Examples

Basic usage:

```sh
setup_cleanups
```

Used with [`cleanup_directory`], [`cleanup_file`], [`setup_traps`], and
[`trap_cleanups`]:

```sh
setup_cleanups
setup_traps trap_cleanups

file="$(mktemp_file)"
cleanup_file "$file"
# do work on file, etc.

dir="$(mktemp_directory)"
cleanup_directory "$dir"
# do work on directory, etc.
```

[`cleanup_directory`]: #cleanup_directory
[`cleanup_file`]: #cleanup_file
[`setup_traps`]: #setup_traps
[`trap_cleanups`]: #trap_cleanups

## setup_traps

Sets up traps for `EXIT` and common signals with the given cleanup function.

In addition to `EXIT`, the `HUP`, `INT`, `QUIT`, `ALRM`, and `TERM` signals are
also covered.

This implementation was based on a very nice, portable signal handling thread
thanks to an implementation on
[Stack Overflow](https://unix.stackexchange.com/a/240736).

- `@param [String]` name of function to run with traps

### Examples

Basic usage with a simple "hello world" cleanup function:

```sh
hello_trap() {
  echo "Hello, trap!"
}

setup_traps hello_trap
```

If the cleanup is simple enough to be a one-liner, you can provide the command
as the single argument:

```sh
setup_traps "echo 'Hello, World!'"
```

## trap_cleanup_directories

Removes any tracked directories registered via [`cleanup_directory`].

- `@return 0` whether or not an error has occurred

[`cleanup_directory`]: #cleanup_directory

### Global Variables

- `__CLEANUP_DIRECTORIES__` used to track the collection of files to clean up
  whose value is a file. If not declared or set, this function will assume there
  is no work to do.

### Examples

Basic usage:

```sh
trap trap_cleanup_directories 1 2 3 15 ERR EXIT

dir="$(mktemp_directory)"
cleanup_directory "$dir"
# do work on directory, etc.
```

## trap_cleanup_files

Removes any tracked files registered via [`cleanup_file`].

- `@return 0` whether or not an error has occurred

[`cleanup_file`]: #cleanup_file

### Global Variables

- `__CLEANUP_FILES__` used to track the collection of files to clean up whose
  value is a file. If not declared or set, this function will assume there is no
  work to do.

### Examples

Basic usage:

```sh
trap trap_cleanup_files 1 2 3 15 ERR EXIT

file="$(mktemp_file)"
cleanup_file "$file"
# do work on file, etc.
```

## trap_cleanups

Removes any tracked files and directories registered via [`cleanup_file`] and
[`cleanup_directory`] respectively.

- `@return 0` whether or not an error has occurred

[`cleanup_directory`]: #cleanup_directory
[`cleanup_file`]: #cleanup_file

### Examples

Basic usage:

```sh
trap trap_cleanups 1 2 3 15 ERR EXIT
```

Used with [`setup_traps`]:

```sh
setup_traps trap_cleanups
```

[`setup_traps`]: #setup_traps

## warn

Prints a warning message to standard out.

- `@param [String]` warning text
- `@stdout` warning heading text
- `@return 0` if successful

### Environment Variables

- `TERM` used to determine whether or not the terminal is capable of printing
  colored output.

### Examples

Basic usage:

```sh
warn "Could not connect to service"
```
