#!/bin/echo This_file_is_not_intended_for_direct_execution
# SquashFS app self-extractor
set -e -u

SQUASHAPP="$0"
SQUASHAPP_NAME="${SQUASHAPP_NAME:?}"
SQUASHAPP_MAIN="${SQUASHAPP_MAIN:?}"
SQUASHAPP_FSSIZE="${SQUASHAPP_FSSIZE:?}"
SQUASHAPP_SHA256="${SQUASHAPP_SHA256:?}"
