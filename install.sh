#!/usr/bin/env bash
# ccswitch installer — makes `ccswitch` callable from any terminal and wires up
# the `use`/`unuse` shell integration. Idempotent; safe to re-run.
#
#   ./install.sh                      # auto: pick a PATH dir, wire your shell rc
#   CCSWITCH_BIN_DIR=/usr/local/bin ./install.sh   # force the bin dir
set -uo pipefail

REPO="$(cd "$(dirname "$0")" && pwd -P)"
BIN_SRC="$REPO/bin/ccswitch"
SHELL_SRC="$REPO/shell/ccswitch.sh"

B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'; D=$'\033[2m'; X=$'\033[0m'
ok(){   printf '%s✓%s %s\n' "$G" "$X" "$*"; }
warn(){ printf '%s!%s %s\n' "$Y" "$X" "$*"; }
step(){ printf '%s•%s %s\n' "$C" "$X" "$*"; }

[ -f "$BIN_SRC" ]   || { echo "missing $BIN_SRC";  exit 1; }
[ -f "$SHELL_SRC" ] || { echo "missing $SHELL_SRC"; exit 1; }
chmod +x "$BIN_SRC" "$REPO/uninstall.sh" 2>/dev/null || true

# The installed binary & shell snippet run code from $REPO. If others can write
# there, they can run code as you on shell startup. Warn on a writable repo.
if [ -n "$(find "$REPO" -maxdepth 0 -perm -0022 2>/dev/null)" ]; then
  warn "repo is group/other-writable: $REPO — anyone who can write it runs code as you (chmod go-w it)"
fi

# CCSWITCH_HOME backs a copied, user-owned shell snippet (so shell startup does
# not source code from the mutable repo). Guard it like bin/ccswitch does.
CCSWITCH_HOME="${CCSWITCH_HOME:-$HOME/.ccswitch}"
case "$CCSWITCH_HOME" in
  *..*)       echo "refusing CCSWITCH_HOME with '..': $CCSWITCH_HOME" >&2; exit 1 ;;
  "$HOME"/?*) : ;;
  *)          echo "refusing unsafe CCSWITCH_HOME=$CCSWITCH_HOME (must be under $HOME)" >&2; exit 1 ;;
esac
[ -L "$CCSWITCH_HOME" ] && { echo "CCSWITCH_HOME is a symlink — refusing" >&2; exit 1; }
DEST_SHELL="$CCSWITCH_HOME/shell/ccswitch.sh"

on_path(){ case ":$PATH:" in *":$1:"*) return 0;; *) return 1;; esac; }
# Portable octal file mode: BSD stat (macOS) then GNU stat (Linux).
file_mode(){ stat -f '%Lp' "$1" 2>/dev/null || stat -c '%a' "$1" 2>/dev/null; }

# ---- 1. choose a bin dir ------------------------------------------------------
# Candidate dirs, in order of preference. We pick the first that is already on
# PATH and writable (so no PATH edit is needed). Home dirs first to avoid
# polluting Homebrew/system dirs. Otherwise fall back to ~/.local/bin + PATH.
CANDIDATES=("$HOME/.local/bin" "$HOME/bin" "/opt/homebrew/bin" "/usr/local/bin")
BIN_DIR=""
NEED_PATH_EDIT=0

if [ -n "${CCSWITCH_BIN_DIR:-}" ]; then
  case "$CCSWITCH_BIN_DIR" in
    *..*) echo "CCSWITCH_BIN_DIR must not contain '..': $CCSWITCH_BIN_DIR" >&2; exit 1 ;;
    /*)   : ;;
    *)    echo "CCSWITCH_BIN_DIR must be an absolute path: $CCSWITCH_BIN_DIR" >&2; exit 1 ;;
  esac
  BIN_DIR="$CCSWITCH_BIN_DIR"
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
[ -w "$BIN_DIR" ] || { echo "bin dir not writable: $BIN_DIR (try: CCSWITCH_BIN_DIR=~/.local/bin ./install.sh)"; exit 1; }

# Remove stale ccswitch symlinks from other candidate dirs (avoid shadowing).
for d in "${CANDIDATES[@]}"; do
  [ "$d" = "$BIN_DIR" ] && continue
  [ -L "$d/ccswitch" ] && rm -f "$d/ccswitch" && step "removed stale link $d/ccswitch"
done

# Symlink where supported; copy as a fallback (e.g. Git Bash without Developer
# Mode, where ln -s can't make a real symlink). A copy won't auto-update on
# `git pull` — re-run install.sh to refresh.
if ln -sf "$BIN_SRC" "$BIN_DIR/ccswitch" 2>/dev/null; then
  ok "installed ccswitch → $BIN_DIR/ccswitch  ${D}(→ $BIN_SRC)${X}"
else
  cp "$BIN_SRC" "$BIN_DIR/ccswitch" && chmod +x "$BIN_DIR/ccswitch"
  ok "installed ccswitch → $BIN_DIR/ccswitch  ${D}(copy; re-run install.sh to update)${X}"
fi

# Copy the shell snippet to a stable, user-owned location so shell startup does
# NOT source code from the (mutable, possibly-moved) repo.
mkdir -p "$CCSWITCH_HOME/shell"
chmod 700 "$CCSWITCH_HOME" "$CCSWITCH_HOME/shell" 2>/dev/null || true
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

add_line(){ # marker, line → idempotent upsert (line is already shell-safe)
  local marker="$1" line="$2" tmp perm
  # already present and identical → no-op
  grep -qF "$line  $marker" "$RC" 2>/dev/null && return 1
  # present but stale (e.g. old path) → atomically drop the old marked line(s)
  if grep -qF "$marker" "$RC" 2>/dev/null; then
    tmp="$(mktemp "${RC}.ccswitch.XXXXXX")" || return 2
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
  if add_line "# >>> ccswitch path >>>" "$PATH_LINE"; then
    ok "added $BIN_DIR to PATH in ${RC/#$HOME/~}"
  else
    ok "PATH entry already in ${RC/#$HOME/~}"
  fi
fi

printf -v SRC_LINE 'source %q' "$DEST_SHELL"
if add_line "# >>> ccswitch shell integration >>>" "$SRC_LINE"; then
  ok "added shell integration to ${RC/#$HOME/~}"
else
  ok "shell integration already in ${RC/#$HOME/~}"
fi

# ---- 3. verify ----------------------------------------------------------------
if PATH="$BIN_DIR:$PATH" command -v ccswitch >/dev/null 2>&1; then
  ok "verified: ccswitch resolves on PATH"
else
  warn "ccswitch not resolving — check that $BIN_DIR is on PATH"
fi

printf '\n%sInstalled.%s Activate in your current shell:\n' "$B" "$X"
printf '  %ssource %s%s\n' "$C" "$RC" "$X"
printf '%s(new terminals pick it up automatically)%s\n\n' "$D" "$X"
printf 'Then:\n'
printf '  %sccswitch list%s            your current account shows as "default"\n' "$C" "$X"
printf '  %sccswitch create work%s     add another account\n' "$C" "$X"
printf '  %sccswitch use work%s        point this shell at it\n' "$C" "$X"
