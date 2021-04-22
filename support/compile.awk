#!/usr/bin/env awk

BEGIN {
    distrib = ARGV[1]
    shebang = "#!/usr/bin/env sh"

    setup_vars(distrib)
    compile_source(distrib)
}

function compile_source(src) {
    find_sources(distrib)

    print_source("lib/_shebang.sh")
    print ""
    print "# BEGIN: libsh.sh"
    print ""
    inline_source("lib/_header")
    print ""
    inline_source(src)
    inline_source("lib/_ksh_local.sh")
    inline_sources()
    print ""
    print "# END: libsh.sh"
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

function inline_sources(_str, _arr, _size, _i) {
    for (_i in srcs)  {
        _str = _str " " _i
    }
    _size = split(_str, _arr, " ")
    heapsort(_arr, _size)
    for (_i in _arr) {
        print ""
        inline_source(_arr[_i])
    }
}

function inline_source(src, _skip, _src_line) {
    while (getline <src > 0) {
        # Remove extra empty lines after source lines
        if (_src_line == 1) {
            if (/^$/) {
                continue
            } else {
                _src_line = 0
            }
        }
        # Remove multiple contiguous empty lines
        if (_empty_line == 1) {
            if (/^$/) {
                continue
            } else {
                _empty_line = 0
            }
        }
        if (/^$/) {
            _empty_line = 1
        }

        if (_skip == 1) {
            # Skip lines until the next empty line is found
            if (/^$/) {
                _skip = 0
            }
            continue
        } else if ($0 == shebang)  {
            # Start skipping lines once the shebang line is found
            _skip = 1
            continue
        } else if ($1 == ".")  {
            # Start skipping source lines and any trailing empty lines
            _src_line = 1
            continue
        } else {
            # Otherwise print the line
            for (token in vars) {
                gsub(token, vars[token])
            }
            print
        }
    }
    close(src)
}

function print_source(src) {
    while (getline <src > 0) {
        for (token in vars) {
            gsub(token, vars[token])
        }
        print
    }
    close(src)
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
    if ((("git " "show -s --format=%ad --date=short") | getline) > 0) {
        vars["@@commit_date@@"] = $1
    }
    _size = split(distrib, _arr, "/")
    vars["@@distrib@@"] = _arr[_size]
}

function heapsort(arr, size, _i) {
    for (_i = int(size / 2); _i >= 1; _i--) {
        heapify(arr, _i, size)
    }
    for (_i = size; _i > 1; _i--) {
        { swap(arr, 1, _i) }
        { heapify(arr, 1, _i - 1) }
    }
}

function heapify(arr, left, right, _p, _c) {
    for (_p = left; (_c = 2 * _p) <= right; _p = _c) {
        if (_c < right && arr[_c + 1] > arr[_c]) {
            _c++
        }

        if (arr[_p] < arr[_c]) {
            swap(arr, _c, _p)
        }
    }
}

function swap(arr, i, j, _t) {
    _t = arr[i]
    arr[i] = arr[j]
    arr[j] = _t
}
