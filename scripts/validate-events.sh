#!/usr/bin/env bash
# Validates every event schema against its example. Fails (exit 1) if any mismatch.
# Usage: ./scripts/validate-events.sh
set -uo pipefail
cd "$(dirname "$0")/../contracts/events"

fail=0
for f in *.v*.json; do
  name="${f%.json}"
  ex="examples/${name}.example.json"
  if [ ! -f "$ex" ]; then
    echo "❌ $name — missing example ($ex)"
    fail=1
    continue
  fi
  if npx --yes -p ajv-cli -p ajv-formats ajv validate -c ajv-formats --spec=draft2020 -s "$f" -r "_envelope.schema.json" -d "$ex" >/tmp/ajv-out 2>&1; then
    echo "✅ $name"
  else
    echo "❌ $name"
    tail -8 /tmp/ajv-out
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "--- every event validates against its example ---"
else
  echo "--- some events failed validation, see above ---"
fi
exit $fail
