#!/bin/bash
# Same /health endpoint the ALB target group checks.
set -euo pipefail
for i in $(seq 1 20); do
  if curl -fsS http://localhost:5000/health >/dev/null; then
    echo "legacy-web healthy"; exit 0
  fi
  sleep 5
done
echo "legacy-web failed health check"; exit 1
