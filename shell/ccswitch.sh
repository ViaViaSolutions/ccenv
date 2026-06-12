# ccswitch shell integration — source this from ~/.zshrc or ~/.bashrc.
#
#   source "/path/to/ccswitch/shell/ccswitch.sh"
#
# It defines a `ccswitch` shell function so `ccswitch use <name>` can change
# CLAUDE_CONFIG_DIR in your CURRENT shell (a child process cannot do that).
# Every other subcommand is forwarded to the real `ccswitch` binary on PATH.

ccswitch() {
  case "${1:-}" in
    use)
      if [ -z "${2:-}" ]; then command ccswitch help; return 2; fi
      local __d
      if ! __d="$(command ccswitch resolve "$2")"; then
        return 1   # unknown profile: leave this shell untouched
      fi
      if [ -z "$__d" ]; then
        unset CLAUDE_CONFIG_DIR        # default profile = ambient ~/.claude
      else
        export CLAUDE_CONFIG_DIR="$__d"
      fi
      export CCSWITCH_PROFILE="$2"
      command ccswitch current
      ;;
    unuse)
      unset CLAUDE_CONFIG_DIR CCSWITCH_PROFILE
      command ccswitch current
      ;;
    *)
      command ccswitch "$@"
      ;;
  esac
}

export CCSWITCH_SHELL_LOADED=1
