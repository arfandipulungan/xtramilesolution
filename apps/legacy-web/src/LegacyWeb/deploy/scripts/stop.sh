#!/bin/bash
set -euo pipefail
systemctl stop legacy-web 2>/dev/null || true
