#!/usr/bin/env bash
# check-no-secrets.sh — HARD guard: block any OLS/customer secret from entering the
# helix plugin. helix is GENERIC: ZERO real OLS data — only placeholders
# {ISSUE_KEY} / {JIRA_DOMAIN} / {PORTAL}. Portable to bash 3.2 (macOS default).
#
#   TIER 1 (SECRETS)  — OLS creds / test-env hosts / tokens. Forbidden EVERYWHERE.
#   TIER 2 (PORTABLE) — machine paths / own-install-path / other-customer coupling.
#                       Forbidden only inside skills/ + commands/.
#
# Usage: check-no-secrets.sh [FILE ...]   (no args = scan all tracked files)
# Exit 0 = clean, 1 = violation (BLOCK).

set -o pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 2

# newline-delimited pattern lists (regex, matched case-insensitively)
TIER1='<TEST_PASSWORD>
<STG_SUFFIX>
@ndlp\.go\.th
ndlp\.go\.th
ndlp68
school-core-api
school-ndlp68
dev-ols
<OTHER_CUSTOMER_HOST>
<OTHER_CUSTOMER_HOST>\.cloud
<TEST_ACCOUNT_8>\.<ACCT_FRAGMENT>
<TEST_ACCOUNT_5>\.<ACCT_FRAGMENT>
<TEST_ACCOUNT_2>
<TEST_ACCOUNT_3>
<TEST_ACCOUNT_1>
\.<ACCT_FRAGMENT>
\.<ACCT_FRAGMENT>
\.<ACCT_FRAGMENT>
<ORG>\.atlassian\.net
\.jira_token
\.discord_webhook
OLS_DISCORD_WEBHOOK
discord(app)?\.com/api/webhooks
\.gcp-oauth
6L[0-9A-Za-z_-]{38}
-----BEGIN [A-Z ]*PRIVATE KEY
xox[baprs]-[0-9A-Za-z-]{10,}
gh[pousr]_[A-Za-z0-9]{36,}
AKIA[0-9A-Z]{16}'

TIER2='/Users/
C:\\Users
~/\.helix
~/\.cursor
pd3-web-portal
pd3-api
learner-mhesi
mycreditport\.com'

self_excluded() {
  case "$1" in
    scripts/check-no-secrets.sh|scripts/ci-check-portable-skills.sh) return 0 ;;
    references/portable-content.md|*/gotchas.md) return 0 ;;
    *.png|*.jpg|*.jpeg|*.gif|*.pdf|*.mp4|*.zip|*.woff2) return 0 ;;
  esac
  return 1
}

# collect files (all tracked, or args) into two temp lists
ALL_LIST="$(mktemp)"; SKILL_LIST="$(mktemp)"
trap 'rm -f "$ALL_LIST" "$SKILL_LIST"' EXIT
if [ "$#" -gt 0 ]; then SRC_CMD() { for a in "$@"; do echo "$a"; done; }; SRC="$(SRC_CMD "$@")"
else SRC="$(git ls-files 2>/dev/null)"; fi
while IFS= read -r f; do
  [ -n "$f" ] || continue
  [ -f "$f" ] || continue
  self_excluded "$f" && continue
  printf '%s\n' "$f" >> "$ALL_LIST"
  case "$f" in skills/*|commands/*) printf '%s\n' "$f" >> "$SKILL_LIST" ;; esac
done <<EOF
$SRC
EOF

RG=""; command -v rg >/dev/null 2>&1 && RG="yes"

scan_tier() {   # $1 = label, $2 = patterns(newline), $3 = file-list path
  local label="$1" patterns="$2" listfile="$3" found=0 pat hits
  [ -s "$listfile" ] || return 0
  while IFS= read -r pat; do
    [ -n "$pat" ] || continue
    if [ -n "$RG" ]; then
      hits="$(rg -n --pcre2 -i -e "$pat" $(cat "$listfile") 2>/dev/null || true)"
    else
      hits="$(grep -nEi -e "$pat" $(cat "$listfile") 2>/dev/null || true)"
    fi
    if [ -n "$hits" ]; then
      echo "❌ [$label] forbidden /$pat/:"
      printf '%s\n' "$hits" | sed 's/^/    /'
      found=1
    fi
  done <<EOF
$patterns
EOF
  return $found
}

RC=0
scan_tier "TIER1 secret"   "$TIER1" "$ALL_LIST"   || RC=1
scan_tier "TIER2 portable" "$TIER2" "$SKILL_LIST" || RC=1

if [ "$RC" -eq 1 ]; then
  echo ""
  echo "::error:: OLS/customer secret or non-portable content detected in helix."
  echo "helix is GENERIC — strip real OLS accounts/passwords/URLs/tokens; use {ISSUE_KEY}/{JIRA_DOMAIN}/{PORTAL}."
  exit 1
fi
echo "✅ check-no-secrets: clean ($(wc -l < "$ALL_LIST" | tr -d ' ') files scanned)"
exit 0
