FROM node:lts AS base

RUN \
  deluser --remove-home node && \
  groupadd --gid 1000 nodered && \
  useradd --gid nodered --uid 1000 --shell /bin/bash --create-home nodered

RUN \
  mkdir -p /data && \
  chown 1000:1000 /data

WORKDIR /data

# Build
FROM base AS build

RUN \
  apt-get update && \
  apt-get install -qy build-essential python perl-modules

COPY --chown=1000:1000 ./package.json /data/

USER 1000

RUN npm install --production

## Release
FROM base AS release

RUN \
  apt-get update && \
  apt-get install -y perl-modules && \
  rm -rf /var/lib/apt/lists/*

COPY --chown=1000:1000 ./* /data/
COPY --from=build --chown=1000:1000 /data/node_modules /data/node_modules

ENV PORT=1880
ENV NODE_ENV=production
ENV NODE_PATH=/data/node_modules
ENV NODE_RED_HOME=/data
EXPOSE 1880

USER 1000

CMD ["node", "/data/server.js", "/data/flows.json"]
