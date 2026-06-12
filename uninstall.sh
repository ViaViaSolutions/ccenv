#!/usr/bin/env bash
# ccswitch uninstaller. Removes the PATH symlink and the rc line.
# Does NOT delete your profiles or sign anyone out unless you pass --purge.
set -uo pipefail

B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; X=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$X" "$*"; }
warn(){ printf '%s!%s %s\n' "$Y" "$X" "$*"; }
# Portable octal file mode: BSD stat (macOS) then GNU stat (Linux).
file_mode(){ stat -f '%Lp' "$1" 2>/dev/null || stat -c '%a' "$1" 2>/dev/null; }

PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

# Guard CCSWITCH_HOME before it can reach rm -rf (matches bin/ccswitch).
CCSWITCH_HOME="${CCSWITCH_HOME:-$HOME/.ccswitch}"
case "$CCSWITCH_HOME" in
  *..*)       echo "refusing CCSWITCH_HOME with '..': $CCSWITCH_HOME" >&2; exit 1 ;;
  "$HOME"/?*) : ;;
  *)          echo "refusing unsafe CCSWITCH_HOME=$CCSWITCH_HOME (must be under $HOME)" >&2; exit 1 ;;
esac
[ -L "$CCSWITCH_HOME" ] && { echo "CCSWITCH_HOME is a symlink — refusing" >&2; exit 1; }

# Remove the ccswitch symlink from any dir the installer may have used.
for d in "${CCSWITCH_BIN_DIR:-}" "/opt/homebrew/bin" "/usr/local/bin" "$HOME/.local/bin" "$HOME/bin"; do
  [ -n "$d" ] || continue
  if [ -L "$d/ccswitch" ]; then rm -f "$d/ccswitch" && ok "removed $d/ccswitch"; fi
done

# Atomically strip ccswitch lines from an rc file (preserve mode; temp in same
# dir so the final mv is atomic; trap cleans up on interrupt).
prune_rc(){
  local rc="$1" tmp perm
  grep -qF "# >>> ccswitch " "$rc" 2>/dev/null || return 0
  tmp="$(mktemp "${rc}.ccswitch.XXXXXX")" || return 1
  grep -vF "# >>> ccswitch " "$rc" > "$tmp" || true
  perm="$(file_mode "$rc")"; [ -n "$perm" ] && chmod "$perm" "$tmp" 2>/dev/null
  mv "$tmp" "$rc" && ok "removed ccswitch lines from ${rc/#$HOME/~}"
  rm -f "$tmp" 2>/dev/null   # no-op after a successful mv; cleans up on failure
}

# Candidate rc files (unique; avoid processing ~/.zshrc twice when ZDOTDIR unset).
RCS="${ZDOTDIR:-$HOME}/.zshrc
$HOME/.zshrc
$HOME/.bashrc"
while IFS= read -r RC; do
  [ -f "$RC" ] && prune_rc "$RC"
done < <(printf '%s\n' "$RCS" | sort -u)

if [ "$PURGE" -eq 1 ]; then
  failures=""
  if [ -d "$CCSWITCH_HOME/profiles" ]; then
    if ! command -v claude >/dev/null 2>&1; then
      warn "claude not on PATH — cannot sign profiles out; stored credentials may remain"
    else
      for d in "$CCSWITCH_HOME"/profiles/*/; do
        [ -d "$d" ] || continue
        if CLAUDE_CONFIG_DIR="${d%/}" claude auth logout >/dev/null 2>&1; then
          ok "signed out $(basename "$d")"
        else
          failures="$failures $(basename "$d")"
        fi
      done
    fi
  fi
  [ -n "$failures" ] && warn "logout failed for:$failures — stored credentials may remain (macOS: remove 'Claude Code-credentials*' from Keychain Access; Linux/Windows: clear with 'claude auth logout')"
  rm -rf "$CCSWITCH_HOME"
  ok "deleted $CCSWITCH_HOME (all profiles)"
else
  warn "profiles kept at ${CCSWITCH_HOME/#$HOME/~} — run with --purge to delete & sign out"
fi
ok "done"
