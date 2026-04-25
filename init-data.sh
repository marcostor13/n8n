#!/bin/bash
# Crea el usuario no-root de n8n en PostgreSQL (se ejecuta solo en el primer arranque)
set -e
set -u

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE USER ${POSTGRES_NON_ROOT_USER} WITH PASSWORD '${POSTGRES_NON_ROOT_PASSWORD}';
  GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_NON_ROOT_USER};
  GRANT ALL ON SCHEMA public TO ${POSTGRES_NON_ROOT_USER};
EOSQL

echo "Usuario ${POSTGRES_NON_ROOT_USER} creado correctamente."
