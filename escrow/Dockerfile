FROM dart:stable

WORKDIR /workspace

COPY escrow /workspace/escrow
COPY hostr_sdk /workspace/hostr_sdk
COPY models /workspace/models

WORKDIR /workspace/escrow

RUN dart pub get
RUN chmod +x docker/entrypoint.sh docker/escrow-cli.sh \
    && install -m 0755 docker/escrow-cli.sh /usr/local/bin/escrow-cli \
    && printf '%s\n' "alias escrow-cli='dart run /workspace/escrow/bin/cli.dart'" > /etc/profile.d/escrow-cli.sh

ENTRYPOINT ["docker/entrypoint.sh"]