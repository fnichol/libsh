#!/usr/bin/env awk

$0 == "# BEGIN: libsh.sh" {
  begin = 1
}
/^# distribution: / {
    gsub(/\.sh/, "-minified.sh")
}
begin == 1 && /^$/ {
  begin = 0
  notice = 1
  print
  next
}
notice == 1 && /^$/ {
  notice = 0
  stripcomment = 1
  next
}
stripcomment == 1 && /^\s*#\s+shellcheck\s+/ {
  print
  next
}
stripcomment == 1 && /^# END: libsh.sh$/ {
  print ""
  print
  next
}
stripcomment == 1 && (/^\s*#/ || /^$/) {
  next
}
{
  print
}
