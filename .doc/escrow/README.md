# Escrow

Repo for listening to nostr events, running required L2 nodes and forwarding or reversing payments.

## CLI Demo

The CLI demo is recorded with [VHS](https://github.com/charmbracelet/vhs).
The escrow `Dockerfile` has a `vhs` target that combines the AOT-compiled CLI
binary with Charm's VHS image — no Dart SDK needed at recording time.

### Build the image (from repo root)

```bash
docker build --target vhs -f escrow/Dockerfile -t escrow-vhs .
```

### Record (with daemon running on the host)

```bash
docker run --rm \
  -v $PWD/escrow:/vhs \
  -v $TMPDIR/escrow_daemon.sock:/tmp/escrow_daemon.sock \
  -e ESCROW_SOCKET=/tmp/escrow_daemon.sock \
  escrow-vhs demo.tape
```

This produces `escrow/escrow-cli.gif` and `escrow/escrow-cli.png`.

> **Note:** The daemon must be reachable via the mounted Unix socket.
> Start it on the host first with `dart run bin/daemon.dart`.
> On macOS, `$TMPDIR` is not `/tmp` — it's something like
> `/var/folders/…/T/` — so we mount the socket into the container at
> `/tmp` and tell the CLI to look there with `ESCROW_SOCKET`.
