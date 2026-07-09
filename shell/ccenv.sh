# ccenv shell integration — source this from ~/.zshrc or ~/.bashrc.
#
#   source "/path/to/ccenv/shell/ccenv.sh"
#
# It defines a `ccenv` shell function so `ccenv use <name>` can change
# CLAUDE_CONFIG_DIR in your CURRENT shell (a child process cannot do that).
# Every other subcommand is forwarded to the real `ccenv` binary on PATH.

ccenv() {
  case "${1:-}" in
    use)
      if [ -z "${2:-}" ]; then command ccenv help; return 2; fi
      local __d
      if ! __d="$(command ccenv resolve "$2")"; then
        return 1   # unknown profile: leave this shell untouched
      fi
      if [ -z "$__d" ]; then
        unset CLAUDE_CONFIG_DIR        # default profile = ambient ~/.claude
      else
        export CLAUDE_CONFIG_DIR="$__d"
      fi
      export CCENV_PROFILE="$2"
      unset CCENV_AUTO                # explicit choice — never auto-re-resolved
      command ccenv current
      ;;
    unuse)
      unset CLAUDE_CONFIG_DIR CCENV_PROFILE CCENV_AUTO
      command ccenv current
      ;;
    default|set-default|setdefault)
      # `default <name>` persists the choice (binary) AND switches this shell
      # now; the show/clear forms just print. Keep in sync with cmd_shell_init.
      command ccenv "$@" || return $?
      case "${2:-}" in
        ""|--clear|clear|none|off|-*) : ;;
        *) ccenv use "$2" ;;
      esac
      ;;
    uninstall)
      command ccenv "$@"
      local __rc=$?
      # 126/127 = binary already gone (repo clone deleted, or uninstalled from
      # another shell) — still clear this shell's integration. Abort keeps it.
      case "$__rc" in
        126|127) echo "ccenv binary already gone — cleared this shell's integration (repo leftovers: ./uninstall.sh)" >&2 ;;
        0) : ;;
        *) return "$__rc" ;;
      esac
      unset CLAUDE_CONFIG_DIR CCENV_PROFILE CCENV_AUTO CCENV_SHELL_LOADED
      unset -f ccenv
      ;;
    *)
      command ccenv "$@"
      ;;
  esac
}

export CCENV_SHELL_LOADED=1

# Auto-apply a profile to this shell based on $PWD: the nearest directory pin
# wins, else the standing default. Re-resolve when this shell has NO profile yet,
# OR when the inherited profile was itself auto-applied (CCENV_AUTO) — otherwise
# an auto profile would leak out of the directory it was set in through a new
# tab / editor terminal / tmux pane that inherits the environment. An explicit
# `ccenv use` clears CCENV_AUTO, so it is never re-resolved and sticks across
# subshells. One `ccenv resolve-auto` spawn, only when a default or pins exists.
if [ -z "${CCENV_PROFILE:-}" ] || [ -n "${CCENV_AUTO:-}" ]; then
  __ccenv_auto=""
  if [ -e "${CCENV_HOME:-$HOME/.ccenv}/default" ] || [ -e "${CCENV_HOME:-$HOME/.ccenv}/pins" ]; then
    __ccenv_auto="$(command ccenv resolve-auto "$PWD" 2>/dev/null)"
  fi
  # Require a NAME<tab>DIR shape; ignore tab-less output (e.g. an error string
  # from a mismatched/older binary on PATH) so it can't set a bogus profile.
  if [ -n "$__ccenv_auto" ] && [ "$__ccenv_auto" != "${__ccenv_auto#*$'\t'}" ]; then
    __ccenv_name="${__ccenv_auto%%$'\t'*}"
    __ccenv_dir="${__ccenv_auto#*$'\t'}"
    if [ -n "$__ccenv_dir" ]; then export CLAUDE_CONFIG_DIR="$__ccenv_dir"; else unset CLAUDE_CONFIG_DIR; fi
    export CCENV_PROFILE="$__ccenv_name" CCENV_AUTO=1
  elif [ -n "${CCENV_AUTO:-}" ]; then
    # An auto-applied profile was inherited but nothing applies to this dir —
    # revert it so it can't leak from the directory it was set in.
    unset CLAUDE_CONFIG_DIR CCENV_PROFILE CCENV_AUTO
  fi
  unset __ccenv_auto __ccenv_name __ccenv_dir
fi
