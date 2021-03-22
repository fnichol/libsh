#!/usr/bin/env awk

BEGIN {
    distrib = ARGV[1]

    find_sources(distrib)
    for (src in srcs) {
        print src
    }
}

function find_sources(src) {
    while (getline <src > 0) {
        if ($1 == ".") {
            gsub(/("|')/, "", $2)
            srcs[$2] = 1
            find_sources($2)
        }
    }
    close(src)
}
