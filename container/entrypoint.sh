#!/usr/bin/env bash
# Runs on every container start; safe to repeat.
set -euo pipefail
BASE="${BASE_BRANCH:-main}"

# depends_on only waits for the proxy container to start, not for squid to listen.
for _ in $(seq 30); do
  (exec 3<>/dev/tcp/proxy/3128) 2>/dev/null && break
  sleep 1
done

git config --global user.name  "${GIT_USER_NAME:-agent}"
git config --global user.email "${GIT_USER_EMAIL:-agent@localhost}"
git config --global push.autoSetupRemote true  # first `git push` creates origin/<branch>
# GitHub token is read from the secret file on demand; only offered to github.com.
git config --global credential.https://github.com.helper \
  '!f() { echo username=x-access-token; echo "password=$(cat /run/secrets/gh_token)"; }; f'

# Claude auth: the claude wrapper (/usr/local/sbin/claude) reads the subscription
# token from /run/secrets/claude_token. Drop any old apiKeyHelper so it can't win.
s=/home/node/.claude/settings.json
mkdir -p /home/node/.claude
[ -f "$s" ] || echo '{}' > "$s"
jq 'del(.apiKeyHelper)' "$s" > "$s.tmp" && mv "$s.tmp" "$s"

[ -d /workspace/repo/.git ] || git clone "$REPO_URL" /workspace/repo
cd /workspace/repo

grep -qxF ".env" .git/info/exclude 2>/dev/null || echo ".env" >> .git/info/exclude

git fetch origin --quiet
if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH" "origin/$BRANCH"
else
  git checkout "$BRANCH" 2>/dev/null || git checkout --no-track -b "$BRANCH" "origin/$BASE"
fi

# Project's .env.agent becomes the app's .env inside the box.
[ -s /run/app.env ] && cp /run/app.env .env || true

exec "$@"
