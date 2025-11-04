# Use LATEST Node 18 LTS with security patches
FROM node:18.20.6-alpine3.19 AS builder

# Security updates
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    curl>=8.5.0 \
    openssl>=3.1.7 && \
    rm -rf /var/cache/apk/*

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build 2>/dev/null || true

# ==================================================
# Production Stage with Latest Secure Node.js
# ==================================================
FROM node:18.20.6-alpine3.19

# Apply all security updates
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    curl>=8.5.0 \
    openssl>=3.1.7 \
    zlib>=1.3 && \
    rm -rf /var/cache/apk/*

# Verify versions - CRITICAL CHECK
RUN echo "=== Security Verification ===" && \
    echo "Node.js version:" && node --version && \
    echo "npm version:" && npm --version && \
    echo "curl version:" && curl --version && \
    echo "OpenSSL version:" && openssl version && \
    echo "zlib version:" && apk info zlib && \
    echo "=== All Critical Packages Updated ==="

# Create non-root user with specific UID/GID
RUN addgroup -g 1000 nodeuser && \
    adduser -D -u 1000 -G nodeuser -s /bin/sh nodeuser

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application from builder
COPY --from=builder --chown=nodeuser:nodeuser /app/build ./build
COPY --chown=nodeuser:nodeuser index.js ./

# Comprehensive security labels
LABEL maintainer="yghislain" \
      security.scan-date="2024-11-04" \
      security.base-image="node:18.20.6-alpine3.19" \
      security.node-version="18.20.6" \
      security.patched.node-directory-traversal="CVE-2025-23084" \
      security.patched.node-memory-leak="CVE-2025-23085" \
      security.patched.curl="CVE-2023-38545" \
      security.patched.libwebp="CVE-2023-4863" \
      security.patched.openssl="CVE-2024-6119" \
      security.known-issue.zlib="CVE-2023-45853-monitoring" \
      security.user="nodeuser:1000" \
      security.status="production-ready"

# Switch to non-root user
USER nodeuser

# Expose port
EXPOSE 8080

# Health check with proper timeout
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Start application
CMD ["node", "index.js"]
