# Getting started

Add to etc/hosts

```bash
sudo nano /etc/hosts
```

add

`127.0.0.1  relay`

Launch all services to fully test app.

```bash
docker network create shared_network
```

Light mode

```bash
./start_local.sh
```

Full escrow mode exchange

```bash
./start.sh
```

Open lnsats, install the lnurp extension and create lightning addresses + import nostr keys for zaps

Open channel between nodes

```bash
sh docker/certs.sh
```

Launch a local relay.

```bash
docker-compose up relay
```

Power down.
(cd ./docker/boltz && ./stop.sh) && docker-compose down --volumes


Wipe the local relay.

```bash
docker-compose rm -v relay
```

Seed the relay.

```bash
dart run app/lib/data/stubs/seed_mock.dart
```

Fund EVM balance:

docker exec into anvil 

```bash
cast rpc anvil_setBalance 0x92c68728fcb57cbe40d9ec9ced82233146af3565 48543953908
```