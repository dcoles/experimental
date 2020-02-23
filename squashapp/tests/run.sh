#!/bin/bash
set -e
shopt -s expand_aliases

cd "$(dirname "$0")"

RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
RESET="$(tput sgr0)"

function log {
    printf -- "$1\n" "${@:2}" >&2
}

function TEST {
    log '- %s' "$1"
}

function DO {
    local returncode="$?"

    if [[ "${returncode}" -eq 0 ]]; then
        log "  ${GREEN}pass${RESET}"
    else
        log "  ${RED}FAIL${RESET}"
    fi

}

function _assert_eq {
    local lineno="$1"
    shift

    if [[ "$1" != "$2" ]]; then
        _fail "${lineno}" '"%s" != "%s"' "$1" "$2"
    fi
}

alias assert_eq='_assert_eq "${LINENO}"'

function _assert_ok {
    local lineno="$1"
    shift

    local output
    if ! output="$("$@" 2>&1)"; then
        _fail "${lineno}" 'Command failed: %s (returncode: %d)' "${output}" "$?"
    fi
}

alias assert_ok='_assert_ok "${LINENO}"'

function _assert_err {
    local lineno="$1"
    shift

    local output
    if output="$("$@" 2>&1)"; then
        _fail "${lineno}" 'Command unexpectedly succeeded: %s' "${output}"
    fi
}

alias assert_err='_assert_err "${LINENO}"'

function _fail {
    local lineno="$1"
    shift

    log "line %d: $1" "${lineno}" "${@:2}"
    exit 1
}

alias fail='_fail "${LINENO}"'

for test in *.test; do
    echo >&2 "Running ${test}..."
    ( . "${test}" )
done
