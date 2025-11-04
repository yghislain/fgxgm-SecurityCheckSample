# Use updated base image
FROM node:18.20.0-slim

# CRITICAL: Update all packages including libwebp and curl
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    libwebp7=1.2.4-0.2+deb12u1 \
    curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r nodeuser && \
    useradd -r -g nodeuser nodeuser

WORKDIR /app

# Copy and install dependencies
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application
COPY --chown=nodeuser:nodeuser index.js ./
COPY --chown=nodeuser:nodeuser build ./build

# Switch to non-root user
USER nodeuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
    CMD node -e "require('http').get('http://localhost:8080/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["node", "index.js"]
