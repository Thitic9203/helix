#!/usr/bin/env bash
# check-no-secrets.sh — HARD guard: block any OLS/customer secret from entering the
# helix plugin. helix is GENERIC and PUBLIC: it carries ZERO real OLS data — only
# placeholders {ISSUE_KEY} / {JIRA_DOMAIN} / {PORTAL}. Portable to bash 3.2 (macOS).
#
# Detection runs THREE independent mechanisms (defense in diversity — a gap in one
# does not open a gap in the others):
#
#   TIER 1 (SHAPE regex)  — generic secret/URL SHAPES that name no customer:
#                           *.go.th / google resource URLs / Bearer tokens / private keys
#                           / provider tokens. Forbidden EVERYWHERE.
#   TIER 2 (PORTABLE)     — machine paths / own-install path / other-customer coupling.
#                           Forbidden only inside skills/ + commands/.
#   HASH tier (TOKEN sha256) — exact OLS identifiers (test password, usernames, resource
#                           IDs, infra hostnames) are stored ONLY as SHA-256 of the
#                           lowercased token — the cleartext literal never appears in this
#                           public repo, yet an exact appearance is still detected.
#                           Forbidden EVERYWHERE. Regenerate from the LOCAL, off-repo list
#                           ~/.helix-ols-denylist via scripts/gen-secret-hashes.sh.
#
# Optional: HELIX_EXTRA_DENYLIST=/path/to/plaintext (one literal per line) adds more
# hashed tokens at runtime without editing this committed file.
#
# Usage: check-no-secrets.sh [FILE ...]   (no args = scan all tracked files)
# Exit 0 = clean, 1 = violation (BLOCK), 2 = scanner error (BLOCK, fail-closed).

set -o pipefail
# SCAN_ROOT lets a hook point the scan at a materialized STAGED-blob tree (paths mirrored)
# instead of the working tree, so pre-commit checks exactly what is being committed.
ROOT="${SCAN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$ROOT" || exit 2

# --- TIER 1: generic SHAPE regex (no customer-identifying cleartext) ---
# ERE, matched case-insensitively. No single-quote/backtick chars (kept single-quote-safe).
TIER1='[a-z0-9][a-z0-9.-]*\.go\.th
(docs|drive|sheets)\.google\.com/[a-z]+/(d|folders)/[A-Za-z0-9_-]{20,}
Bearer [A-Za-z0-9._-]{20,}
discord(app)?\.com/api/webhooks
\.jira_token
\.discord_webhook
\.gcp-oauth
6L[0-9A-Za-z_-]{38}
-----BEGIN [A-Z ]*PRIVATE KEY
xox[baprs]-[0-9A-Za-z-]{10,}
gh[pousr]_[A-Za-z0-9]{36,}
AKIA[0-9A-Z]{16}'

# --- TIER 2: portable-content / other-customer coupling (skills + commands only) ---
TIER2='/Users/
C:\\Users
~/\.helix
~/\.cursor
pd3-web-portal
pd3-api
learner-mhesi
mycreditport\.com'

