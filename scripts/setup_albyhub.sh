#!/bin/bash

setup_albyhub() {
    # Check if the correct number of arguments is provided
    if [ "$#" -ne 3 ]; then
        echo "Usage: $0 <url> <app_name> <password>"
        exit 1
    fi

    # Get the arguments
    local ALBYHUB_URL=$1
    local APP_NAME=$2
    local PASSWORD=$3
    local AUTH_TOKEN=""

    # Function to setup AlbyHub
    setup_albyhub_init() {
        response=$(curl -s -k -X POST "$ALBYHUB_URL/api/setup" \
            -H "Content-Type: application/json" \
            -d '{
                "unlockPassword": "'"$PASSWORD"'"
            }')
        
        echo "$response"
        
        if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
            error=$(echo "$response" | jq -r '.error')
            if echo "$error" | grep -q "already set up"; then
                echo "AlbyHub is already set up"
                return 0
            else
                echo "Failed to setup AlbyHub: $error"
                return 1
            fi
        fi
        
        echo "AlbyHub setup completed"
        return 0
    }

    # Function to start AlbyHub after setup
    start_albyhub() {
        response=$(curl -s -k -X POST "$ALBYHUB_URL/api/start" \
            -H "Content-Type: application/json" \
            -d "{\"unlockPassword\": \"$PASSWORD\"}")

        echo "$response"

        if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
            error=$(echo "$response" | jq -r '.error')
            if echo "$error" | grep -q "already started"; then
                echo "AlbyHub already started"
                return 0
            else
                echo "Failed to start AlbyHub: $error"
                return 1
            fi
        fi

        # Extract the JWT token if present
        if echo "$response" | jq -e '.token' > /dev/null 2>&1; then
            AUTH_TOKEN=$(echo "$response" | jq -r '.token')
            echo "Successfully got token from start"
        fi

        echo "AlbyHub start completed"
        return 0
    }

    # Function to get authorization token
    unlock() {
        response=$(curl -s -k -X POST "$ALBYHUB_URL/api/unlock" \
            -H "Content-Type: application/json" \
            -d '{
                "permission": "full",
                "unlockPassword": "'"$PASSWORD"'"
            }')
        echo "$response"
        
        if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
            error=$(echo "$response" | jq -r '.error')
            echo "Failed to authenticate: $error"
            return 1
        fi
        
        # Extract the JWT token
        if echo "$response" | jq -e '.token' > /dev/null 2>&1; then
            AUTH_TOKEN=$(echo "$response" | jq -r '.token')
            echo "Successfully authenticated with AlbyHub"
            return 0
        fi
        
        # Check if already unlocked
        if echo "$response" | jq -e '.message' > /dev/null 2>&1; then
            message=$(echo "$response" | jq -r '.message')
            if echo "$message" | grep -q "already unlocked"; then
                echo "AlbyHub is already unlocked"
                return 0
            fi
        fi
        
        echo "Successfully authenticated with AlbyHub"
        echo $AUTH_TOKEN
    }

    # Function to create app connection
    create_app() {
        response=$(curl -s -k -X POST "$ALBYHUB_URL/api/apps" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $AUTH_TOKEN" \
            -d '{
                "name": "'"$APP_NAME"'",
                "pubkey": "",
                "budgetRenewal": "yearly",
                "maxAmount": 0,
                "metadata": {},
                "returnTo": "",
                "scopes": [
                    "pay_invoice",
                    "get_info",
                    "get_balance",
                    "make_invoice",
                    "lookup_invoice",
                    "list_transactions",
                    "notifications"
                ],
                "isolated": false,
                "unlockPassword": "'"$PASSWORD"'"
            }')
        
        echo "$response"
        
        # Check if the response contains an error
        if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
            error=$(echo "$response" | jq -r '.error')
            if echo "$error" | grep -q "app already exists"; then
                echo "App '$APP_NAME' already exists, skipping creation"
                return 0
            else
                echo "Failed to create app: $error"
                return 1
            fi
        fi
        
        # Check for error in message field
        if echo "$response" | jq -e '.message' > /dev/null 2>&1; then
            message=$(echo "$response" | jq -r '.message')
            if echo "$message" | grep -q -i "failed\|error"; then
                echo "Failed to create app: $message"
                return 1
            fi
        fi
        
        # Extract and display the pairingSecretKey if present
        if echo "$response" | jq -e '.pairingSecretKey' > /dev/null 2>&1; then
            pairing_uri=$(echo "$response" | jq -r '.pairingUri')
            echo "App created successfully"
            echo "Pairing URI: $pairing_uri"
            return 0
        fi
        
        echo "App setup completed"
    }

    # Main script execution
    setup_albyhub_init
    start_albyhub

    # Wait to avoid rate limiting
    echo "Waiting to avoid rate limit..."
    sleep 3
    
    # Always get auth token via unlock
    echo "Getting auth token..."
    unlock

    # Verify we have a token before proceeding
    if [ -z "$AUTH_TOKEN" ]; then
        echo "Failed to get authentication token, cannot create app"
        exit 1
    fi

    echo "Using auth token to create app..."
    create_app
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_albyhub "$@"
fi
