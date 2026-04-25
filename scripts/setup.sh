#!/usr/bin/env bash
# First-time pipeline setup: git init, GitHub remote, git hooks
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

log()  { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }

echo -e "${GREEN}=== Configurando pipeline Antigravity + Claude + Coolify ===${NC}"
echo ""

# ── 1. Cargar .env ────────────────────────────────────────────
if [ ! -f .env ]; then
  cp .env.example .env
  warn ".env creado desde .env.example — completa tus credenciales y re-ejecuta setup.sh"
  exit 0
fi
source .env

# ── 2. Inicializar git ────────────────────────────────────────
if [ ! -d .git ]; then
  git init
  git branch -M "${GITHUB_BRANCH:-main}"
  log "Git inicializado (rama: ${GITHUB_BRANCH:-main})"
else
  log "Git ya inicializado"
fi

# ── 3. Configurar remote de GitHub ───────────────────────────
if [ -z "${GITHUB_REPO:-}" ]; then
  fail "GITHUB_REPO no está configurado en .env"
fi

if git remote get-url origin &>/dev/null 2>&1; then
  git remote set-url origin "$GITHUB_REPO"
else
  git remote add origin "$GITHUB_REPO"
fi
log "Remote configurado: $GITHUB_REPO"

# ── 4. Instalar git hooks ─────────────────────────────────────
chmod +x scripts/hooks/pre-push
cp scripts/hooks/pre-push .git/hooks/pre-push
log "Git hook pre-push instalado"

# ── 5. Verificar dependencias ─────────────────────────────────
echo ""
echo "Verificando herramientas..."

command -v git   &>/dev/null && log "git encontrado"   || fail "git no instalado"
command -v curl  &>/dev/null && log "curl encontrado"  || warn "curl no encontrado — necesario para coolify-deploy.sh"
command -v claude &>/dev/null && log "claude encontrado (mensajes AI activados)" || warn "claude CLI no encontrado — se usarán mensajes con timestamp"

# ── 6. Test de conexión a Coolify ─────────────────────────────
echo ""
if [ -n "${COOLIFY_TOKEN:-}" ] && [ "${COOLIFY_TOKEN}" != "your-api-token-here" ]; then
  COOLIFY_HOST=$(echo "${COOLIFY_WEBHOOK}" | sed 's|/api/v1.*||')
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    --header "Authorization: Bearer ${COOLIFY_TOKEN}" \
    "${COOLIFY_HOST}/api/v1/version" 2>/dev/null || echo "000")

  if [ "$HTTP_CODE" = "200" ]; then
    log "Conexión a Coolify verificada (${COOLIFY_HOST})"
  else
    warn "No se pudo conectar a Coolify (HTTP ${HTTP_CODE}) — verifica COOLIFY_TOKEN y URL"
  fi
else
  warn "COOLIFY_TOKEN pendiente — configúralo en .env para habilitar deploys manuales"
fi

echo ""
echo -e "${GREEN}=== Setup completo ===${NC}"
echo ""
echo "Flujo de trabajo:"
echo "  1. Codificar con Antigravity + Claude Code"
echo "  2. make push msg='mi cambio'    → commit + push automático"
echo "  3. GitHub webhook → Coolify auto-despliega"
echo ""
echo "Comandos disponibles:"
echo "  make push [msg='...']   — commit + push (genera mensaje AI si no das uno)"
echo "  make deploy             — forzar deploy manual en Coolify"
echo "  make status             — git status + últimos commits"
