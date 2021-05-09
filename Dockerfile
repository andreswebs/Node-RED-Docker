FROM node:16-buster-slim AS base

RUN \
  apt-get update > /dev/null && \
  apt-get install -qy perl-modules git && \
  deluser --remove-home node && \
  groupadd --gid 1000 node-red && \
  useradd --gid node-red --uid 1000 --shell /bin/bash --create-home node-red && \
  apt-get remove -qy perl-modules && \
  apt-get clean && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

RUN \
  mkdir -p /data && \
  chown node-red:node-red /data

WORKDIR /data

# Build
FROM base AS build

RUN \
  apt-get update > /dev/null && \
  apt-get install -qy \
    gcc \
    g++ \
    make \
    perl-modules \
    python3 && \
  ln -s /usr/bin/python3 /usr/bin/python && \
  rm -rf /var/lib/apt/lists/*

COPY --chown=node-red:node-red ./src/* /data/

USER node-red

RUN \
  npm install --production

## Release
FROM base AS release

COPY --chown=node-red:node-red ./src/* /data/
COPY --from=build --chown=node-red:node-red /data/node_modules /data/node_modules

ENV PORT=1880
ENV NODE_ENV=production
ENV NODE_PATH=/data/node_modules
ENV NODE_RED_HOME=/data
EXPOSE 1880

USER node-red

CMD ["node", "/data/server.js", "/data/flows.json"]
