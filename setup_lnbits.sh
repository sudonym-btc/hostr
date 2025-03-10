#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <port> <username>"
    exit 1
fi

# Get the arguments
PORT=$1
USERNAME=$2

# Define variables
LNBITS_URL="http://localhost:$PORT" # Use the provided port in the LNbits URL
ADMIN_EMAIL="admin@example.com"    # Change this to the admin email
ADMIN_PASSWORD="adminpassword"     # Change this to the admin password
EXTENSION_NAME="lnurlp"            # Change this to the extension name you want to enable

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
            "archive": "https://github.com/lnbits/lnurlp/archive/refs/tags/v1.0.1.zip",
            "source_repo": "https://raw.githubusercontent.com/lnbits/lnbits-extensions/main/extensions.json",
            "version": "1.0.1",
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
    echo '{
            "comment_chars": 0,
            "description": "test",
            "max": 10000000,
            "min": 1,
            "username": "'$USERNAME'",
            "wallet": "'$first_wallet_id'",
            "zaps": true
        }'
    echo $response
    echo "$(echo $response | jq -r '.detail')"
    if [ "$(echo $response | jq -r '.detail')"  != ""  ]; then
        echo "Failed to post data"
        exit 1
    fi
    echo "Data posted successfully"
}

# Main script execution
login_admin
enable_extension
get_first_wallet_id
post_data
