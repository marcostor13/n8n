# Nota: este proyecto usa docker-compose.yml para producción (n8n + PostgreSQL).
# Este Dockerfile es solo para pruebas rápidas de un solo contenedor sin BD persistente.
FROM docker.n8n.io/n8nio/n8n:latest
EXPOSE 5678
