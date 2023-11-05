#!/usr/bin/env bash
set -e

COMMAND=""
DEVICE=""

# help message
for ARGUMENT in "$@"; do
    if [ "$ARGUMENT" == "-h" ] || [ "$ARGUMENT" == "--help" ]; then
        echo "usage: $(basename "$0") [ARGUMENT]"
        echo "Run a command on a device connected to MeshCentral."
        echo "Make sure following environment variables are set:"
        echo "    SERVER_URL, SERVER_USERNAME, SERVER_PASSWORD"
        echo "ARGUMENT can be"
        echo "    --command COMMAND The command to execute."
        echo "    --device DEVICE The device name."
        exit
    fi
done

# check arguments
while [[ -n "$1" ]]; do
    if [[ "$1" == "--command" ]]; then
        shift
        COMMAND="$1"
    elif [[ "$1" == "--device" ]]; then
        shift
        DEVICE="$1"
    else
        echo "Unknown argument: \"$1\""
        exit 1
    fi
    shift
done

cd /opt/meshcentral/node_modules/meshcentral

DEVICE_ID="$(node meshctrl --loginuser "$SERVER_USERNAME" \
        --loginpass "$SERVER_PASSWORD" --url "$SERVER_URL" \
        ListDevices --filter "^${DEVICE}\$" --csv | \
    sed "s|^\([^,]*,\)\{2\}\"\([^\"]*\)\"\(,[^,]*\)\{4\}|\2|")"
node meshctrl --loginuser "$SERVER_USERNAME" --loginpass "$SERVER_PASSWORD" \
    --url "$SERVER_URL" RunCommand --id "$DEVICE_ID" --run \
    "bash -c \"(${COMMAND[*]} && echo finishedRunCommand || echo failedRunCommand) &> \
        /tmp/meshcentral-run-on-device.log\""
echo "Started command \"${COMMAND}\""
echo > meshcentral-run-on-device.log
while ! (tail -n 1 < meshcentral-run-on-device.log | grep finishedRunCommand > /dev/null); do
    sleep 3
    for ATTEMPT in {1..10}; do
        node meshctrl --loginuser "$SERVER_USERNAME" \
            --loginpass "$SERVER_PASSWORD" --url "$SERVER_URL" Download \
            --id "$DEVICE_ID" --file /tmp/meshcentral-run-on-device.log \
            --target meshcentral-run-on-device-new.log \
            > /dev/null
        if [[ ! -f meshcentral-run-on-device-new.log ]]; then
            echo "Attempt ${ATTEMPT}: Failed to download new status."
            sleep 5
        else
            break;
        fi
    done
    comm -3 --nocheck-order meshcentral-run-on-device.log meshcentral-run-on-device-new.log
    mv meshcentral-run-on-device-new.log meshcentral-run-on-device.log
    (tail -n 1 < meshcentral-run-on-device.log | grep failedRunCommand > /dev/null) && exit 1
done
rm meshcentral-run-on-device.log
node meshctrl --loginuser "$SERVER_USERNAME" --loginpass "$SERVER_PASSWORD" \
    --url "$SERVER_URL" RunCommand --id "$DEVICE_ID" --run \
    "rm /tmp/meshcentral-run-on-device.log"
sleep 3
