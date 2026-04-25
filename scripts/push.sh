#!/usr/bin/env bash
# YOLO push: stage todo → commit (mensaje AI o timestamp) → push a GitHub
# Uso: ./scripts/push.sh ["mensaje opcional"] [rama]
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

[ -f .env ] && source .env

BRANCH="${GITHUB_BRANCH:-main}"
MSG="${1:-}"

# ── Verificar que hay cambios ─────────────────────────────────
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo -e "${YELLOW}Sin cambios para commitear.${NC}"
  exit 0
fi

git add -A

# ── Generar mensaje de commit ─────────────────────────────────
if [ -z "$MSG" ]; then
  if command -v claude &>/dev/null; then
    echo "Generando mensaje de commit con Claude..."
    DIFF_SUMMARY=$(git diff --cached --stat 2>/dev/null)
    MSG=$(printf '%s\n\nEscribe un mensaje de commit git conciso (máx 72 caracteres). Solo el mensaje, sin comillas ni explicaciones.' "$DIFF_SUMMARY" \
      | claude -p 2>/dev/null \
      | head -1 \
      | tr -d '"' \
      || echo "")
  fi

  # Fallback si Claude no está disponible o falla
  if [ -z "$MSG" ]; then
    MSG="chore: update $(date '+%Y-%m-%d %H:%M')"
  fi
fi

# ── Commit y push ─────────────────────────────────────────────
git commit -m "$MSG"
git push origin "$BRANCH"

echo ""
echo -e "${GREEN}✓ Push completado → '$MSG'${NC}"
echo -e "${GREEN}✓ Coolify detectará el push y desplegará automáticamente.${NC}"
