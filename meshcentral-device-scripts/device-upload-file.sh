#!/usr/bin/env bash
set -e

DEVICE=""
FILE=""
TARGET=""

# help message
for ARGUMENT in "$@"; do
    if [ "$ARGUMENT" == "-h" ] || [ "$ARGUMENT" == "--help" ]; then
        echo "usage: $(basename "$0") [ARGUMENT]"
        echo "Upload a file to a device connected to MeshCentral."
        echo "Make sure following environment variables are set:"
        echo "    SERVER_URL, SERVER_USERNAME, SERVER_PASSWORD"
        echo "ARGUMENT can be"
        echo "    --device DEVICE The device name."
        echo "    --file FILE The path of the file to upload."
        echo "    --target TARGET The target folder path to upload the file to."
        exit
    fi
done

# check arguments
while [[ -n "$1" ]]; do
    if [[ "$1" == "--device" ]]; then
        shift
        DEVICE="$1"
    elif [[ "$1" == "--file" ]]; then
        shift
        FILE="$1"
    elif [[ "$1" == "--target" ]]; then
        shift
        TARGET="$1"
    else
        echo "Unknown argument: \"$1\""
        exit 1
    fi
    shift
done

if [[ -f "$FILE" ]]; then
    FILE="$(realpath "$FILE")"
else
    echo "File \"${FILE}\" not found"
fi

cd /opt/meshcentral/node_modules/meshcentral

echo "Upload file \"${FILE}\" to \"${TARGET}\" on \"${DEVICE}\"."
DEVICE_ID="$(node meshctrl --loginuser "$SERVER_USERNAME" \
        --loginpass "$SERVER_PASSWORD" --url "$SERVER_URL" \
        ListDevices --filter "^${DEVICE}\$" --csv | \
    sed "s|^\([^,]*,\)\{2\}\"\([^\"]*\)\"\(,[^,]*\)\{4\}|\2|")"
for ATTEMPT in {1..10}; do
    UPLOAD_RESULT=\"$(node meshctrl --loginuser "$SERVER_USERNAME" --loginpass "$SERVER_PASSWORD" \
        --url "$SERVER_URL" Upload --id "$DEVICE_ID" --file "$FILE" \
        --target "$TARGET")\"
    if [[ "$UPLOAD_RESULT" != *'Upload done'* ]]; then
        echo "Attempt ${ATTEMPT}: Failed to upload file."
        echo "$UPLOAD_RESULT"
        if [[ "$ATTEMPT" -eq 10 ]]; then
            exit 1
        fi
        sleep 5
    else
        break;
    fi
done
