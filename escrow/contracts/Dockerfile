FROM node:22-slim

WORKDIR /usr/src/app

COPY package*.json ./
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci --no-audit --no-fund

COPY . .

EXPOSE 8545

CMD ["npm", "exec", "hardhat", "--", "node"]