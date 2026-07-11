#!/usr/bin/env bash
# ccenv uninstaller. Removes the PATH symlink and the rc line.
# Does NOT delete your profiles or sign anyone out unless you pass --purge.
set -uo pipefail

B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; X=$'\033[0m'
ok(){ printf '%s✓%s %s\n' "$G" "$X" "$*"; }
warn(){ printf '%s!%s %s\n' "$Y" "$X" "$*"; }
# Portable octal file mode. Gate on uname — on GNU stat, `-f` means
# --file-system and would pollute the captured output instead of failing clean.
file_mode(){
  case "$(uname -s 2>/dev/null)" in
    Darwin|*BSD*) stat -f '%Lp' "$1" 2>/dev/null ;;
    *)            stat -c '%a'  "$1" 2>/dev/null ;;
  esac
}

PURGE=0; YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --purge)  PURGE=1 ;;
    -y|--yes) YES=1 ;;
    *) echo "unknown option: $1  (usage: ./uninstall.sh [--purge] [-y])" >&2; exit 1 ;;
  esac
  shift
done

# Guard CCENV_HOME before it can reach rm -rf (matches bin/ccenv).
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

# Confirm, mirroring `ccenv uninstall` (keep the two in sync).
if [ "$YES" -ne 1 ]; then
  if [ "$PURGE" -eq 1 ]; then
    printf 'Uninstall ccenv and DELETE ALL PROFILES (signs every account out)? [y/N] '
  else
    printf 'Uninstall ccenv? Profiles at %s are kept. [y/N] ' "${CCENV_HOME/#$HOME/~}/profiles"
  fi
  read -r ans || ans="n"
  case "${ans:-n}" in y|Y|yes|YES) : ;; *) echo "Aborted."; exit 2 ;; esac
fi

# Remove the installed ccenv (symlink, or copy on e.g. Git Bash) from any
# dir the installer may have used. Keep in sync with cmd_uninstall in bin/ccenv.
for d in "${CCENV_BIN_DIR:-}" "/opt/homebrew/bin" "/usr/local/bin" "$HOME/.local/bin" "$HOME/bin"; do
  [ -n "$d" ] || continue
  if [ -L "$d/ccenv" ]; then
    rm -f "$d/ccenv" && ok "removed $d/ccenv"
  elif [ -f "$d/ccenv" ] && grep -q 'CCENV_VERSION=' "$d/ccenv" 2>/dev/null; then
    # never a repo checkout's own bin/ccenv (e.g. CCENV_BIN_DIR=<repo>/bin)
    if [ -f "$d/../install.sh" ] && [ -f "$d/../shell/ccenv.sh" ]; then continue; fi
    rm -f "$d/ccenv" && ok "removed $d/ccenv (copied binary)"
  fi
  # Bundled macOS sibling: remove ccdesktop the same way (never a repo checkout's).
  if [ -L "$d/ccdesktop" ]; then
    rm -f "$d/ccdesktop" && ok "removed $d/ccdesktop"
  elif [ -f "$d/ccdesktop" ] && grep -q 'CCDESK_VERSION=' "$d/ccdesktop" 2>/dev/null; then
    if [ ! -f "$d/../install.sh" ] || [ ! -f "$d/../shell/ccenv.sh" ]; then
      rm -f "$d/ccdesktop" && ok "removed $d/ccdesktop (copied binary)"
    fi
  fi
done

# Atomically strip ccenv lines from an rc file (preserve mode; temp in same
# dir so the final mv is atomic; trap cleans up on interrupt).
prune_rc(){
  local rc="$1" tmp perm t hops=0
  grep -qF "# >>> ccenv " "$rc" 2>/dev/null || return 0
  # Follow a symlinked rc (stow/chezmoi dotfiles) to its physical file so the
  # atomic mv rewrites the target instead of replacing the user's symlink.
  while [ -L "$rc" ] && [ "$hops" -lt 10 ]; do
    t="$(readlink "$rc")" || break
    case "$t" in /*) rc="$t" ;; *) rc="$(dirname "$rc")/$t" ;; esac
    hops=$((hops + 1))
  done
  tmp="$(mktemp "${rc}.ccenv.XXXXXX")" || return 1
  grep -vF "# >>> ccenv " "$rc" > "$tmp" || true
  perm="$(file_mode "$rc")"; [ -n "$perm" ] && chmod "$perm" "$tmp" 2>/dev/null
  mv "$tmp" "$rc" && ok "removed ccenv lines from ${rc/#$HOME/~}"
  rm -f "$tmp" 2>/dev/null   # no-op after a successful mv; cleans up on failure
}

# Candidate rc files (unique; avoid processing ~/.zshrc twice when ZDOTDIR unset).
RCS="${ZDOTDIR:-$HOME}/.zshrc
$HOME/.zshrc
$HOME/.bashrc"
while IFS= read -r RC; do
  [ -f "$RC" ] && prune_rc "$RC"
done < <(printf '%s\n' "$RCS" | sort -u)

# Remove the installed shell snippet (orphaned once the rc line is gone).
if [ -f "$CCENV_HOME/shell/ccenv.sh" ]; then
  rm -f "$CCENV_HOME/shell/ccenv.sh" && ok "removed installed shell snippet"
  rmdir "$CCENV_HOME/shell" 2>/dev/null || true
fi

if [ "$PURGE" -eq 1 ]; then
  failures=""
  if [ -d "$CCENV_HOME/profiles" ]; then
    if ! command -v claude >/dev/null 2>&1; then
      warn "claude not on PATH — cannot sign profiles out; stored credentials may remain"
    else
      for d in "$CCENV_HOME"/profiles/*/; do
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
  rm -rf "$CCENV_HOME"
  ok "deleted $CCENV_HOME (all profiles)"
else
  warn "profiles kept at ${CCENV_HOME/#$HOME/~} — run with --purge to delete & sign out"
fi
ok "done"
