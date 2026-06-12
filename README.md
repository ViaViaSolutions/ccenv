# ccswitch

Run multiple **Claude Code** accounts from one machine — switch in a keystroke,
and keep **as many accounts signed in at once as you have terminals**, each on
its own account.

```
$ ccswitch list
● default    johndoe@gmail.com       max
  work       me@company.com          team
  client     not signed in
```

`● = active in this shell`

- **Concurrent, not just switchable** — personal in one terminal, work in
  another, a client in a third… all live at once, no clobbering. No fixed limit.
- **Secure** — ccswitch stores zero secrets; tokens stay in the OS credential
  store, managed by Claude Code.
- **Your setup comes along** — every profile inherits your plugins, skills,
  commands, and hooks.
- **Nothing to migrate** — your current login is already profile `default`.

---

## Requirements

- [Claude Code](https://claude.com/claude-code) installed (`claude` on your `PATH`)
- **macOS** or **Linux** (native), or **Windows** via **Git Bash** or **WSL**

## Install

```sh
git clone <this repo> ccswitch && cd ccswitch
./install.sh
# activate in the current shell (new terminals do this automatically):
source ~/.zshrc      # macOS (zsh)
# source ~/.bashrc   # Linux / Git Bash
```

`install.sh` is idempotent: it puts `ccswitch` on your `PATH` (preferring a dir
already on it, e.g. `~/.local/bin`, and only touching your rc if none is found),
adds one line for the `use`/`unuse` shell integration, and verifies the result.
Override the location with `CCSWITCH_BIN_DIR=/usr/local/bin ./install.sh`.

## Quickstart

```sh
ccswitch list                 # your current account shows up as "default"
ccswitch create work          # new profile (inherits your plugins/skills), then sign in
```

### Many accounts at once — the whole point

One account per terminal, as many as you like — all running simultaneously:

```sh
# Terminal A
ccswitch use work        # this shell → work account
claude                   # …runs as work

# Terminal B  (at the same time)
ccswitch use default     # this shell → your personal account
claude                   # …runs as personal

# Terminal C, D, …       # ccswitch use <profile> → and so on
```

Or launch one without touching your shell:

```sh
ccswitch run work                              # a claude session as 'work'
ccswitch run work -- -p "summarize this repo"  # pass args straight through
```

`ccswitch use` changes only the current shell; `ccswitch run` only that one
session. Either way the accounts never interfere.

## Commands

| Command | What it does |
|---|---|
| `list` / `ls` | Accounts + sign-in status (● = active in this shell) |
| `use <name>` | Point the current shell at a profile |
| `unuse` | Revert this shell to `default` |
| `run <name> [-- args]` | Launch a `claude` session as `<name>` |
| `current` | Show this shell's active profile |
| `create <name> [opts]` | New profile, then login |
| `login <name>` / `logout <name>` | Sign a profile in / out |
| `status [name]` | Detailed auth status |
| `sync <name> [dir]` | Re-copy `settings*.json` / `mcp_config.json` from `~/.claude` (or `dir`) |
| `remove <name> [-y] [--keep-creds]` | Delete a profile (signs it out first) |
| `rename <old> <new>` | Rename a profile (**requires re-login** afterward) |
| `doctor` | Health check |
| `help` / `help full` | Short help / full reference |

`create` options: `--isolated` (don't share any config), `--no-login`,
`--email <addr>`, `--share-from <dir>`, and `--console` / `--sso` / `--claudeai`
(passed through to `claude auth login`).

## How it works

A **profile** is an isolated Claude Code config directory (`CLAUDE_CONFIG_DIR`).
Claude Code stores each config dir's credentials in their own entry of the OS
credential store, so two shells pointed at two profiles are two accounts — at the
same time, with no clobbering. `default` is your existing `~/.claude`.

What a new profile inherits from `~/.claude`:

| | Items | Why |
|---|---|---|
| **Symlinked** (shared) | `plugins`, `skills`, `commands`, `hooks`, `CLAUDE.md` | read-mostly; every account gets your full setup |
| **Copied** (independent) | `settings.json`, `settings.local.json`, `mcp_config.json` | mutable at runtime — copying keeps concurrent accounts from racing; each can diverge. `ccswitch sync` re-copies |
| **Fresh** per profile | sessions, projects, history, credentials | identity/write-heavy state stays isolated |

> On platforms without symlink support (e.g. Git Bash without Developer Mode),
> the symlinked items are **copied** instead.

> **Custom hooks** are shared. If you run accounts concurrently, keep them
> account-agnostic — read per-profile state via `$CLAUDE_CONFIG_DIR` (set for the
> active profile), not hard-coded `~/.claude` paths.

## Security

- **ccswitch stores no secrets.** Tokens live in the OS credential store
  (macOS Keychain, or a per-profile credentials file on Linux/Windows), managed
  by Claude Code via `claude auth`. `~/.ccswitch` is `0700`; copied config files
  are `0600`.
- **`remove` is guarded:** signs the profile out first (`--keep-creds` skips),
  refuses symlinked profile dirs, refuses any path not under `~/.ccswitch/profiles`,
  and refuses `default`.
- **`rm -rf` guard:** `CCSWITCH_HOME` must be a real directory **under `$HOME`**,
  no `..`, not a symlink. Profile names are restricted to `[A-Za-z0-9._-]`.
- **rc edits are injection-safe** (`printf %q`, atomic rewrite), and the shell
  snippet is copied to `~/.ccswitch/shell/` so startup never runs code from the
  repo.
- **Trust assumption:** the installed `ccswitch` is a symlink back to this repo,
  so whoever can write the repo can run code as you. Keep it somewhere only you
  can write — the installer warns if the repo is group/other-writable.

## Uninstall

```sh
./uninstall.sh            # removes the CLI + rc lines; keeps your profiles
./uninstall.sh --purge    # also signs out every profile and deletes ~/.ccswitch
```

## License

MIT — see [LICENSE](LICENSE).
