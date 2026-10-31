#!/usr/bin/env bash
# Formats a single file based on its extension. Invoked by the PostToolUse hook.
# Fails silently: a missing formatter shouldn't break the session.
set -u
f="${1:-}"; [ -f "$f" ] || exit 0
case "$f" in
  *.go)              command -v gofmt >/dev/null && gofmt -w "$f" ;;
  *.php)             [ -x ./vendor/bin/pint ] && ./vendor/bin/pint "$f" ;;
  *.ts|*.tsx|*.vue|*.json|*.css)
                     command -v npx >/dev/null && npx --no-install prettier --write "$f" ;;
esac
exit 0
