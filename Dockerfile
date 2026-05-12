# Multi-stage Alpine (même esprit que sesame-orchestrator) : build isolé, runtime avec node_modules complet pour `start.mjs` (rebuild si `.env` change).
FROM node:22-alpine AS builder

WORKDIR /data

RUN apk add --no-cache git

COPY package.json yarn.lock ./

RUN yarn install \
  --prefer-offline \
  --frozen-lockfile \
  --non-interactive \
  --production=false

COPY . .

RUN yarn build

FROM node:22-alpine AS production

ARG NODE_ENV=production
ARG BUILD_VERSION=dev
ARG GIT_BRANCH=unknown
ARG GIT_COMMIT=unknown
ARG DOCKER_TAG=unknown

ENV NODE_ENV=${NODE_ENV}
ENV BUILD_VERSION=${BUILD_VERSION}
ENV GIT_BRANCH=${GIT_BRANCH}
ENV GIT_COMMIT=${GIT_COMMIT}
ENV DOCKER_TAG=${DOCKER_TAG}
ENV DO_NOT_TRACK=1
ENV TZ=Europe/Paris

WORKDIR /data

RUN apk add --no-cache \
  git \
  openssl \
  jq \
  bash \
  tzdata \
  && cp "/usr/share/zoneinfo/${TZ}" /etc/localtime \
  && echo "${TZ}" > /etc/timezone

COPY package.json yarn.lock ./

# Même jeu de fichiers que le builder : `start.mjs` peut relancer `yarn build` si le hash `.env` change.
COPY --from=builder /data/node_modules ./node_modules
COPY --from=builder /data/.output ./.output
COPY --from=builder /data/start.mjs ./start.mjs
COPY --from=builder /data/nuxt.config.ts ./nuxt.config.ts
COPY --from=builder /data/tsconfig.json ./tsconfig.json
COPY --from=builder /data/src ./src
COPY --from=builder /data/playwright.config.ts ./playwright.config.ts
COPY --from=builder /data/vitest.config.ts ./vitest.config.ts
COPY --from=builder /data/tests ./tests

RUN yarn cache clean \
  && rm -rf /tmp/* /var/cache/apk/* /root/.npm /root/.node-gyp

EXPOSE 3000

CMD ["yarn", "run", "start:prod"]
