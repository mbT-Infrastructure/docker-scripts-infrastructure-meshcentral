#!/usr/bin/env bash
set -e

# help message
for ARGUMENT in "$@"; do
    if [ "$ARGUMENT" == "-h" ] || [ "$ARGUMENT" == "--help" ]; then
        echo "usage: $(basename "$0")"
        echo "Test the connection to MeshCentral."
        echo "Make sure following environment variables are set:"
        echo "    SERVER_URL, SERVER_USERNAME, SERVER_PASSWORD"
        exit
    fi
done

cd /opt/meshcentral/node_modules/meshcentral

echo "Test connection to \"${SERVER_URL}\"."
SERVERINFO="$(node meshctrl --loginuser "$SERVER_USERNAME" \
    --loginpass "$SERVER_PASSWORD" --url "$SERVER_URL" serverinfo)"
echo "$SERVERINFO"
if (grep -q "Unable to connect" <<<"$SERVERINFO"); then
    exit 1
fi
