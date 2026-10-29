#!/usr/bin/env bash
# Serve the desktop POCs on http://localhost and open a page (YouTube embeds refuse file:// pages)
# usage: ./serve.sh [page.html]   (default: index.html)

set -euo pipefail

PORT="${PORT:-8039}"
PAGE="${1:-index.html}"

cd "$(dirname "$0")"
echo "POCs on http://localhost:${PORT}/${PAGE} (Ctrl+C to stop)"
(sleep 1 && xdg-open "http://localhost:${PORT}/${PAGE}" >/dev/null 2>&1) &
exec python3 -m http.server "${PORT}" --bind 127.0.0.1
