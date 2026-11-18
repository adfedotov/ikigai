FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl ca-certificates ripgrep jq procps build-essential python3 \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code

# Wrapper earlier in PATH than the npm-installed /usr/local/bin/claude: hands the
# subscription token to Claude per invocation, without putting it in the container env.
RUN printf '%s\n' '#!/bin/sh' \
      'export CLAUDE_CODE_OAUTH_TOKEN="$(cat /run/secrets/claude_token)"' \
      'exec /usr/local/bin/claude "$@"' > /usr/local/sbin/claude \
    && chmod 755 /usr/local/sbin/claude

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh \
    && mkdir -p /workspace /home/node/.claude \
    && chown node:node /workspace /home/node/.claude

USER node
WORKDIR /workspace
ENTRYPOINT ["entrypoint.sh"]
CMD ["sleep", "infinity"]

