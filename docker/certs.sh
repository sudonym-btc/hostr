(
    cd certs
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout lnbits1.hostr.development.key \
        -out lnbits1.hostr.development.crt \
        -subj "/CN=lnbits1.hostr.development"
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ./lnbits1.hostr.development.crt

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout lnbits2.hostr.development.key \
        -out lnbits2.hostr.development.crt \
        -subj "/CN=lnbits2.hostr.development"
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ./lnbits2.hostr.development.crt

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout relay.hostr.development.key \
        -out relay.hostr.development.crt \
        -subj "/CN=relay.hostr.development"
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ./relay.hostr.development.crt
)
# Setup wildcard routing for .local domains
brew install dnsmasq
mkdir -pv $(brew --prefix)/etc/
echo 'address=/.hostr.development/127.0.0.1' >>$(brew --prefix)/etc/dnsmasq.conf
echo 'port=53' >>$(brew --prefix)/etc/dnsmasq.conf
sudo brew services start dnsmasq
sudo mkdir -v /etc/resolver
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/development'
