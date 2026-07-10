#!/usr/bin/env bash
# Infra deploy: arrenca/actualitza Caddy i (re)crea la xarxa "web".
# Les APPS es despleguen des dels seus propis repos (veure README).
#
# Ús:  ./deploy.sh          -> up -d de la infra
#      ./deploy.sh reload    -> recarrega el Caddyfile sense downtime
set -euo pipefail

cd "$(dirname "$0")"

case "${1:-up}" in
	reload)
		# Recarrega la config de Caddy en calent (sense tallar connexions)
		docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile
		;;
	up)
		docker compose pull
		docker compose up -d
		;;
	*)
		echo "ús: $0 [up|reload]" >&2
		exit 1
		;;
esac
