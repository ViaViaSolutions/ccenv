#!/usr/bin/env bash
# ccenv installer — makes `ccenv` callable from any terminal and wires up
# the `use`/`unuse` shell integration. Idempotent; safe to re-run.
#
#   curl -fsSL https://ccenv.dev/install.sh | bash   # web install (no clone)
#   ./install.sh                                      # from a cloned repo
#   CCENV_BIN_DIR=/usr/local/bin ./install.sh         # force the bin dir
set -uo pipefail

REPO="$(cd "$(dirname "$0")" 2>/dev/null && pwd -P || true)"
BASE_URL="${CCENV_BASE_URL:-https://ccenv.dev}"
BIN_SRC="$REPO/bin/ccenv"
SHELL_SRC="$REPO/shell/ccenv.sh"
WEB_INSTALL=0

B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'; D=$'\033[2m'; X=$'\033[0m'
ok(){   printf '%s✓%s %s\n' "$G" "$X" "$*"; }
warn(){ printf '%s!%s %s\n' "$Y" "$X" "$*"; }
step(){ printf '%s•%s %s\n' "$C" "$X" "$*"; }

# Source the two artifacts. From a clone they sit next to this script; run as
# `curl … | bash` there is no clone, so download them from BASE_URL instead.
fetch(){ # url dest
  if command -v curl >/dev/null 2>&1; then curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null 2>&1; then wget -qO "$2" "$1"
  else echo "need curl or wget to install ccenv from the web" >&2; return 1; fi
}
if [ -f "$BIN_SRC" ] && [ -f "$SHELL_SRC" ]; then
  chmod +x "$BIN_SRC" 2>/dev/null || true
  [ -f "$REPO/uninstall.sh" ] && chmod +x "$REPO/uninstall.sh" 2>/dev/null || true
  # The installed binary & shell snippet run code from $REPO. If others can write
  # there, they can run code as you on shell startup. Warn on a writable repo.
  if [ -n "$(find "$REPO" -maxdepth 0 -perm -0022 2>/dev/null)" ]; then
    warn "repo is group/other-writable: $REPO — anyone who can write it runs code as you (chmod go-w it)"
  fi
else
  WEB_INSTALL=1
  DL_TMP="$(mktemp -d)" || { echo "cannot create temp dir" >&2; exit 1; }
  trap 'rm -rf "$DL_TMP"' EXIT
  step "downloading ccenv from $BASE_URL"
  fetch "$BASE_URL/bin/ccenv"      "$DL_TMP/ccenv"    || { echo "download failed: $BASE_URL/bin/ccenv"  >&2; exit 1; }
  fetch "$BASE_URL/shell/ccenv.sh" "$DL_TMP/ccenv.sh" || { echo "download failed: $BASE_URL/shell/ccenv.sh" >&2; exit 1; }
  # Sanity-check before installing: reject HTML error pages / truncated bodies.
  { head -n1 "$DL_TMP/ccenv" | grep -q '^#!' && grep -q 'CCENV_VERSION=' "$DL_TMP/ccenv"; } \
    || { echo "downloaded ccenv looks wrong (not the expected script) — aborting" >&2; exit 1; }
  grep -q 'CCENV_SHELL_LOADED' "$DL_TMP/ccenv.sh" \
    || { echo "downloaded shell snippet looks wrong — aborting" >&2; exit 1; }
  chmod +x "$DL_TMP/ccenv"
  BIN_SRC="$DL_TMP/ccenv"
  SHELL_SRC="$DL_TMP/ccenv.sh"
fi

# CCENV_HOME backs a copied, user-owned shell snippet (so shell startup does
# not source code from the mutable repo). Guard it like bin/ccenv does.
CCENV_HOME="${CCENV_HOME:-$HOME/.ccenv}"
# Strip trailing slashes first: "$HOME//" slips past the case guard (? matches
# / in a case pattern) and "link/" past the -L check (test follows it).
while [ "${CCENV_HOME%/}" != "$CCENV_HOME" ]; do CCENV_HOME="${CCENV_HOME%/}"; done
case "$CCENV_HOME" in
  *..*)       echo "refusing CCENV_HOME with '..': $CCENV_HOME" >&2; exit 1 ;;
  "$HOME"/?*) : ;;
  *)          echo "refusing unsafe CCENV_HOME=$CCENV_HOME (must be under $HOME)" >&2; exit 1 ;;
