#!/usr/bin/env bash
set -e

if  [[ -z "$SERVER_PASSWORD" ]] || [[ -z "$SERVER_URL" ]] || [[ -z "$SERVER_USERNAME" ]]; then
    echo "Please set the environment variables \"SERVER_PASSWORD\", \"SERVER_URL\"," \
        "\"SERVER_USERNAME\""
    exit 1
fi

exec "$@"
