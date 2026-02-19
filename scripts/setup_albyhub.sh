#!/bin/bash

setup_albyhub() {
    if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
        echo "Usage: $0 <url> <app_name> <password> [user_pubkey]"
        return 1
    fi

    local ALBYHUB_URL=$1
    local APP_NAME=$2
    local PASSWORD=$3
    local USER_PUBKEY=${4:-}

    local ROOT_DIR
    ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
    local HOSTR_SDK_DIR="$ROOT_DIR/hostr_sdk"
    local DART_SCRIPT="test/integration/tools/setup_albyhub.dart"

    if [ ! -f "$HOSTR_SDK_DIR/$DART_SCRIPT" ]; then
        echo "Missing Dart script: $HOSTR_SDK_DIR/$DART_SCRIPT"
        return 1
    fi

    local cmd=(
        dart run "$DART_SCRIPT"
        --url "$ALBYHUB_URL"
        --app-name "$APP_NAME"
        --password "$PASSWORD"
        --output-dir "$ROOT_DIR/docker/data"
    )

    if [ -n "$USER_PUBKEY" ]; then
        cmd+=(--user-pubkey "$USER_PUBKEY")
    fi

    (
        cd "$HOSTR_SDK_DIR" || exit 1
        "${cmd[@]}"
    )
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_albyhub "$@"
fi
