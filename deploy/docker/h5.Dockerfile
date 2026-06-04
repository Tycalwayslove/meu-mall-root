FROM node:22-bookworm-slim AS deps

WORKDIR /app/hybird-meumall

RUN corepack enable && corepack prepare pnpm@10.19.0 --activate
RUN pnpm config set registry https://registry.npmmirror.com

COPY hybird-meumall/package.json hybird-meumall/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

FROM deps AS builder

ARG H5_BASE_PATH=
ARG H5_ASSET_PREFIX=
ARG H5_VERSION=unknown
ARG H5_RELEASE_LABEL=
ARG NEXT_PUBLIC_H5_ASSET_BASE_URL=
ARG NEXT_PUBLIC_CONFIG_API_BASE_URL=/
ARG NEXT_PUBLIC_H5_MANIFEST_URL=/api/h5/manifest/active?environment=prod
ARG H5_MANIFEST_URL=https://hybird.aigcpop.com/api/h5/manifest/active?environment=prod

ENV H5_BASE_PATH=${H5_BASE_PATH} \
    H5_ASSET_PREFIX=${H5_ASSET_PREFIX} \
    NEXT_PUBLIC_H5_BASE_PATH=${H5_BASE_PATH} \
    NEXT_PUBLIC_H5_ASSET_BASE_URL=${NEXT_PUBLIC_H5_ASSET_BASE_URL} \
    H5_VERSION=${H5_VERSION} \
    H5_RELEASE_LABEL=${H5_RELEASE_LABEL} \
    NEXT_PUBLIC_CONFIG_API_BASE_URL=${NEXT_PUBLIC_CONFIG_API_BASE_URL} \
    NEXT_PUBLIC_H5_MANIFEST_URL=${NEXT_PUBLIC_H5_MANIFEST_URL} \
    H5_MANIFEST_URL=${H5_MANIFEST_URL}

COPY hybird-meumall ./
RUN pnpm build

FROM node:22-bookworm-slim AS runner

ENV NODE_ENV=production \
    HOSTNAME=0.0.0.0 \
    PORT=3109 \
    H5_VERSION=unknown \
    H5_RELEASE_LABEL=

WORKDIR /app

COPY --from=builder /app/hybird-meumall/.next/standalone ./
COPY --from=builder /app/hybird-meumall/.next/static ./.next/static
COPY --from=builder /app/hybird-meumall/public ./public

EXPOSE 3109

CMD ["node", "server.js"]
