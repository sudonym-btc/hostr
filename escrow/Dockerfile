FROM dart:stable

WORKDIR /workspace

COPY escrow /workspace/escrow
COPY hostr_sdk /workspace/hostr_sdk
COPY models /workspace/models

WORKDIR /workspace/escrow

RUN dart pub get

CMD ["dart", "run", "lib/cli.dart", "start"]