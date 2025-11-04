# Switch to Alpine which may have the fix
FROM node:18-alpine3.18

# Alpine uses musl-libc with different zlib
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    curl \
    zlib && \
    rm -rf /var/cache/apk/*

# Verify versions
RUN apk info zlib

# Rest of your Dockerfile...
RUN addgroup -g 1000 nodeuser && \
    adduser -D -u 1000 -G nodeuser nodeuser

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

COPY --chown=nodeuser:nodeuser index.js ./
COPY --chown=nodeuser:nodeuser build ./build

USER nodeuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["node", "index.js"]
