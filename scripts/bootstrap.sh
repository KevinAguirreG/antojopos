#!/usr/bin/env bash
# Creates the monorepo skeleton. Idempotent: safe to run more than once.
set -euo pipefail

for d in \
  services/{identity,catalog,orders,payments,inventory,reporting,kds-notifications,gateway} \
  services/_shared/{go,php,ts} \
  apps/{pos-web,kds-web} \
  contracts/{openapi,asyncapi,events} \
  infra/{docker,k8s,terraform} \
  infra/tools \
  docs/adr \
  .claude/{rules,skills} \
  scripts
do
  mkdir -p "$d"
  [ -z "$(ls -A "$d")" ] && touch "$d/.gitkeep"
done

[ -f .env.example ] || cat > .env.example <<'ENV'
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_PASSWORD=changeme
RABBITMQ_HOST=rabbitmq
RABBITMQ_USER=antojopos
RABBITMQ_PASSWORD=changeme
REDIS_HOST=redis
JWT_JWKS_URL=http://identity:8001/.well-known/jwks.json
OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:4318
ENV

echo "Skeleton ready. Next: git init && git add -A && git commit -m 'chore: skeleton and docs'"
