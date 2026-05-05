#!/usr/bin/env bash
# Apply the Jambo modern login skin to the running Znuny container.
# Idempotent — strips any prior block before re-appending. Safe to re-run.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CSS_SRC="$ROOT/theme/login-modern.css"
CSS_TARGET_HOST="$ROOT/app-data/httpd/htdocs/skins/Agent/default/css/Core.Login.css"
APP_CONTAINER="${APP_CONTAINER:-Support_V7-App-portal}"

if [[ ! -f "$CSS_SRC" ]]; then
    echo "Source CSS not found: $CSS_SRC" >&2
    exit 1
fi
if [[ ! -f "$CSS_TARGET_HOST" ]]; then
    echo "Target CSS not found on host: $CSS_TARGET_HOST" >&2
    echo "Make sure the stack has been started at least once so app-data/ is hydrated." >&2
    exit 1
fi

echo "Stripping any prior modern-login block..."
docker run --rm \
    -v "$ROOT/app-data:/data" \
    -v "$ROOT/theme:/theme:ro" \
    alpine sh -c "
        sed -i '/>>> JAMBO MODERN LOGIN — START >>>/,/<<< JAMBO MODERN LOGIN — END <<</d' /data/httpd/htdocs/skins/Agent/default/css/Core.Login.css
        echo '' >> /data/httpd/htdocs/skins/Agent/default/css/Core.Login.css
        cat /theme/login-modern.css >> /data/httpd/htdocs/skins/Agent/default/css/Core.Login.css
    "

echo "Clearing Znuny CSS bundle cache..."
if docker ps --format '{{.Names}}' | grep -qx "$APP_CONTAINER"; then
    docker exec "$APP_CONTAINER" sh -c '
        rm -f /opt/app/var/httpd/htdocs/skins/Agent/default/css-cache/* 2>/dev/null || true
        rm -f /opt/app/var/httpd/htdocs/skins/Customer/default/css-cache/* 2>/dev/null || true
    '
else
    echo "Container $APP_CONTAINER not running — cache will be regenerated on next start." >&2
fi

echo "Done. Open http://localhost:8082/znuny/index.pl (hard-refresh: Ctrl+Shift+R)."
