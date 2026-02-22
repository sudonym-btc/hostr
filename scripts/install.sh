#!/bin/bash

install_hostr() {
    # Remove legacy /etc/hosts entry (dnsmasq handles resolution now)
    if grep -q "relay.hostr.development" /etc/hosts; then
        echo "Removing legacy relay.hostr.development from /etc/hosts (dnsmasq handles this)..."
        sudo sed -i '' '/relay\.hostr\.development/d' /etc/hosts
    fi

    # Install and configure dnsmasq
    if ! brew list dnsmasq &>/dev/null; then
        echo "Installing dnsmasq..."
        brew install dnsmasq
        sh docker/certs.sh
    fi

    # Determine the IP to advertise for .hostr.development:
    # - Tailscale IP if available (stable across networks, reachable from mobile)
    # - 127.0.0.1 as fallback (local-only development)
    if command -v tailscale &>/dev/null && tailscale ip -4 &>/dev/null; then
        HOSTR_IP=$(tailscale ip -4)
        echo "Using Tailscale IP ($HOSTR_IP) for .hostr.development"
        echo "Tip: Add a split DNS entry in Tailscale admin for 'hostr.development' → $HOSTR_IP"
        echo "     so mobile devices on your tailnet resolve automatically."
    else
        HOSTR_IP="127.0.0.1"
        echo "Tailscale not found — using 127.0.0.1 (local-only, no mobile access)"
    fi

    DNSMASQ_CONF=$(brew --prefix)/etc/dnsmasq.conf
    if [ -f "$DNSMASQ_CONF" ]; then
        if grep -q "address=/.hostr.development/" "$DNSMASQ_CONF"; then
            # Update existing entry to current IP
            sed -i '' "s|address=/.hostr.development/.*|address=/.hostr.development/$HOSTR_IP|" "$DNSMASQ_CONF"
        else
            echo "Configuring dnsmasq for .hostr.development..."
            echo "address=/.hostr.development/$HOSTR_IP" >> "$DNSMASQ_CONF"
            echo 'port=53' >> "$DNSMASQ_CONF"
        fi

        # Ensure dnsmasq listens on Tailscale interface (for mobile access)
        if [ "$HOSTR_IP" != "127.0.0.1" ]; then
            if grep -q "listen-address=" "$DNSMASQ_CONF"; then
                sed -i '' "s|listen-address=.*|listen-address=127.0.0.1,$HOSTR_IP|" "$DNSMASQ_CONF"
            else
                echo "listen-address=127.0.0.1,$HOSTR_IP" >> "$DNSMASQ_CONF"
            fi
        fi
    fi

    # Ensure dnsmasq is running (system level)
    if sudo brew services list 2>/dev/null | grep -q "dnsmasq.*started"; then
        sudo brew services restart dnsmasq
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
