#!/usr/bin/env bash
# Dispara un deploy manual en Coolify via API v1
# Uso: ./scripts/coolify-deploy.sh [--force]
set -euo pipefail

[ -f .env ] && source .env

: "${COOLIFY_WEBHOOK:?COOLIFY_WEBHOOK no configurado en .env}"
: "${COOLIFY_TOKEN:?COOLIFY_TOKEN no configurado en .env}"

FORCE="false"
[ "${1:-}" = "--force" ] && FORCE="true"

# Separar base URL de los query params para agregar force
BASE_URL=$(echo "$COOLIFY_WEBHOOK" | sed 's/\?.*//')
UUID_PARAM=$(echo "$COOLIFY_WEBHOOK" | grep -o 'uuid=[^&]*' || echo "")

echo "Disparando deploy en Coolify..."
echo "  Endpoint: $BASE_URL"
echo "  Force rebuild: $FORCE"
echo ""

RESPONSE=$(curl --silent --fail \
  --request GET \
  "${BASE_URL}?${UUID_PARAM}&force=${FORCE}" \
  --header "Authorization: Bearer ${COOLIFY_TOKEN}" \
  --header "Accept: application/json" \
  -w "\nHTTP_STATUS:%{http_code}")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_STATUS:")

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ]; then
  echo "✓ Deploy disparado exitosamente (HTTP $HTTP_STATUS)"
  echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"
else
  echo "✗ Error al disparar deploy (HTTP $HTTP_STATUS)"
  echo "$BODY"
  exit 1
fi
