#!/usr/bin/env bash
# What Helix created, decided from a symlink's raw target text (readlink, never resolved), so a
# broken Helix link is still recognised. Everything else belongs to the user and is never deleted.
# Usage: . scripts/lib/helix-owned.sh
# Spec: docs/sdd/link-skills-no-delete (Terms, R3, R4, R11, R12)

# helix_is_skill_link <entry> <name> <relative 0|1> <repo> [repo_physical]
# True when <entry> is a symlink to <repo>/skills/…/<name> (logical or physical repo path), or,
# in relative mode, exactly ../../skills/<name>. A link into an older clone or cache is not ours.
helix_is_skill_link() {
  local entry="$1" name="$2" relative="$3" repo="$4" repo_p="${5:-}" t
  [ -L "$entry" ] || return 1
  t="$(readlink "$entry")" || return 1
  if [ "$relative" = 1 ] && [ "$t" = "../../skills/$name" ]; then
    return 0
  fi
  [ "$(basename "$t")" = "$name" ] || return 1
  case "$t" in
    "$repo"/skills/*) return 0 ;;
  esac
  if [ -n "$repo_p" ]; then
    case "$t" in
      "$repo_p"/skills/*) return 0 ;;
    esac
  fi
  return 1
}

# helix_is_cache_link <entry> <clone> [clone_physical]
# True when <entry> is a symlink whose raw target names the clone itself: the same text as
# <clone> or <clone_physical>, or a directory whose `pwd -P` is <clone_physical> (install.sh links
# the logical path, setup.sh the git top level, which is physical).
helix_is_cache_link() {
  local entry="$1" clone="$2" clone_p="${3:-}" t t_p
  [ -L "$entry" ] || return 1
  t="$(readlink "$entry")" || return 1
  t="${t%/}"
  [ "$t" = "$clone" ] && return 0
  [ -n "$clone_p" ] || return 1
  [ "$t" = "$clone_p" ] && return 0
  case "$t" in /*) ;; *) return 1 ;; esac   # never resolve a relative target against our cwd
  t_p="$(cd "$t" 2>/dev/null && pwd -P)" || return 1
  [ "$t_p" = "$clone_p" ]
}

# helix_link_plugin_cache <cache_base> <version> <clone>
# Remove only Helix cache links under <cache_base> (unlink, never recursive), keep and warn about
# every other entry, then link <cache_base>/<version> -> <clone> when that path is free.
# Always returns 0 so a caller under `set -e` keeps going (R12).
helix_link_plugin_cache() {
  local base="$1" ver="$2" clone="$3" clone_p entry kept=0
  clone="${clone%/}"
  clone_p="$(cd "$clone" 2>/dev/null && pwd -P || true)"
  mkdir -p "$base"
  for entry in "$base"/* "$base"/.[!.]*; do
    [ -e "$entry" ] || [ -L "$entry" ] || continue
    if helix_is_cache_link "$entry" "$clone" "$clone_p"; then
      rm -f -- "$entry"
    else
      echo "keep (plugin cache) $entry: not a Helix link to $clone — left unchanged" >&2
      kept=$((kept + 1))
    fi
  done
  if [ -e "$base/$ver" ] || [ -L "$base/$ver" ]; then
    echo "skip (plugin cache) $base/$ver is not a Helix link — rename or remove it, then re-run the installer" >&2
  else
    ln -s "$clone" "$base/$ver"
  fi
  [ "$kept" -eq 0 ] || echo "$kept plugin cache entr(y/ies) kept because Helix did not create them (see above)" >&2
  return 0
}
