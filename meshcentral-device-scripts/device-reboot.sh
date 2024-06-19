#!/usr/bin/env bash
set -e

DEVICE=""

# help message
for ARGUMENT in "$@"; do
    if [ "$ARGUMENT" == "-h" ] || [ "$ARGUMENT" == "--help" ]; then
        echo "usage: $(basename "$0") [ARGUMENT]"
        echo "Reboot a device connected to MeshCentral."
        echo "Make sure following environment variables are set:"
        echo "    SERVER_URL, SERVER_USERNAME, SERVER_PASSWORD"
        echo "ARGUMENT can be"
        echo "    --device DEVICE The device name."
        exit
    fi
done

# check arguments
while [[ -n "$1" ]]; do
    if [[ "$1" == "--device" ]]; then
        shift
        DEVICE="$1"
    else
        echo "Unknown argument: \"$1\""
        exit 1
    fi
    shift
done

cd /opt/meshcentral/node_modules/meshcentral

if [[ "$SKIP_REBOOT" == "true" ]]; then
    echo "SKIP_REBOOT is set to true. Skip reboot of \"${DEVICE}\"."
    exit
fi

echo "Reboot \"${DEVICE}\""
DEVICE_ID="$(node meshctrl --loginuser "$SERVER_USERNAME" \
        --loginpass "$SERVER_PASSWORD" --url "$SERVER_URL" \
        ListDevices --filter "^${DEVICE}\$" --csv | \
    sed "s|^\([^,]*,\)\{2\}\"\([^\"]*\)\"\(,[^,]*\)\{4\}|\2|")"
node meshctrl --loginuser "$SERVER_USERNAME" --loginpass "$SERVER_PASSWORD" \
    --url "$SERVER_URL" RunCommand --id "$DEVICE_ID" --run reboot
for ATTEMPT in {1..60}; do
    sleep 10
    ONLINE_STATUS="$(node meshctrl --loginuser "$SERVER_USERNAME" \
        --loginpass "$SERVER_PASSWORD" --url "$SERVER_URL" \
        ListDevices --filter "^${DEVICE}\$" --csv | \
    sed "s|^\([^,]*,\)\{5\}\([^\"]*\)\(,[^,]*\)\{1\}|\2|")"
    if [[ "$ONLINE_STATUS" != 1 ]]; then
        echo "Attempt ${ATTEMPT}: Device not online."
    else
        echo "Attempt ${ATTEMPT}: Device online."
        break;
    fi
done
