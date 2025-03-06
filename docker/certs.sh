(
    cd certs
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout lnbits1.local.key \
        -out lnbits1.local.crt \
        -subj "/CN=lnbits1.local"
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ./lnbits1.local.crt

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout lnbits2.local.key \
        -out lnbits2.local.crt \
        -subj "/CN=lnbits2.local"
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ./lnbits2.local.crt
)
# Setup wildcard routing for .local domains
brew install dnsmasq
mkdir -pv $(brew --prefix)/etc/
echo 'address=/.local/127.0.0.1' >>$(brew --prefix)/etc/dnsmasq.conf
echo 'port=53' >>$(brew --prefix)/etc/dnsmasq.conf
sudo brew services start dnsmasq
sudo mkdir -v /etc/resolver
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/local'
