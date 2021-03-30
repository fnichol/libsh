#!/usr/bin/env sh

if [ -n "${KSH_VERSION:-}" ]; then
  # Evil, nasty, wicked hack to ignore calls to `local <var>`, on the strict
  # assumption that no initialization will take place, i.e. `local
  # <var>=<value>`. If this assumption holds, this implementation fakes a
  # `local` keyword for ksh. The `eval` is used as some versions of dash will
  # error with "Syntax error: Bad function name" whether or not it's in a
  # conditional (likely in the parser/ast phase) (src:
  # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=619786). Also, `shfmt`
  # does *not* like a function called `local` so...another dodge here. TBD on
  # this one, folks...
  eval "local() { return 0; }"
fi
