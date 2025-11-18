# MCP Memory Server - Encrypted context/memory storage for privacy mode
# Provides persistent memory with encryption for sensitive data

FROM node:20-alpine

LABEL description="MCP Memory Server - Encrypted context storage"
LABEL version="1.0.0"

# Install dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    openssl

# Create app directory
WORKDIR /app

# Install MCP memory server
RUN npm install -g @modelcontextprotocol/server-memory

# Install encryption dependencies
RUN npm install node-forge bcrypt

# Create memory storage directory
RUN mkdir -p /data/memory && \
    chmod 700 /data/memory

# Create non-root user
RUN addgroup -g 1002 mcpmem && \
    adduser -D -u 1002 -G mcpmem mcpmem && \
    chown -R mcpmem:mcpmem /data

# Switch to non-root user
USER mcpmem

# Expose MCP server port
EXPOSE 3003

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3003/health || exit 1

# Start MCP memory server with encryption
CMD ["npx", "@modelcontextprotocol/server-memory", \
     "--storage-path", "/data/memory", \
     "--encryption", "aes-256-gcm", \
     "--port", "3003"]
