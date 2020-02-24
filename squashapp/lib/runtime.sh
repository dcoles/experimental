
SQUASHAPP="$0"
SQUASHAPP_NAME="$(basename "$0" .run)"
SQUASHAPP_ARGV0="$(dirname "$0")/${SQUASHAPP_NAME}"
SQUASHAPP_RUNTIME_VER=0.1

function usage {
    log "Usage: $0 [options] ..."
    log "SquashApp options:"
    log "	--squashapp-extract   extract SquashFS as ${SQUASHAPP_NAME}.squash"
    log "	--squashapp-mount     mount SquashFS volume and print mountpoint"
    log "	--squashapp-offset    print offset of SquashFS data"
    log "	--squashapp-verify    check digest of SquashFS data matches"
    log "	--squashapp-help      show help (this text)"
}

function log {
    echo >&2 "$*"
}

function error {
    echo >&2 "ERROR: $*"
}

# Calculate number of lines of runtime
# Requires file to end with a '# EOF' line
# Usage: squashapp_lines
function squashapp_lines {
    local lines
    lines="$(grep -aFonx '# EOF' "${SQUASHAPP}" | cut -d : -f 1)"

    if ! [[ "${lines}" -gt 0 ]]; then
        error 'Could not calculate SquashFS offset'
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
        error "Failed to create mountpoint"
        exit 1
    fi

    if ! squashfuse -o offset="${offset}" -- "${SQUASHAPP}" "${mountpoint}"; then
        error "Failed to mount ${SQUASHAPP} (offset: ${offset})"
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
# Usage: run <mountpoint> <arg>...
function run_main {
    (
        local mountpoint="${1:?}"
        shift

        exec -a "${SQUASHAPP_ARGV0}" "${mountpoint}/${SQUASHAPP_MAIN}" "$@"
    )
}

# Main: Run SquashApp
# Usage: main <args>...
function main {
    local offset
    offset="$(squashapp_offset)"

    if [[ "$(wc -c < "${SQUASHAPP}")" -lt "$(( offset + SQUASHAPP_FSSIZE ))" ]]; then
        error 'Truncated archive'
        exit 1
    fi

    # Local args
    for arg in "$@"; do
        case "${arg}" in
            --squashapp-extract)
                log "Extracting to ${SQUASHAPP_NAME}.squash"
                squashapp_extract "${SQUASHAPP_NAME}.squash" "${offset}"
                exit 0
                ;;
            --squashapp-mount)
                local mountpoint
                mountpoint="$(squashapp_mount "${offset}")"
                log "Mounted to ${mountpoint}"
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
                    log "Bad sha256sum: ${digest}"
                    exit 1
                fi
                log "OK ${digest}"
                exit 0
                ;;
            --squashapp-help)
                usage
                exit 0
                ;;
            --squashapp*)
                error "Unknown SquashApp flag ${arg}"
                usage
                exit 2
                ;;
            *)
                continue
        esac
        shift
    done

    MOUNTPOINT="$(squashapp_mount "${offset}")"
    trap 'squashapp_unmount "${MOUNTPOINT}"' EXIT

    run_main "${MOUNTPOINT}" "$@"
}

main "$@"
exit $?
