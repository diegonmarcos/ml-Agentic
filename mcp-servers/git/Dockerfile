# MCP Git Server - Read-only git operations for privacy mode
# Provides git log, search, and diff capabilities without write access

FROM node:20-alpine

LABEL description="MCP Git Server - Read-only git operations"
LABEL version="1.0.0"

# Install git and dependencies
RUN apk add --no-cache \
    git \
    openssh-client \
    python3

# Create app directory
WORKDIR /app

# Install MCP git server
RUN npm install -g @modelcontextprotocol/server-git

# Create repositories directory
RUN mkdir -p /data/repos && \
    chmod 755 /data/repos

# Create non-root user
RUN addgroup -g 1001 mcpgit && \
    adduser -D -u 1001 -G mcpgit mcpgit && \
    chown -R mcpgit:mcpgit /data

# Switch to non-root user
USER mcpgit

# Expose MCP server port
EXPOSE 3002

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3002/health || exit 1

# Start MCP git server (read-only mode)
CMD ["npx", "@modelcontextprotocol/server-git", \
     "--repository-path", "/data/repos", \
     "--read-only", \
     "--port", "3002"]
