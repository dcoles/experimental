
# SquashApp runtime

# Required variables
: "${SQUASHAPP:?}"
: "${SQUASHAPP_NAME:?}" 
: "${SQUASHAPP_MAIN:?}"
: "${SQUASHAPP_FSSIZE:?}"
: "${SQUASHAPP_SHA256:?}"

# Calculate number of lines of runtime
# Requires file to end with a '# EOF' line
# Usage: squashapp_lines
function squashapp_lines {
    local lines
    lines="$(grep -aFonx '# EOF' "${SQUASHAPP}" | cut -d : -f 1)"

    if ! [[ "${lines}" -gt 0 ]]; then
        echo >&2 'ERROR: Could not calculate SquashFS offset'
        exit 1
    fi

    echo "${lines}"
}

# Calculate offset of SquashFS
# Usage: squashapp_offset
function squashapp_offset {
    local lines
    lines="$(squashapp_lines)"

    head -n "${lines}" < "${SQUASHAPP}" | wc -c
}

# Extract SquashFS from SquashApp
# Usage: squashapp_extract <out> [<offset>]
function squashapp_extract {
    dd ibs="${2:-0}" skip=1 if="${SQUASHAPP}" of="$1"
}

# Calculate SHA256 digest of SquashFS in SquashApp
# Usage: squashapp_sha256_digest
function squashapp_sha256_digest {
    local lines
    lines="$(squashapp_lines)"

    tail -n "+$(( lines + 1 ))" "${SQUASHAPP}" | sha256sum -b | cut -d ' ' -f 1
}

# Mount SquashFS
# Usage: squashapp_mount <offset>
# Returns path squashfs is mounted to
function squashapp_mount {
    local offset="${1:?}"

    local mountpoint
    mountpoint="$(mktemp -d -t squashapp.XXXXXXXXXX)"

    if ! [[ -d "${mountpoint}" ]]; then
        echo >&2 "ERROR: Failed to create mountpoint"
        exit 1
    fi

    if ! squashfuse -o offset="${offset}" -- "${SQUASHAPP}" "${mountpoint}"; then
        echo >&2 "ERROR: Failed to mount ${SQUASHAPP} (offset: ${offset})"
        rmdir "${mountpoint}"
        exit 1
    fi

    echo "${mountpoint}"
}

# Unmount SquashFS
# Usage: squashapp_unmount <path>
function squashapp_unmount {
    local path="${1:?}"

    fusermount -u -- "${path}"
    rmdir "${path}"
}

# Run command
# Usage: run <cwd> <program> <arg>...
function run {
    (
        local cwd="${1:?}"
        shift

        cd "${cwd}" && exec "$@"
    )
}

# Main: Run SquashApp
# Usage: main <args>...
function main {
    local offset
    offset="$(squashapp_offset)"

    if [[ "$(wc -c < "${SQUASHAPP}")" -lt "$(( offset + SQUASHAPP_FSSIZE ))" ]]; then
        echo >&2 'ERROR: Truncated archive'
        exit 1
    fi

    # Local args
    for arg in "$@"; do
        case "${arg}" in
            --squashapp-uncat)
                echo >&2 "Extracting to ${NAME}.squash"
                squashapp_extract "$0" "${NAME}.squash" "${offset}"
                exit 0
                ;;
            --squashapp-mount)
                local mountpoint
                mountpoint="$(squashapp_mount)"
                echo >&2 "Mounted to ${mountpoint}"
                exit 0
                ;;
            --squashapp-offset)
                echo "${offset}"
                exit 0
                ;;
            --squashapp-verify)
                local digest
                digest="$(squashapp_sha256_digest)"
                if [[ "${digest}" != "${SQUASHAPP_SHA256}" ]]; then
                    echo >&2 "Bad sha256sum: ${digest}"
                    exit 1
                fi
                echo >&2 "OK ${digest}"
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

    MOUNTPOINT="$(squashapp_mount "${offset}")"
    trap 'squashapp_unmount "${MOUNTPOINT}"' EXIT

    run "${MOUNTPOINT}" ./"${SQUASHAPP_MAIN}" "$@"
}

main "$@"

exit "$?"
# EOF
