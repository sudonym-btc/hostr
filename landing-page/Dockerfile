FROM node:16-bullseye AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends ruby-full build-essential \
    && gem install bundler -v 1.17.2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY Gemfile Gemfile.lock ./
RUN bundle _1.17.2_ install

COPY . .
RUN npm run build

FROM nginx:1.27-alpine
COPY --from=builder /app/_site /usr/share/nginx/html
EXPOSE 80
