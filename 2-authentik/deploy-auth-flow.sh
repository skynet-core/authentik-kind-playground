#!/usr/bin/env bash
set -e

DIR="$(dirname "$(realpath "$0")")"

AUTHENTIK_URL="${AUTHENTIK_URL:-https://sso.localhost}"
ADMIN_TOKEN="${ADMIN_TOKEN:-$(cat "$DIR/authentik-admin-token.secret")}"

BLUEPRINT_FILE="$DIR/auth-flow-blueprint.yaml"

echo "Applying auth flow blueprint to ${AUTHENTIK_URL}..."

# Read the blueprint and import via API
curl -s -f -X POST "${AUTHENTIK_URL}/api/v3/blueprints/imports/" \
  --header "Authorization: Bearer ${ADMIN_TOKEN}" \
  --header "Content-Type: application/json" \
  --data "{
    \"content\": $(cat "$BLUEPRINT_FILE" | python3 -c "import sys, json; print(json.dumps(sys.stdin.read()))")
  }" | python3 -m json.tool

echo ""
echo "Blueprint imported. You may need to run the blueprint from the Admin UI:"
echo "  Admin → Blueprints → find 'Default Auth Flow with SSO and Auto-Signup' → Run"
echo ""
echo "Before using SSO, update the consumer secrets in the Admin UI:"
echo "  - Google:  replace YOUR_GOOGLE_CLIENT_ID and set consumer secret"
echo "  - Apple:   replace YOUR_APPLE_CLIENT_ID and set consumer secret"
echo "  - Facebook: replace YOUR_FACEBOOK_APP_ID and set consumer secret"
