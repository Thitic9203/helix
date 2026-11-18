#!/usr/bin/env bash
# Fail if committed skills/commands/references contain machine paths, host-specific tool
# names, or single-project coupling.
# Excludes docs that list forbidden patterns as examples.
# Uses grep (always present) rather than rg: a missing scanner must never read as "clean".

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DIRS=(skills commands references)
EXCLUDES=(
  --exclude=portable-content.md
  --exclude=gotchas.md
)

PATTERNS=(
  '/Users/'
  'C:\Users'
  '~/.helix'
  '~/.cursor'
  'pd3-web-portal'
  'pd3-api'
  'pw:login:pd3'
  'playwright.e2e.config'
  'learner-mhesi'
  'mycreditport.com'
  '.ols-qa-secrets'
  'mcp__Control_Chrome__'
)

FOUND=0
for pat in "${PATTERNS[@]}"; do
  # grep exits 0 = match, 1 = no match, 2 = error. An error is a failure, never "clean".
  set +e
  grep -rnF "${EXCLUDES[@]}" -e "$pat" -- "${DIRS[@]}"
  rc=$?
  set -e
  if [ "$rc" -eq 0 ]; then
    FOUND=1
  elif [ "$rc" -ne 1 ]; then
    echo "::error::grep failed (exit $rc) while scanning for '$pat'"
    exit 2
  fi
done

# --- Project tokens (Spec docs/sdd/project-agnostic R9) ---------------------------------
# Whole-word, case-sensitive product/project names (e.g. a product acronym) are stored only as
# SHA-256 hex in scripts/project-token-hashes.txt, so the public repo never spells them out.
# Each word [A-Za-z0-9_-]+ is checked as a whole and split on '-' / '_' (so a hyphenated
# repo name is caught). HELIX_EXTRA_PROJECT_TOKENS=/path adds plaintext tokens at run time.
# Add a token: printf '%s' TOKEN | shasum -a 256 >> scripts/project-token-hashes.txt (hex only).
TOKEN_HASHES="scripts/project-token-hashes.txt"
TOKEN_ALLOW=(            # exact repo paths exempt from the token scan (templates that must name a placeholder project)
)
if ! command -v perl >/dev/null 2>&1; then
  echo "::error::perl not found — project-token scan cannot run (failing closed)"
  exit 2
fi
set +e
find "${DIRS[@]}" -type f -name '*.md' | perl -e '
  use strict; use warnings; use Digest::SHA qw(sha256_hex);
  my ($hashfile, $extra, @skip) = @ARGV; @ARGV = ();
  my %deny; my %skip = map { $_ => 1 } @skip;
  if (-f $hashfile) { open(my $h, "<", $hashfile) or exit 2;
    while (my $x = <$h>) { $x =~ s/\s+$//; $deny{lc $x} = 1 if $x =~ /^[0-9a-fA-F]{64}$/ } close $h }
  if (length $extra) { open(my $e, "<", $extra) or exit 2;
    while (my $x = <$e>) { $x =~ s/\r?\n$//; next if $x =~ /^\s*(#|$)/; $deny{ sha256_hex($x) } = 1 } close $e }
  exit 0 unless %deny;
  my $found = 0;
  while (my $f = <STDIN>) { chomp $f; next if $skip{$f};
    my $base = $f; $base =~ s{.*/}{}; next if $base eq "portable-content.md" || $base eq "gotchas.md";
    open(my $in, "<", $f) or exit 2; my $ln = 0;
    while (my $line = <$in>) { $ln++;
      WORD: while ($line =~ /([A-Za-z0-9][A-Za-z0-9_-]*)/g) { my $w = $1;
        for my $t ($w, split /[-_]+/, $w) { next unless length $t;
          if ($deny{ sha256_hex($t) }) { print "$f:$ln: project-specific token (value redacted)\n"; $found = 1; last WORD } } } }
    close $in }
  exit($found ? 1 : 0);
' "$TOKEN_HASHES" "${HELIX_EXTRA_PROJECT_TOKENS:-}" ${TOKEN_ALLOW[@]+"${TOKEN_ALLOW[@]}"}
rc=$?
set -e
if [ "$rc" -eq 1 ]; then
  FOUND=1
elif [ "$rc" -ne 0 ]; then
  echo "::error::project-token scan failed (exit $rc)"
  exit 2
fi

if [ "$FOUND" -eq 1 ]; then
  echo "::error::Portable-content violation in skills/, commands/ or references/. See references/portable-content.md"
  exit 1
fi

echo "ok: no portable-content violations in skills/, commands/ and references/"