# --- HASH tier: sha256 of lowercased OLS identifier tokens (cleartext NEVER in repo) ---
# Regenerate with scripts/gen-secret-hashes.sh from ~/.helix-ols-denylist.
HASH_ALL='a075d17f3d453073853f813838c15b8023b8c487038436354fe599c3942e1f95
dbaac1d60c653da918251acd510ba4b293ee086b6a2e96f00f33afcc41ce5380
f4e6fe4ee11d5c1e173e113cb1fa20c6fb37fc7c5da03b542db52a508e6b67ae
2c805a222173a1dd75e5df47a77849048e7208d2b475bad875e6281a616d9b3a
5ee334b02ac71ceb94b7341511c6d42fa01482d837130a3c16e40bf8d71abf6d
31ad94821ba5c6e4fb68195b539cb1677cd4270b5d4e7ebe09ddf60f5b4ccd5b
f4102fdcb89826c5f32b3ada137332231e209844c8cb60a58508829ae5a202fe
dd119752301ddf869ce8ec5ba98b06857cfd1f1e84cc3fdbfecb47ebf5875269
ee0ebe2700950a3978fae0850842e2bf0e4f6980635e1c259f9e82f2441c1d31
6f9b6a7615dd5d62fb261adb34ca0ceafdfa5c078871d77d1ca36e548b5148a3
b92a4bb1b6e104c2ede742e064cb6ef33a495edd2d67446b764bce9fb8e97cc5
55743ae1b1a087b5852d3aaf0ef37923441bc43aaf0d34a6593f6b9b0bcde291
81b2c4a2026bc50e96ce263cc22e6c7558c74b8d73a2569bdcab92370f0143eb
bd61a527b723d654d9292143304cc06599359a5af93dee1aece255fa406ff85e
b976b3daf1cf8d166884943493ac3711a35d8d9250a83a78c16dd8bb5e350d12
254a3cc1029ec4d755a9ff3e16e8229764d5327065f719a96f3a45b820a8993a
0d17bc9c15c9d36b948b7983b47042d32128fb7e91a9bec6bd18dc2333985a7d
ef616f6ff602a4a6a69686c3506313cd1ca69fcf8f3e47f636a8e91239965009
a6b2a5d91b97c52cdbf8fd27221de1df54b5d5f3612171feed323be84010bf8e
7a119b31af7e5b71199bfae66b818ddce793e80ceb89ff112a8c8831e9bbec0f
9b6038a35fa9ed7071af3b29ff0d8ab742ab830e9b972afdd3aab527f095d291
acbe836ac1eda7cb7dd9161cfabb8d32e763372226c672c86a85a9ab83a78eb7
0da91e5cc0f32ce14c9ffa5f795ae8ea8a807c573ff0d150b86348e8a3cfca82
4f5f282a62bcba78713d38b01b90ef2ae3ab3c7bbb75a14c1433aca83b2827a9'

self_excluded() {   # skipped by ALL tiers (binaries + files that legitimately quote the patterns)
  case "$1" in
    scripts/check-no-secrets.sh|scripts/gen-secret-hashes.sh|scripts/ci-check-portable-skills.sh) return 0 ;;
    references/portable-content.md) return 0 ;;
    *.png|*.jpg|*.jpeg|*.gif|*.pdf|*.mp4|*.zip|*.woff2|*.ico|*.webp) return 0 ;;
  esac
  return 1
}

tier2_excluded() {  # exempt from TIER2 (portable) ONLY — still fully scanned by shape + hash.
  # gotchas.md TEACHES the portable-path rule, so it must quote /Users/ and C:\Users\
  # as examples. Real OLS secrets there are still caught by TIER1 shapes + the hash tier.
  case "$1" in
    */gotchas.md) return 0 ;;
  esac
  return 1
}

