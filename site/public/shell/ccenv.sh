# ccenv shell integration — source this from ~/.zshrc or ~/.bashrc.
#
#   source "/path/to/ccenv/shell/ccenv.sh"
#
# It defines a `ccenv` shell function so `ccenv use <name>` can change
# CLAUDE_CONFIG_DIR in your CURRENT shell (a child process cannot do that).
# Every other subcommand is forwarded to the real `ccenv` binary on PATH.

# Apply the pin/default that governs $PWD to THIS shell — unless an explicit
# `ccenv use` is in effect (CCENV_PROFILE set WITHOUT CCENV_AUTO). Used both at
# shell startup and right after `ccenv pin`/`unpin`, so a pin takes effect
# immediately, not only in new terminals. Auto-applied profiles are tagged
# CCENV_AUTO=1 so they re-resolve per-directory instead of leaking through an
# inherited environment (a new tab / editor terminal / tmux pane). Cheap when
# nothing is configured: only spawns `ccenv resolve-auto` if a default or pins
# file exists. Keep in sync with cmd_shell_init.
__ccenv_autoapply() {
  [ -z "${CCENV_PROFILE:-}" ] || [ -n "${CCENV_AUTO:-}" ] || return 0
  local __a="" __n __d
  if [ -e "${CCENV_HOME:-$HOME/.ccenv}/default" ] || [ -e "${CCENV_HOME:-$HOME/.ccenv}/pins" ]; then
    __a="$(command ccenv resolve-auto "$PWD" 2>/dev/null)"
  fi
  # Require a NAME<tab>DIR shape; ignore tab-less output (e.g. an error string
  # from a mismatched/older binary on PATH) so it can't set a bogus profile.
  if [ -n "$__a" ] && [ "$__a" != "${__a#*$'\t'}" ]; then
    __n="${__a%%$'\t'*}"; __d="${__a#*$'\t'}"
    if [ -n "$__d" ]; then export CLAUDE_CONFIG_DIR="$__d"; else unset CLAUDE_CONFIG_DIR; fi
    export CCENV_PROFILE="$__n" CCENV_AUTO=1
  elif [ -n "${CCENV_AUTO:-}" ]; then
    # An auto profile was inherited but nothing applies here — revert it so it
    # can't leak from the directory it was set in.
    unset CLAUDE_CONFIG_DIR CCENV_PROFILE CCENV_AUTO
  fi
}

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
      # now; the show/clear forms just print.
      command ccenv "$@" || return $?
      case "${2:-}" in
        ""|--clear|clear|none|off|-*) : ;;
        *) ccenv use "$2" ;;
      esac
      ;;
    pin|unpin)
      # Persist the pin (binary), then reflect it in THIS shell immediately —
      # new terminals already do this at startup. Never overrides an explicit use.
      command ccenv "$@" || return $?
      __ccenv_autoapply
      command ccenv current
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
      unset -f ccenv __ccenv_autoapply
      ;;
    *)
      command ccenv "$@"
      ;;
  esac
}

export CCENV_SHELL_LOADED=1

# Auto-apply the pin/default for this shell's starting directory. Re-resolves
# when the shell has no profile yet, or when an inherited profile was itself
# auto-applied (so it never leaks out of the directory it was set in).
__ccenv_autoapply
