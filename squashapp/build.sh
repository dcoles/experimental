#!/bin/bash
# Build SquashFS app
set -e

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo >&2 "Usage: $0 <dir> [<main>]"
    exit 2
fi

BASEDIR="$(dirname "$0")"
DIR="$1"
NAME="$(basename "${DIR}")"
MAIN="${2:-bin/${NAME}}"
INTERPRETER=/bin/bash
LOADER="${BASEDIR}/lib/loader.sh"
SQUASH="${NAME}.squash"
OUT="${NAME}.run"

if ! [[ -d "${DIR}" ]]; then
    echo >&2 "ERROR: ${DIR} is not a directory"
    exit 1
fi

if ! (cd "${DIR}" && [[ -n "$(find . -wholename "./${MAIN}" -executable)" ]]); then
    echo >&2 "ERROR: Could not find executable ${MAIN} in ${1}"
    echo >&2 "Note: <main> must be relative to <dir> (e.g. \"bin/${NAME}\")"
    exit 1
fi

echo >&2 "Building ${SQUASH}"
mksquashfs "${DIR}" "${SQUASH}" -noappend -all-root -comp xz

SIZE="$(wc -c < "${SQUASH}")"
SHA256="$(sha256sum -b "${SQUASH}" | cut -d ' ' -f 1)"

echo >&2 "Building ${OUT}"
sed -e "s|^#!.*|#!${INTERPRETER}|" \
    -e "s|^SIZE=.*|SIZE=\"${SIZE}\"|" \
    -e "s|^SHA256=.*|SHA256=\"${SHA256}\"|" \
    -e "s|^MAIN=.*|MAIN=\"${MAIN}\"|" \
    "${LOADER}" | cat - "${SQUASH}" > "${OUT}"

chmod a+x "${OUT}"

echo >&2 'Done'
