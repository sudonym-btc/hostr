# Getting started

<!--
This is now part of start_local.sh
Add to etc/hosts

```bash
sudo nano /etc/hosts
```

add

`127.0.0.1  relay` -->

Install dnsmasq and route hostr.development to docker.

```bash
# sh docker/certs.sh
```

Launch all services to fully test app.

Light mode (does not launch boltz for chain swaps)

```bash
./start_local.sh
```

Full escrow mode exchange

```bash
./start.sh
```

Power down.

```bash
./stop.sh
```

Wipe the local relay.

```bash
docker-compose rm -v relay
```

Seed the relay.

```bash
dart run app/lib/stubs/seed.dart wss://relay.hostr.development
```

Fund EVM balance:

docker exec into anvil

```bash
cast rpc anvil_setBalance 0x92c68728fcb57cbe40d9ec9ced82233146af3565 48543953908
```
