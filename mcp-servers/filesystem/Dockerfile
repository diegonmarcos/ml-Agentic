# MCP Filesystem Server - Sandboxed file operations for privacy mode
# Provides read/write access to specific directories with path validation

FROM node:20-alpine

LABEL description="MCP Filesystem Server - Sandboxed file operations"
LABEL version="1.0.0"

# Install dependencies
RUN apk add --no-cache \
    git \
    python3 \
    py3-pip

# Create app directory
WORKDIR /app

# Install MCP filesystem server
RUN npm install -g @modelcontextprotocol/server-filesystem

# Create sandboxed directories
RUN mkdir -p /data/projects /data/shared /data/temp && \
    chmod 755 /data/projects /data/shared /data/temp

# Create non-root user
RUN addgroup -g 1000 mcp && \
    adduser -D -u 1000 -G mcp mcp && \
    chown -R mcp:mcp /data

# Switch to non-root user
USER mcp

# Expose MCP server port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

# Start MCP filesystem server with allowed paths
CMD ["npx", "@modelcontextprotocol/server-filesystem", \
     "--allowed-directory", "/data/projects", \
     "--allowed-directory", "/data/shared", \
     "--allowed-directory", "/data/temp", \
     "--port", "3001"]
