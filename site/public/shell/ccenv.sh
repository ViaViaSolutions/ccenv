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