esac
[ -L "$CCENV_HOME" ] && { echo "CCENV_HOME is a symlink — refusing" >&2; exit 1; }
DEST_SHELL="$CCENV_HOME/shell/ccenv.sh"

on_path(){ case ":$PATH:" in *":$1:"*) return 0;; *) return 1;; esac; }
# Portable octal file mode. Gate on uname — on GNU stat, `-f` means
# --file-system and would pollute the captured output instead of failing clean.
file_mode(){
  case "$(uname -s 2>/dev/null)" in
    Darwin|*BSD*) stat -f '%Lp' "$1" 2>/dev/null ;;
    *)            stat -c '%a'  "$1" 2>/dev/null ;;
  esac
}

# ---- 1. choose a bin dir ------------------------------------------------------
# Candidate dirs, in order of preference. We pick the first that is already on
# PATH and writable (so no PATH edit is needed). Home dirs first to avoid
# polluting Homebrew/system dirs. Otherwise fall back to ~/.local/bin + PATH.
CANDIDATES=("$HOME/.local/bin" "$HOME/bin" "/opt/homebrew/bin" "/usr/local/bin")
BIN_DIR=""
NEED_PATH_EDIT=0

if [ -n "${CCENV_BIN_DIR:-}" ]; then
  case "$CCENV_BIN_DIR" in
    *..*) echo "CCENV_BIN_DIR must not contain '..': $CCENV_BIN_DIR" >&2; exit 1 ;;
    /*)   : ;;
    *)    echo "CCENV_BIN_DIR must be an absolute path: $CCENV_BIN_DIR" >&2; exit 1 ;;
  esac
  BIN_DIR="$CCENV_BIN_DIR"
  mkdir -p "$BIN_DIR" 2>/dev/null || true
  on_path "$BIN_DIR" || NEED_PATH_EDIT=1
else
  for d in "${CANDIDATES[@]}"; do
    if on_path "$d" && [ -d "$d" ] && [ -w "$d" ]; then BIN_DIR="$d"; break; fi
  done
  if [ -z "$BIN_DIR" ]; then
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
    on_path "$BIN_DIR" || NEED_PATH_EDIT=1
  fi
fi
[ -w "$BIN_DIR" ] || { echo "bin dir not writable: $BIN_DIR (try: CCENV_BIN_DIR=~/.local/bin ./install.sh)"; exit 1; }

# Remove stale ccenv symlinks from other candidate dirs (avoid shadowing).
for d in "${CANDIDATES[@]}"; do
  [ "$d" = "$BIN_DIR" ] && continue
  [ -L "$d/ccenv" ] && rm -f "$d/ccenv" && step "removed stale link $d/ccenv"
done

# From a clone: symlink where supported (auto-updates on `git pull`), copy as a
# fallback (e.g. Git Bash without Developer Mode). Web install: always copy — the
# downloaded source lives in a temp dir that is removed when this script exits.
if [ "$WEB_INSTALL" -eq 0 ] && ln -sf "$BIN_SRC" "$BIN_DIR/ccenv" 2>/dev/null; then
  ok "installed ccenv → $BIN_DIR/ccenv  ${D}(→ $BIN_SRC)${X}"
else
  cp "$BIN_SRC" "$BIN_DIR/ccenv" && chmod +x "$BIN_DIR/ccenv"
  if [ "$WEB_INSTALL" -eq 1 ]; then
    ok "installed ccenv → $BIN_DIR/ccenv  ${D}(re-run the curl command to update)${X}"
  else
    ok "installed ccenv → $BIN_DIR/ccenv  ${D}(copy; re-run install.sh to update)${X}"
  fi
fi

# Copy the shell snippet to a stable, user-owned location so shell startup does
# NOT source code from the (mutable, possibly-moved) repo.
mkdir -p "$CCENV_HOME/shell"
chmod 700 "$CCENV_HOME" "$CCENV_HOME/shell" 2>/dev/null || true
cp "$SHELL_SRC" "$DEST_SHELL"
chmod 600 "$DEST_SHELL" 2>/dev/null || true

# ---- 2. wire the shell rc -----------------------------------------------------
detect_rc(){
  if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "${SHELL:-}")" = "zsh" ]; then
    printf '%s' "${ZDOTDIR:-$HOME}/.zshrc"
  else
    printf '%s' "$HOME/.bashrc"
  fi
}
RC="$(detect_rc)"; touch "$RC"
# Follow a symlinked rc (stow/chezmoi dotfiles) to its physical file so
# add_line's atomic rewrite never replaces the user's symlink with a copy.
hops=0
while [ -L "$RC" ] && [ "$hops" -lt 10 ]; do
  t="$(readlink "$RC")" || break
  case "$t" in /*) RC="$t" ;; *) RC="$(dirname "$RC")/$t" ;; esac
  hops=$((hops + 1))
done

add_line(){ # marker, line → idempotent upsert (line is already shell-safe)
  local marker="$1" line="$2" tmp perm
  # already present and identical → no-op
  grep -qF "$line  $marker" "$RC" 2>/dev/null && return 1
  # present but stale (e.g. old path) → atomically drop the old marked line(s)
  if grep -qF "$marker" "$RC" 2>/dev/null; then
    tmp="$(mktemp "${RC}.ccenv.XXXXXX")" || return 2
    grep -vF "$marker" "$RC" > "$tmp" || true
    perm="$(file_mode "$RC")"; [ -n "$perm" ] && chmod "$perm" "$tmp" 2>/dev/null
    mv "$tmp" "$RC"
  fi
  printf '\n%s  %s\n' "$line" "$marker" >> "$RC"; return 0
}

# Build rc lines with printf %q so any special char in a path (quote, $(), space,
# newline) is safely escaped and can never inject code when the rc is sourced.
if [ "$NEED_PATH_EDIT" -eq 1 ]; then
  printf -v PATH_LINE 'export PATH=%q:$PATH' "$BIN_DIR"
  if add_line "# >>> ccenv path >>>" "$PATH_LINE"; then
    ok "added $BIN_DIR to PATH in ${RC/#$HOME/~}"
  else
    ok "PATH entry already in ${RC/#$HOME/~}"
  fi
fi

make_source_line(){
  printf 'source %q' "$DEST_SHELL"
}
SRC_LINE="$(make_source_line)"
if add_line "# >>> ccenv shell integration >>>" "$SRC_LINE"; then
  ok "added shell integration to ${RC/#$HOME/~}"
else
  ok "shell integration already in ${RC/#$HOME/~}"
fi

# ---- 3. verify ----------------------------------------------------------------
if PATH="$BIN_DIR:$PATH" command -v ccenv >/dev/null 2>&1; then
  ok "verified: ccenv resolves on PATH"
else
  warn "ccenv not resolving — check that $BIN_DIR is on PATH"
fi

printf '\n%sInstalled.%s Activate in your current shell:\n' "$B" "$X"
printf '  %ssource %s%s\n' "$C" "$RC" "$X"
printf '%s(new terminals pick it up automatically)%s\n\n' "$D" "$X"
printf 'Then:\n'
printf '  %sccenv list%s            your current account shows as "default"\n' "$C" "$X"
printf '  %sccenv create work%s     add another account\n' "$C" "$X"
printf '  %sccenv use work%s        point this shell at it\n' "$C" "$X"
