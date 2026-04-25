.PHONY: setup push deploy status preview

# Primera configuración del pipeline
setup:
	bash scripts/setup.sh

# Commit + push automático. Uso: make push  o  make push msg="mi cambio"
push:
	bash scripts/push.sh "$(msg)"

# Forzar deploy manual en Coolify sin hacer push
deploy:
	bash scripts/coolify-deploy.sh

# Deploy forzando rebuild completo
deploy-force:
	bash scripts/coolify-deploy.sh --force

# Estado del repo
status:
	@git status
	@echo ""
	@git log --oneline --graph -8
