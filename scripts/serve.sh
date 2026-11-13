#!/usr/bin/env bash
# Usage: scripts/serve.sh www|deal|comply|respond   then open http://localhost:8080
set -euo pipefail
site="sites/$1"
rm -rf "$site/shared" && cp -r shared "$site/shared"
py=python3; "$py" --version >/dev/null 2>&1 || py=python   # Windows ships "python", plus a python3 stub
cd "$site" && "$py" -m http.server 8080
