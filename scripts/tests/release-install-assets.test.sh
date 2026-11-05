#!/usr/bin/env bash
# scripts/release-install-assets.sh builds the two release assets (install.sh + install.sh.sha256)
# and the release step of version.yml attaches them.
# Spec: docs/sdd/install-pinned-checksum R1 R2 R9
. "$(dirname "$0")/lib.sh"
S="$(mktemp -d)"; trap 'rm -rf "$S"' EXIT
cd "$REPO_ROOT"
SCRIPT=scripts/release-install-assets.sh
[ -f "$SCRIPT" ] && ok "$SCRIPT exists" || { fail "$SCRIPT exists"; finish; exit $?; }

BASH_BIN="$(command -v bash)"
tool_dir() { # tool_dir <name> <tool>... -> PATH dir holding only coreutils the script needs plus the named hash tool
  local d="$S/path-$1"; shift; mkdir -p "$d"
  local t; for t in cut cp cat cmp mkdir rm head tr sed awk grep wc dirname basename mktemp uname date "$@"; do
    p="$(command -v "$t" 2>/dev/null || true)"; [ -n "$p" ] && [ ! -e "$d/$t" ] && ln -s "$p" "$d/$t"
  done
  p="$(command -v perl 2>/dev/null || true)"; [ -n "$p" ] && [ ! -e "$d/perl" ] && ln -s "$p" "$d/perl"
  echo "$d"
}

out="$S/out"
bash "$SCRIPT" "$out" >"$S/log" 2>&1; rc=$?
[ "$rc" -eq 0 ] && ok "builds the assets (rc=0)" || fail "builds the assets (rc=$rc: $(tail -1 "$S/log"))"
cmp -s scripts/install.sh "$out/install.sh" && ok "install.sh asset is byte-identical to scripts/install.sh" || fail "install.sh asset differs from scripts/install.sh"
[ "$(wc -l < "$out/install.sh.sha256" | tr -d ' ')" = 1 ] && ok "install.sh.sha256 has exactly one line" || fail "install.sh.sha256 line count"
grep -Eq '^[0-9a-f]{64}  install\.sh$' "$out/install.sh.sha256" && ok "line format is '<64 hex>  install.sh'" || fail "line format: $(cat "$out/install.sh.sha256" 2>/dev/null)"
if ! LC_ALL=C grep -q $'\r' "$out/install.sh.sha256"; then ok "no CR in install.sh.sha256"; else fail "CR in install.sh.sha256"; fi
want="$(shasum -a 256 scripts/install.sh 2>/dev/null | cut -d' ' -f1 || true)"
[ -n "$want" ] || want="$(sha256sum scripts/install.sh | cut -d' ' -f1)"
[ "$(cut -d' ' -f1 "$out/install.sh.sha256")" = "$want" ] && ok "hash equals an independent SHA-256 of scripts/install.sh" || fail "hash differs from independent SHA-256"

for tool in shasum sha256sum; do
  command -v "$tool" >/dev/null 2>&1 || { echo "  -- $tool not installed here; skipped (only the other one is exercised)"; continue; }
  if [ "$tool" = shasum ]; then (cd "$out" && shasum -a 256 -c install.sh.sha256 >/dev/null 2>&1); else (cd "$out" && sha256sum -c install.sh.sha256 >/dev/null 2>&1); fi
  [ $? -eq 0 ] && ok "$tool -c passes on the asset pair" || fail "$tool -c passes on the asset pair"
done
cp -R "$out" "$S/flip"; printf '#' >> "$S/flip/install.sh"
if (cd "$S/flip" && { command -v sha256sum >/dev/null && sha256sum -c install.sh.sha256 || shasum -a 256 -c install.sh.sha256; }) >/dev/null 2>&1
then fail "flipping one byte of install.sh must fail the check"; else ok "flipping one byte of install.sh fails the check"; fi

# each hash tool alone (R9)
for tool in shasum sha256sum; do
  command -v "$tool" >/dev/null 2>&1 || continue
  rm -rf "$S/o-$tool"
  PATH="$(tool_dir "$tool" "$tool")" "$BASH_BIN" "$SCRIPT" "$S/o-$tool" >"$S/log-$tool" 2>&1; rc=$?
  [ "$rc" -eq 0 ] && cmp -s "$out/install.sh.sha256" "$S/o-$tool/install.sh.sha256" && ok "only $tool on PATH: same hash file (rc=0)" || fail "only $tool on PATH (rc=$rc: $(tail -1 "$S/log-$tool"))"
done
# no hash tool at all: fail, leave no hash file
rm -rf "$S/o-none"
PATH="$(tool_dir none)" "$BASH_BIN" "$SCRIPT" "$S/o-none" >"$S/log-none" 2>&1; rc=$?
{ [ "$rc" -ne 0 ] && [ ! -e "$S/o-none/install.sh.sha256" ] && grep -q "neither sha256sum nor shasum" "$S/log-none"; } && ok "no hash tool: rc=$rc and no hash file written" || fail "no hash tool (rc=$rc)"
# no argument
bash "$SCRIPT" >/dev/null 2>&1; [ $? -ne 0 ] && ok "no out-dir argument is refused" || fail "no out-dir argument is refused"

