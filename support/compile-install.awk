#!/usr/bin/env awk

BEGIN {
    input = ARGV[1]
    distrib = ARGV[2]

    setup_vars(input)
    compile_source(input, distrib)
}

function compile_source(src, distrib, _skip) {
    while (getline <src > 0) {
        if (/^# (BEGIN|INSERT): libsh.sh$/) {
            insert_libsh(distrib)
            if (/^# BEGIN: libsh.sh$/) {
                _skip = 1
            }
        } else if (_skip == 1 && /^# END: libsh.sh$/) {
            _skip = 0
        } else if (_skip == 0) {
            for (token in vars) {
                gsub(token, vars[token])
            }
            print
        }
    }
}

function insert_libsh(distrib, _print) {
    while (getline <distrib > 0) {
        if (/^# BEGIN: libsh.sh$/) {
            _print = 1
            print
        } else if (/^# END: libsh.sh$/) {
            _print = 0
            print
        } else if (_print == 1) {
            print
        }
    }
}

function setup_vars(distrib, _arr, _size) {
    if (getline <"VERSION.txt" > 0) {
        vars["@@version@@"] = $1
    }
    if (NIGHTLY_BUILD) {
        _size = split(vars["@@version@@"], _arr, "-")
        vars["@@version@@"] = _arr[1] "-nightly." NIGHTLY_BUILD
    }
    if ((("git " "show -s --format=%H") | getline) > 0) {
        vars["@@commit_hash@@"] = $1
    }
    if ((("git " "show -s --format=%h") | getline) > 0) {
        vars["@@commit_hash_short@@"] = $1
    }
    if ((("git " "show -s --format=%ad --date=short") | getline) > 0) {
        vars["@@commit_date@@"] = $1
    }
    _size = split(distrib, _arr, "/")
    vars["@@distrib@@"] = _arr[_size]
}
