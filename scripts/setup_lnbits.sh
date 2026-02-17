#!/bin/bash

setup_lnbits() {
    # Check if the correct number of arguments is provided
    if [ "$#" -ne 2 ]; then
        echo "Usage: $0 <port> <username>"
        exit 1
    fi

    # Get the arguments
    local PORT=$1
    local USERNAME=$2

    # Load environment variables
    if [ -f "$(dirname "${BASH_SOURCE[0]}")/../.env" ]; then
        export $(cat "$(dirname "${BASH_SOURCE[0]}")/../.env" | grep -v '^#' | xargs)
    fi

    # Define variables
    local LNBITS_URL="http://localhost:$PORT"
    local ADMIN_EMAIL="${LNBITS_ADMIN_EMAIL}"
    local ADMIN_PASSWORD="${LNBITS_ADMIN_PASSWORD}"
    local EXTENSION_NAME="${LNBITS_EXTENSION_NAME}"
    local LNBITS_NOSTR_PRIVATE_KEY="${LNBITS_NOSTR_PRIVATE_KEY}"
    local admin_token=""
    local first_wallet_id=""
    local first_wallet_key=""

    # Function to log in as admin and get the admin token
    login_admin() {
        response=$(curl -s -L -X PUT "$LNBITS_URL/api/v1/auth/first_install" \
            -H "Content-Type: application/json" \
            -d "{\"username\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\", \"password_repeat\":\"$ADMIN_PASSWORD\"}")
        echo $response
        if echo "$response" | grep -q '"detail":"This is not your first install"'; then
            response=$(curl -s -L -X POST "$LNBITS_URL/api/v1/auth" \
                -H "Content-Type: application/json" \
                -d "{\"username\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")
        fi
        echo $response
        admin_token=$(echo $response | jq -r '.access_token')
        if [ "$admin_token" == "null" ]; then
            echo "Failed to log in as admin"
            exit 1
        fi
        echo $admin_token
        echo "Admin logged in successfully"
    }

    # Function to enable an extension
    enable_extension() {
        response=$(curl -s -L -X POST "$LNBITS_URL/api/v1/extension" \
            -H "Authorization: Bearer $admin_token" \
            -H "Content-Type: application/json" \
            -d '{
                "ext_id": "'"$EXTENSION_NAME"'",
                "archive": "https://github.com/lnbits/lnurlp/archive/refs/tags/v1.3.0.zip",
                "source_repo": "https://raw.githubusercontent.com/lnbits/lnbits-extensions/main/extensions.json",
                "version": "1.3.0",
                "cost_sats": null,
                "payment_hash": null
            }')
        echo $response
        if [ "$(echo $response | jq -r '.is_valid')" != "true" ]; then
            echo "Failed to enable extension: $EXTENSION_NAME"
            exit 1
        fi
        echo "Extension installed successfully: $EXTENSION_NAME"

        response=$(curl -s -X PUT "$LNBITS_URL/api/v1/extension/$EXTENSION_NAME/enable" \
            -H "Authorization: Bearer $admin_token" \
            -H "Content-Type: application/json")
        echo $response
        if [ "$(echo $response | jq -r '.success')" != "true" ]; then
            echo "Failed to enable extension: $EXTENSION_NAME"
            exit 1
        fi
        echo "Extension enabled successfully: $EXTENSION_NAME"
    }

    # Function to get the first wallet ID
    get_first_wallet_id() {
        response=$(curl -s -L -X GET "$LNBITS_URL/api/v1/wallets" \
            -H "Authorization: Bearer $admin_token")
        first_wallet_id=$(echo $response | jq -r '.[0].id')
        first_wallet_key=$(echo $response | jq -r '.[0].adminkey')
        echo $first_wallet_key
        echo "key"
        if [ "$first_wallet_id" == "null" ]; then
            echo "Failed to get the first wallet ID"
            exit 1
        fi
        echo $first_wallet_id
    }

    # Function to configure lnurlp settings (optional)
    configure_lnurlp_settings() {
        if [ -z "$LNBITS_NOSTR_PRIVATE_KEY" ]; then
            echo "LNBITS_NOSTR_PRIVATE_KEY not set. lnurlp will use its auto-generated Nostr key for zap receipts."
            return
        fi

        settings_response=$(curl -s -L -X GET "$LNBITS_URL/lnurlp/api/v1/settings" \
            -H "Authorization: Bearer $admin_token" \
            -H "Content-Type: application/json")

        if [ "$(echo "$settings_response" | jq -r '.detail // empty')" != "" ]; then
            echo "Failed to read lnurlp settings: $settings_response"
            exit 1
        fi

        payload=$(echo "$settings_response" | jq --arg key "$LNBITS_NOSTR_PRIVATE_KEY" '.nostr_private_key = $key')
        update_response=$(curl -s -L -X PUT "$LNBITS_URL/lnurlp/api/v1/settings" \
            -H "Authorization: Bearer $admin_token" \
            -H "Content-Type: application/json" \
            -d "$payload")

        if [ "$(echo "$update_response" | jq -r '.nostr_private_key // empty')" = "" ]; then
            echo "Failed to update lnurlp Nostr private key: $update_response"
            exit 1
        fi

        echo "Configured lnurlp Nostr private key for zap receipt signing"
    }

    # Function to post data to the link
    post_data() {
        response=$(curl -s -L -X POST "$LNBITS_URL/lnurlp/api/v1/links" \
            -H "X-Api-Key: $first_wallet_key" \
            -H "Authorization: Bearer $admin_token" \
            -H "Content-Type: application/json" \
            -d '{
                "comment_chars": 0,
                "description": "testing",
                "max": 10000000,
                "min": 1,
                "username": "'$USERNAME'",
                "wallet": "'$first_wallet_id'",
                "zaps": true
            }')
        echo $response
        detail=$(echo $response | jq -r '.detail')
        echo "$detail"
        if [ "$detail" != "" ] && [ "$detail" != "null" ]; then
            if echo "$detail" | grep -q "Username already taken"; then
                echo "Username already exists, skipping creation"
            else
                echo "Failed to post data"
                exit 1
            fi
        else
            echo "Data posted successfully"
        fi
        
        # Create tips@ username
        response=$(curl -s -L -X POST "$LNBITS_URL/lnurlp/api/v1/links" \
            -H "X-Api-Key: $first_wallet_key" \
            -H "Authorization: Bearer $admin_token" \
            -H "Content-Type: application/json" \
            -d '{
                "comment_chars": 0,
                "description": "tips",
                "max": 10000000,
                "min": 1,
                "username": "tips",
                "wallet": "'$first_wallet_id'",
                "zaps": true
            }')
        echo $response
        detail=$(echo $response | jq -r '.detail')
        echo "$detail"
        if [ "$detail" != "" ] && [ "$detail" != "null" ]; then
            if echo "$detail" | grep -q "Username already taken"; then
                echo "Tips username already exists, skipping creation"
            else
                echo "Failed to create tips username"
                exit 1
            fi
        else
            echo "Tips username created successfully"
        fi
    }

    # Main script execution
    login_admin
    enable_extension
    configure_lnurlp_settings
    get_first_wallet_id
    post_data
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_lnbits "$@"
fi
