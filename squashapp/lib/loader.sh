#!/bin/echo This_file_is_not_intended_for_direct_execution
# SquashFS app self-extractor
set -e

THIS="$0"
NAME="$(basename "${THIS}" .run)"
LINES="$(grep -aFonx '# EOF' "${THIS}" | cut -d : -f 1)"
OFFSET="$(head -n "${LINES}" < "${0}" | wc -c)"
MAIN="${MAIN:?}"
SIZE="${SIZE:?}"
SHA256="${SHA256:?}"

function _uncat {
    dd ibs="${OFFSET}" skip=1 if="${THIS}" of="${NAME}.squash"
}

function _digest {
    tail -n "+$(( LINES + 1 ))" "${THIS}" | sha256sum -b | cut -d ' ' -f 1
}

function _mount {
    MOUNT="$(mktemp -d -t squashapp.XXXXXXXXXX)"
    squashfuse -o offset="${OFFSET:-0}" -- "${THIS}" "${MOUNT}"
}

function _unmount {
    fusermount -u -- "${MOUNT:?}"
    rmdir "${MOUNT:?}"
}

function _run {
    (
        cd "${MOUNT:?}"
        exec -a "${NAME}" "./${MAIN}" "$@"
    )
}

if [[ "$(wc -c < "${THIS}")" -lt "$(( OFFSET + SIZE ))" ]]; then
    echo >&2 'ERROR: Truncated archive'
    exit 1
fi

# Local args
for arg in "$@"; do
    case "${arg}" in
        --squashapp-uncat)
            echo >&2 "Extracting to ${NAME}.squash"
            _uncat
            exit 0
            ;;
        --squashapp-mount)
            _mount
            echo >&2 "Mounted to ${MOUNT}"
            exit 0
            ;;
        --squashapp-offset)
            echo "${OFFSET}"
            exit 0
            ;;
        --squashapp-verify)
            DIGEST="$(_digest)"
            if [[ "${DIGEST}" != "${SHA256}" ]]; then
                echo >&2 "Bad sha256sum: ${DIGEST}"
                exit 1
            fi
            echo >&2 'OK'
            exit 0
            ;;
        --squashapp*)
            echo >&1 "ERROR: Unknown SquashApp flag ${arg}"
            exit 2
            ;;
        *)
            continue
    esac
    shift
done

_mount
trap _unmount EXIT

_run "$@"

exit $?
# EOF