# the release step calls it and attaches both assets; notes print the pinned install (R1, R2)
Y=.github/workflows/version.yml
grep -q 'scripts/release-install-assets.sh' "$Y" && ok "version.yml calls release-install-assets.sh" || fail "version.yml calls release-install-assets.sh"
grep -q '"\$DIST/install.sh" "\$DIST/install.sh.sha256"' "$Y" && ok "gh release create attaches both files" || fail "gh release create attaches both files"
grep -q -- '--target "\$(git rev-parse HEAD)"' "$Y" && ok "release tag targets the hashed commit" || fail "release tag targets the hashed commit"
grep -q 'releases/download/\${TAG}' "$Y" && ok "release notes print the pinned download of the tag" || fail "release notes print the pinned download of the tag"

# --- run the real release step of version.yml in a sandbox with a fake `gh` ---------------------
# The step only runs on push to main, so this is the only place it is exercised before a merge.
step_body() { # prints the shell body of the release step with the workflow expression filled in
  awk '/- name: Create GitHub Release if tag missing/{f=1} f&&/run: \|/{r=1; next} r{ if ($0 ~ /^      - /) exit; sub(/^          /,""); print }' "$Y" \
    | sed 's/\${{ steps.bump.outputs.version }}/9.9.9/'
}
mk_sandbox() { # mk_sandbox <dir>: a git repo with an origin, a previous tag, and a fake gh
  local d="$1"; mkdir -p "$d/repo" "$d/bin" "$d/pub"
  (cd "$REPO_ROOT" && git ls-files -co --exclude-standard -z | xargs -0 -I{} sh -c 'mkdir -p "$1/$(dirname "$2")" && cp -P "$2" "$1/$2"' _ "$d/repo" {})
  ( cd "$d/repo" && git init -q -b main && git -c user.name=t -c user.email=t@t add -A >/dev/null 2>&1 \
    && git -c user.name=t -c user.email=t@t commit -q -m one && git tag v0.0.1 \
    && git clone -q --bare . "$d/origin.git" && git remote add origin "$d/origin.git" )
  cat > "$d/bin/gh" <<GH
#!/usr/bin/env bash
case "\$1 \$2" in
  "release view") exit 1 ;;
  "release create") echo "\$@" > "$d/gh.args"
    while [ \$# -gt 0 ]; do case "\$1" in
      */install.sh|*/install.sh.sha256) cp "\$1" "$d/pub/";;
      --notes-file) cp "\$2" "$d/notes.md"; shift;;
    esac; shift; done ;;
  *) echo "unexpected gh call: \$*" >&2; exit 9 ;;
esac
GH
  chmod +x "$d/bin/gh"
}
run_step() { # run_step <sandbox> -> exit code of the real step body
  ( cd "$1/repo" && GH_TOKEN=x PATH="$1/bin:$PATH" bash -e -c "$(step_body)" ) >"$1/step.log" 2>&1
}
[ -n "$(step_body)" ] && ok "extracted the release step body from version.yml" || fail "extracted the release step body from version.yml"
mk_sandbox "$S/sbx"; run_step "$S/sbx"; rc=$?
[ "$rc" -eq 0 ] && ok "release step runs against a fake gh (rc=0)" || fail "release step (rc=$rc: $(tail -2 "$S/sbx/step.log" | tr '\n' ' '))"
head_sha="$(git -C "$S/sbx/repo" rev-parse HEAD)"
grep -q -- "release create v9.9.9 .*/install.sh .*/install.sh.sha256 --target $head_sha " "$S/sbx/gh.args" && ok "gh release create v9.9.9 attaches both files at --target HEAD" || fail "gh args: $(cat "$S/sbx/gh.args" 2>/dev/null)"
if (cd "$S/sbx/pub" && { command -v sha256sum >/dev/null && sha256sum -c install.sh.sha256 || shasum -a 256 -c install.sh.sha256; }) >/dev/null 2>&1
then ok "published pair passes the user's check"; else fail "published pair passes the user's check"; fi
cmp -s "$REPO_ROOT/scripts/install.sh" "$S/sbx/pub/install.sh" && ok "published install.sh is this commit's scripts/install.sh" || fail "published install.sh differs"
grep -q 'releases/download/v9.9.9/install.sh.sha256' "$S/sbx/notes.md" && ok "release notes name the pinned assets of v9.9.9" || fail "release notes: $(cat "$S/sbx/notes.md" 2>/dev/null)"
if grep -Eq 'curl.*[|] *ba''sh' "$S/sbx/notes.md"; then fail "release notes still pipe curl into bash"; else ok "release notes have no curl-into-bash line"; fi
# failure path: no install.sh to hash -> the step stops and no release is created
mk_sandbox "$S/bad"; rm "$S/bad/repo/scripts/install.sh"; run_step "$S/bad"; rc=$?
{ [ "$rc" -ne 0 ] && [ ! -e "$S/bad/gh.args" ] && grep -q "install.sh not found" "$S/bad/step.log"; } && ok "asset build fails: step rc=$rc and gh release create never called" || fail "asset-build failure path (rc=$rc, gh.args exists? $([ -e "$S/bad/gh.args" ] && echo y || echo n))"
finish
