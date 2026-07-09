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

# Auto-apply a profile to this shell when it hasn't already picked one: a
# directory pin for $PWD (nearest wins) beats the standing default. The
# CCENV_PROFILE guard means subshells and an explicit `ccenv use`/`unuse` always
# win. One `ccenv resolve-auto` spawn per new shell, only when a default or pins
# file exists (so a fresh install with neither still spawns nothing).
if [ -z "${CCENV_PROFILE:-}" ] && { [ -e "${CCENV_HOME:-$HOME/.ccenv}/default" ] || [ -e "${CCENV_HOME:-$HOME/.ccenv}/pins" ]; }; then
  __ccenv_auto="$(command ccenv resolve-auto "$PWD" 2>/dev/null)"
  # Require a NAME<tab>DIR shape; ignore tab-less output (e.g. an error string
  # from a mismatched/older binary on PATH) so it can't set a bogus profile.
  if [ -n "$__ccenv_auto" ] && [ "$__ccenv_auto" != "${__ccenv_auto#*$'\t'}" ]; then
    __ccenv_name="${__ccenv_auto%%$'\t'*}"
    __ccenv_dir="${__ccenv_auto#*$'\t'}"
    if [ -n "$__ccenv_dir" ]; then export CLAUDE_CONFIG_DIR="$__ccenv_dir"; else unset CLAUDE_CONFIG_DIR; fi
    export CCENV_PROFILE="$__ccenv_name"
  fi
  unset __ccenv_auto __ccenv_name __ccenv_dir
fi
