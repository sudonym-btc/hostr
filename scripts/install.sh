#!/bin/bash

install_hostr() {
    # Ensure hosts entry exists for local development
    if ! grep -q "127.0.0.1.*relay.hostr.development" /etc/hosts; then
        echo "Adding relay.hostr.development to /etc/hosts..."
        echo "127.0.0.1  relay.hostr.development" | sudo tee -a /etc/hosts > /dev/null
    fi

    # Install and configure dnsmasq
    if ! brew list dnsmasq &>/dev/null; then
        echo "Installing dnsmasq..."
        brew install dnsmasq
        sh docker/certs.sh
    fi

    DNSMASQ_CONF=$(brew --prefix)/etc/dnsmasq.conf
    if [ -f "$DNSMASQ_CONF" ] && ! grep -q "address=/.hostr.development/" "$DNSMASQ_CONF"; then
        echo "Configuring dnsmasq for .hostr.development..."
        echo 'address=/.hostr.development/127.0.0.1' >> "$DNSMASQ_CONF"
        echo 'port=53' >> "$DNSMASQ_CONF"
    fi

    # Ensure dnsmasq is running (system level)
    if sudo brew services list 2>/dev/null | grep -q "dnsmasq.*started"; then
        :
    else
        echo "Starting dnsmasq..."
        sudo brew services start dnsmasq
    fi

    # Setup resolver for .development domains
    if [ ! -f /etc/resolver/development ]; then
        echo "Configuring /etc/resolver/development..."
        sudo mkdir -pv /etc/resolver
        sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/development'
    fi
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_hostr "$@"
fi
