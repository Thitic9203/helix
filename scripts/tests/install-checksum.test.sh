#!/usr/bin/env bash
# The documented install block (README "Install (one-time)") run against a local fake release.
# Spec: docs/sdd/install-pinned-checksum R3 R4 R9 R10
# Everything lives in a throwaway sandbox: a sandbox HOME, a fake release directory served via
# file://, and a PATH that holds only the tools the block needs. Nothing touches the real HOME.
. "$(dirname "$0")/lib.sh"
S="$(mktemp -d)"; trap 'rm -rf "$S"' EXIT

# --- the block, exactly as README prints it ---------------------------------------------------
BLOCK_SRC="$(awk '/^HELIX_TAG=v[0-9]/{p=1} p{ if ($0 == "```") exit; print }' "$REPO_ROOT/README.md")"
TAG="$(printf '%s\n' "$BLOCK_SRC" | head -1 | sed 's/^HELIX_TAG=//')"
if [ -z "$BLOCK_SRC" ]; then
  fail "README has a pinned install block (a line starting HELIX_TAG=v... inside a bash fence)"
  finish; exit $?
fi
ok "README has a pinned install block for $TAG"
# point only the host at the fake release; the path and file names stay README's
BLOCK="$(printf '%s\n' "$BLOCK_SRC" | sed "s#https://github.com/[^\"/]*/[^\"/]*/releases/download#file://$S/rel#")"
case "$BLOCK" in *"file://$S/rel/"*) ok "block's base URL swapped to the fake release";; *) fail "block's base URL swapped to the fake release";; esac

# --- PATH shims: the block must work with either hash tool ------------------------------------
REAL_CURL="$(command -v curl)"; REAL_BASH="$(command -v bash)"; REAL_WC="$(command -v wc)"
REAL_SHASUM="$(command -v shasum || true)"; REAL_SHA256SUM="$(command -v sha256sum || true)"; REAL_PERL="$(command -v perl || true)"
REAL_TR="$(command -v tr)"
mkshim() { # mkshim <variant> -> prints a dir holding only curl, bash, wc and one hash tool
  local v="$1" d="$S/shim-$1"; [ -d "$d" ] && { echo "$d"; return; }; mkdir -p "$d"
  ln -s "$REAL_CURL" "$d/curl"; ln -s "$REAL_BASH" "$d/bash"; ln -s "$REAL_WC" "$d/wc"
  if [ "$v" = lenient ]; then
    # Mimics GNU sha256sum on Linux, which accepts a CRLF checklist: strips CR, then checks. The block
    # must refuse a CRLF .sha256 itself and not depend on how strict the hash tool is.
    local chk; if [ -n "$REAL_SHASUM" ]; then chk="$REAL_SHASUM -a 256 -c"; else chk="$REAL_SHA256SUM -c"; fi
    printf '#!%s\nf="${@: -1}"\n%s -d "\\r" < "$f" | %s\n' "$REAL_BASH" "$REAL_TR" "$chk" > "$d/sha256sum"; chmod +x "$d/sha256sum"
  elif [ "$v" = sha256sum ]; then
    if [ -n "$REAL_SHA256SUM" ]; then ln -s "$REAL_SHA256SUM" "$d/sha256sum"
    else printf '#!%s\nexec %s -a 256 "$@"\n' "$REAL_BASH" "$REAL_SHASUM" > "$d/sha256sum"; chmod +x "$d/sha256sum"; fi
  else
    if [ -n "$REAL_SHASUM" ]; then ln -s "$REAL_SHASUM" "$d/shasum"; [ -z "$REAL_PERL" ] || ln -s "$REAL_PERL" "$d/perl"
    else printf '#!%s\nshift 2\nexec %s "$@"\n' "$REAL_BASH" "$REAL_SHA256SUM" > "$d/shasum"; chmod +x "$d/shasum"; fi
  fi
  echo "$d"
}

HASHFILE=install.sh.sha256
mkrel() { # mkrel <case> -> fresh fake release dir holding install.sh + a correct hash file
  local r="$S/rel/$TAG"; rm -rf "$S/rel"; mkdir -p "$r"
  printf '#!/bin/bash\necho installed-%s > "$HOME/ran"\n' "$1" > "$r/install.sh"
  local h; h="$(shasum -a 256 "$r/install.sh" 2>/dev/null || sha256sum "$r/install.sh")"
  printf '%s  install.sh\n' "${h%% *}" > "$r/$HASHFILE"
  echo "$r"
}

run_block() { # run_block <variant> -> exit code of the block; sandbox HOME is empty before
  local v="$1" shim; shim="$(mkshim "$v")"
  rm -rf "$S/home" "$S/work"; mkdir -p "$S/home" "$S/work"
  ( cd "$S/work" && HOME="$S/home" PATH="$shim" "$REAL_BASH" -c "$BLOCK" ) >"$S/out" 2>&1
}
home_empty() { [ -z "$(ls -A "$S/home")" ]; }

for v in sha256sum shasum lenient; do
  [ -n "$REAL_SHASUM$REAL_SHA256SUM" ] || { fail "no hash tool on this machine"; break; }
  echo "  -- hash tool on PATH: $v"
  r="$(mkrel clean)"; run_block "$v"; rc=$?
  { [ "$rc" -eq 0 ] && [ -f "$S/home/ran" ]; } && ok "[$v] untouched release: check passes and install.sh runs" || fail "[$v] untouched release (rc=$rc)"

  r="$(mkrel tampered)"; printf '# added\n' >> "$r/install.sh"; run_block "$v"; rc=$?
  { [ "$rc" -ne 0 ] && home_empty; } && ok "[$v] tampered install.sh: rc=$rc, HOME still empty" || fail "[$v] tampered install.sh (rc=$rc, HOME empty? $(home_empty && echo y || echo n))"

  r="$(mkrel nohash)"; rm "$r/$HASHFILE"; run_block "$v"; rc=$?
  { [ "$rc" -ne 0 ] && home_empty; } && ok "[$v] missing .sha256: rc=$rc, HOME still empty" || fail "[$v] missing .sha256 (rc=$rc)"

  r="$(mkrel noinstall)"; rm "$r/install.sh"; run_block "$v"; rc=$?
  { [ "$rc" -ne 0 ] && home_empty; } && ok "[$v] missing install.sh: rc=$rc, HOME still empty" || fail "[$v] missing install.sh (rc=$rc)"

  # a real CR (printf, not sed: BSD sed writes a literal 'r' for \r in a replacement)
  r="$(mkrel crlf)"; h="$(cut -d' ' -f1 "$r/$HASHFILE")"; printf '%s  install.sh\r\n' "$h" > "$r/$HASHFILE"; run_block "$v"; rc=$?
  { [ "$rc" -ne 0 ] && home_empty; } && ok "[$v] CRLF .sha256: rc=$rc, HOME still empty" || fail "[$v] CRLF .sha256 (rc=$rc)"

  r="$(mkrel wrongname)"; sed 's/  install.sh$/  other.sh/' "$r/$HASHFILE" > "$r/h" && mv "$r/h" "$r/$HASHFILE"; run_block "$v"; rc=$?
  { [ "$rc" -ne 0 ] && home_empty; } && ok "[$v] .sha256 naming another file: rc=$rc, HOME still empty" || fail "[$v] wrong name in .sha256 (rc=$rc)"

  r="$(mkrel extra)"; echo "not a hash line" >> "$r/$HASHFILE"; run_block "$v"; rc=$?
  { [ "$rc" -ne 0 ] && home_empty; } && ok "[$v] .sha256 with an extra line: rc=$rc, HOME still empty" || fail "[$v] extra line in .sha256 (rc=$rc)"

  r="$(mkrel emptyhash)"; : > "$r/$HASHFILE"; run_block "$v"; rc=$?
  { [ "$rc" -ne 0 ] && home_empty; } && ok "[$v] empty .sha256: rc=$rc, HOME still empty" || fail "[$v] empty .sha256 (rc=$rc)"
done
finish
