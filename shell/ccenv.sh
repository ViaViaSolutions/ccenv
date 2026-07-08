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
      command ccenv current
      ;;
    unuse)
      unset CLAUDE_CONFIG_DIR CCENV_PROFILE
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
      unset CLAUDE_CONFIG_DIR CCENV_PROFILE CCENV_SHELL_LOADED
      unset -f ccenv
      ;;
    *)
      command ccenv "$@"
      ;;
  esac
}

export CCENV_SHELL_LOADED=1

# Auto-apply the standing default (`ccenv default <name>`) to this shell when it
# hasn't already picked a profile. The CCENV_PROFILE guard means subshells and
# an explicit `ccenv use`/`unuse` always win over the default. One `ccenv
# resolve` spawn per new shell, only when a default is set.
if [ -z "${CCENV_PROFILE:-}" ] && [ -r "${CCENV_HOME:-$HOME/.ccenv}/default" ]; then
  __ccenv_def="$(cat "${CCENV_HOME:-$HOME/.ccenv}/default" 2>/dev/null | head -n1 | tr -d '[:space:]')"
  if [ -n "$__ccenv_def" ] && __ccenv_dir="$(command ccenv resolve "$__ccenv_def" 2>/dev/null)"; then
    [ -n "$__ccenv_dir" ] && export CLAUDE_CONFIG_DIR="$__ccenv_dir"
    export CCENV_PROFILE="$__ccenv_def"
  fi
  unset __ccenv_def __ccenv_dir
fi