# --- collect files (all tracked, or args) into bash arrays (no word-splitting) ---
ALL_FILES=(); SKILL_FILES=()
if [ "$#" -gt 0 ]; then SRC="$(for a in "$@"; do printf '%s\n' "$a"; done)"
else SRC="$(git ls-files 2>/dev/null)"; fi
while IFS= read -r f; do
  [ -n "$f" ] || continue
  [ -f "$f" ] || continue
  self_excluded "$f" && continue
  ALL_FILES+=("$f")
  case "$f" in
    skills/*|commands/*) tier2_excluded "$f" || SKILL_FILES+=("$f") ;;
  esac
done <<EOF
$SRC
EOF

RC=0

# --- regex scan: rc 0=match(bad) 1=clean ≥2=grep ERROR(fail-closed) ---
scan_tier() {   # $1=label  $2=patterns(newline)  $3..=files
  local label="$1" patterns="$2"; shift 2
  [ "$#" -gt 0 ] || return 0
  local found=0 pat hits rc
  while IFS= read -r pat; do
    [ -n "$pat" ] || continue
    hits="$(grep -nEi -e "$pat" -- "$@" 2>/dev/null)"; rc=$?
    if [ "$rc" -ge 2 ]; then
      echo "❌ [$label] grep ERROR on /$pat/ (rc=$rc) — failing closed"
      found=2
    elif [ -n "$hits" ]; then
      echo "❌ [$label] forbidden /$pat/:"
      printf '%s\n' "$hits" | sed 's/^/    /'
      [ "$found" -lt 1 ] && found=1
    fi
  done <<EOF2
$patterns
EOF2
  return $found
}

# --- HASH scan: tokenize → lowercase → sha256 → membership. One perl pass (fast). ---
hash_scan() {   # $1..=files ; uses HASH_ALL + optional HELIX_EXTRA_DENYLIST
  [ "$#" -gt 0 ] || return 0
  local hashfile listfile extra="${HELIX_EXTRA_DENYLIST:-}" rc
  hashfile="$(mktemp)"; listfile="$(mktemp)"
  printf '%s\n' "$HASH_ALL" > "$hashfile"
  local f; for f in "$@"; do printf '%s\n' "$f" >> "$listfile"; done

  if command -v perl >/dev/null 2>&1; then
    perl - "$hashfile" "$listfile" "$extra" <<'PL'
use strict; use warnings;
use Digest::SHA qw(sha256_hex);
my ($hashfile, $listfile, $extra) = @ARGV;
my %deny;
open(my $h, '<', $hashfile) or die "hashfile: $!";
while (my $x = <$h>) { $x =~ s/^\s+|\s+$//g; $deny{$x} = 1 if $x =~ /^[0-9a-f]{64}$/; }
close $h;
if (defined $extra && length $extra && -f $extra) {
  open(my $e, '<', $extra) or die "extra: $!";
  while (my $x = <$e>) { $x =~ s/\r?\n$//; next if $x =~ /^\s*(#|$)/; $deny{ sha256_hex(lc $x) } = 1; }
  close $e;
}
my $found = 0;
open(my $l, '<', $listfile) or die "listfile: $!";
while (my $file = <$l>) {
  chomp $file; next unless length $file; next unless -f $file;
  open(my $in, '<', $file) or next;
  my $ln = 0;
  while (my $line = <$in>) {
    $ln++;
    while ($line =~ /([A-Za-z0-9._\@-]{6,})/g) {
      if ($deny{ sha256_hex(lc $1) }) {
        print "!! [HASH secret] $file:$ln matches a known OLS-identifier hash (value redacted)\n";
        $found = 1;
        last;
      }
    }
  }
  close $in;
}
exit($found ? 1 : 0);
PL
    rc=$?
  else
    # Fallback (no perl): dedupe tokens, hash each via shasum. Loses file:line, still fail-closed.
    rc=0
    local toks t hh
    toks="$(grep -ohE '[A-Za-z0-9._@-]{6,}' -- "$@" 2>/dev/null | tr 'A-Z' 'a-z' | sort -u)"
    if [ -n "$extra" ] && [ -f "$extra" ]; then
      toks="$toks
$(grep -vE '^\s*(#|$)' "$extra" | tr 'A-Z' 'a-z')"
    fi
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      hh="$(printf '%s' "$t" | shasum -a 256 | awk '{print $1}')"
      if grep -qxF "$hh" "$hashfile"; then
        echo "!! [HASH secret] a token matching a known OLS-identifier hash is present (value redacted)"
        rc=1
      fi
    done <<EOF3
$toks
EOF3
  fi
  rm -f "$hashfile" "$listfile"
  return $rc
}

scan_tier "TIER1 shape"    "$TIER1" "${ALL_FILES[@]}"   ; t1=$?; [ "$t1" -gt "$RC" ] && RC=$t1
scan_tier "TIER2 portable" "$TIER2" "${SKILL_FILES[@]}" ; t2=$?; [ "$t2" -gt "$RC" ] && RC=$t2
hash_scan "${ALL_FILES[@]}" || RC=1

if [ "$RC" -ge 2 ]; then
  echo ""
  echo "::error:: secret scanner ERROR — failing closed (treated as a violation)."
  exit 2
fi
if [ "$RC" -eq 1 ]; then
  echo ""
  echo "::error:: OLS/customer secret or non-portable content detected in helix."
  echo "helix is GENERIC — strip real OLS accounts/passwords/URLs/tokens; use {ISSUE_KEY}/{JIRA_DOMAIN}/{PORTAL}."
  exit 1
fi
echo "✅ check-no-secrets: clean (${#ALL_FILES[@]} files scanned)"
exit 0
