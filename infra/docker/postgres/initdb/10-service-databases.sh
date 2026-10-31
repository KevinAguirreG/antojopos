#!/usr/bin/env bash
# Runs once, when the postgres data volume is empty (docker-entrypoint-initdb.d).
# One database and one login role per service, and a role can only connect to its
# own database: "a service never reads another service's database" (CLAUDE.md rule 1),
# enforced by credentials rather than by discipline.
# To re-run it: docker compose down && docker volume rm antojopos_postgres-data
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
  -c 'REVOKE CONNECT ON DATABASE postgres FROM PUBLIC;'

for svc in identity catalog orders payments inventory reporting; do
  var="${svc^^}_DB_PASSWORD"
  pass="${!var:?$var is not set}"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
    -v svc="$svc" -v pass="$pass" <<'SQL'
CREATE ROLE :"svc" LOGIN PASSWORD :'pass';
CREATE DATABASE :"svc" OWNER :"svc";
REVOKE ALL ON DATABASE :"svc" FROM PUBLIC;
SQL
  echo "created database and role: $svc"
done
