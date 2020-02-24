
if [[ -z "${SQUASHAPP_RUNTIME:-}" ]]; then
    echo >&2 'ERROR: SQUASHAPP_RUNTIME not defined'
    exit 1
fi

. "${SQUASHAPP_RUNTIME}"
