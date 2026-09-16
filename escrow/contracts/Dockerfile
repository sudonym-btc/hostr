FROM node:26.8.2-bookworm-slim
RUN npm install --global npm@12.0.2 --no-fund --no-audit

WORKDIR /usr/src/app

COPY package*.json ./
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci --no-audit --no-fund

COPY . .

# Supplied by Compose's additional_contexts; no second Solidity source/compiler.
COPY --from=nmdk-contracts /artifacts/MultiEscrow.json /usr/src/app/nmdk-artifacts/MultiEscrow.json
ENV NMDK_ESCROW_ARTIFACT=/usr/src/app/nmdk-artifacts/MultiEscrow.json

RUN npm run compile

EXPOSE 8545

CMD ["npm", "exec", "hardhat", "--", "node"]
