FROM node:22-bookworm-slim AS builder

WORKDIR /app/admin-meumall

RUN corepack enable && corepack prepare pnpm@10.19.0 --activate
RUN pnpm config set registry https://registry.npmmirror.com

COPY admin-meumall/package.json admin-meumall/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

ARG VITE_CONFIG_API_BASE_URL=/
ARG VITE_BASE_PATH=/admin/

ENV VITE_CONFIG_API_BASE_URL=${VITE_CONFIG_API_BASE_URL}

COPY admin-meumall ./
RUN pnpm exec tsc -b && pnpm exec vite build --base="${VITE_BASE_PATH}"

FROM nginx:1.27-alpine

COPY deploy/nginx/admin-container.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/admin-meumall/dist /usr/share/nginx/html/admin

EXPOSE 80
