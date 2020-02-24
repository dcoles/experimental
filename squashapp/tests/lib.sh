# Required for tests
shopt -s expand_aliases

RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
RESET="$(tput sgr0)"

# Failed tests
FAILED=()

function log {
    echo >&2 "$*"
}

function TEST {
    TESTNAME="$1"

    log "- ${TESTNAME}"
}

function DO {
    local returncode="$?"

    if [[ "${returncode}" -eq 0 ]]; then
        log "  ${GREEN}pass${RESET}"
    else
        log "  ${RED}FAIL${RESET}"
        FAILED+=("${TESTFILE}:${TESTNAME}")
    fi

    unset TESTNAME
}

function _fail {
    local lineno="$1"
    shift

    log "line ${lineno}: $*"
    exit 1
}

alias fail='_fail "${LINENO}"'

function _assert_eq {
    local lineno="$1"
    shift

    if [[ "$1" != "$2" ]]; then
        _fail "${lineno}" "\"$1\" != \"$2\""
    fi
}

alias assert_eq='_assert_eq "${LINENO}"'

function _assert_ok {
    local lineno="$1"
    shift

    local output
    if ! output="$("$@" 2>&1)"; then
        _fail "${lineno}" "Command failed: ${output} (returncode: $?)"
    fi
}

alias assert_ok='_assert_ok "${LINENO}"'

function _assert_err {
    local lineno="$1"
    shift

    local output
    if output="$("$@" 2>&1)"; then
        _fail "${lineno}" "Command unexpectedly succeeded: ${output}"
    fi
}

alias assert_err='_assert_err "${LINENO}"'

function build_squashapp {
    ../build_squashapp "$@"
}
