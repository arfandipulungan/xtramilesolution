#!/bin/bash
# Runs as root on the instance. Dedicated non-root service user, hardened systemd unit.
set -euo pipefail
id legacyweb &>/dev/null || useradd --system --no-create-home --shell /usr/sbin/nologin legacyweb
chown -R legacyweb:legacyweb /opt/legacy-web/app

cat > /etc/systemd/system/legacy-web.service <<'UNIT'
[Unit]
Description=legacy-web (.NET 8)
After=network-online.target

[Service]
WorkingDirectory=/opt/legacy-web/app
ExecStart=/usr/bin/dotnet /opt/legacy-web/app/LegacyWeb.dll
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000
Environment=ASPNETCORE_ENVIRONMENT=Production
User=legacyweb
Restart=always
RestartSec=5
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable legacy-web
