# Getting started

Add to etc/hosts

```bash
sudo nano /etc/hosts
```

add

`127.0.0.1  relay`

Launch all services to fully test app.

```bash
docker-compose up -d nginx-proxy bitcoind relay lnd1 lnd2 lnbits1 lnbits2 albyhub1 albyhub2 evm
```

Open lnsats, install the lnurp extension and create lightning addresses + import nostr keys for zaps

Open channel between nodes

```bash
sh docker/setup.sh
sh docker/certs.sh
```

Launch a local relay.

```bash
docker-compose up relay
```

Wipe the local relay.

```bash
docker-compose rm -v relay
```

Seed the relay.

```bash
dart run app/lib/data/stubs/seed_mock.dart
```

Boltz exchange

cd ../
git clone git@github.com:BoltzExchange/regtest.git boltz
cd boltz
export DOCKER_DEFAULT_PLATFORM=linux/amd64
./start.sh