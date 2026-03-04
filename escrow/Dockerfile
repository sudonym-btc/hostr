FROM dart:stable

WORKDIR /workspace

COPY escrow /workspace/escrow
COPY hostr_sdk /workspace/hostr_sdk
COPY models /workspace/models

WORKDIR /workspace/escrow

RUN dart pub get

# Default: run the daemon (long-running process).
# Override with `docker exec … dart run bin/cli.dart` to attach the CLI.
CMD ["dart", "run", "bin/daemon.dart"]