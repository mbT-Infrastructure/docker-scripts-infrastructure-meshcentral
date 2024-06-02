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

echo "Run command on \"${DEVICE}\"."

DEVICE_ID="$(node meshctrl --loginuser "$SERVER_USERNAME" \
        --loginpass "$SERVER_PASSWORD" --url "$SERVER_URL" \
        ListDevices --filter "^${DEVICE}\$" --csv | \
    sed "s|^\([^,]*,\)\{2\}\"\([^\"]*\)\"\(,[^,]*\)\{4\}|\2|")"
mkfifo output
node meshctrl --loginuser "$SERVER_USERNAME" --loginpass "$SERVER_PASSWORD" \
    --url "$SERVER_URL" RunCommand --id "$DEVICE_ID" --reply --run \
    "bash -c \"${COMMAND[*]} || echo -n failedRunCommand\"" \
        | tee output &
tail --lines 1 < output \
    | grep --invert-match --silent failedRunCommand
rm output
