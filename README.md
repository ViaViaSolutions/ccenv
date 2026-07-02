# ccenv

Run multiple **Claude Code** accounts from one machine — switch in a keystroke,
and keep **as many accounts signed in at once as you have terminals**, each on
its own account.

```
$ ccenv list
● default    johndoe@gmail.com       max
  work       me@company.com          team
  client     not signed in
```

`● = active in this shell`

- **Concurrent, not just switchable** — personal in one terminal, work in
  another, a client in a third… all live at once, no clobbering. No fixed limit.
- **Secure** — ccenv stores zero secrets; tokens stay in the OS credential
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
curl -fsSL https://ccenv.dev/install.sh | bash
# then activate in the current shell (new terminals do this automatically):
source ~/.zshrc      # macOS (zsh)
# source ~/.bashrc   # Linux / Git Bash
```

One line, no clone, no build step — the script downloads the `ccenv` binary and
shell snippet from `ccenv.dev` and installs them per-user (no sudo). Needs
`curl` (or `wget`) and [Claude Code](https://claude.com/claude-code) on your
`PATH`. Re-run any time to update.

<details>
<summary>From a clone instead</summary>

```sh
git clone https://github.com/westdabestdb/ccenv ccenv && cd ccenv
./install.sh
```

A clone install **symlinks** `ccenv` back to the repo (so `git pull` updates it);
the web install **copies** it. Same wiring otherwise.
</details>

`install.sh` is idempotent: it puts `ccenv` on your `PATH` (preferring a dir
already on it, e.g. `~/.local/bin`, and only touching your rc if none is found),
adds one line for the `use`/`unuse` shell integration, and verifies the result.
Override the bin dir with `CCENV_BIN_DIR=/usr/local/bin`, or the download origin
with `CCENV_BASE_URL=https://ccenv.dev`.

## Quickstart

```sh
ccenv list                 # your current account shows up as "default"
ccenv create work          # new profile (inherits your plugins/skills), then sign in
```

### Many accounts at once — the whole point

One account per terminal, as many as you like — all running simultaneously:

```sh
# Terminal A
ccenv use work        # this shell → work account
claude                   # …runs as work

# Terminal B  (at the same time)
ccenv use default     # this shell → your personal account
claude                   # …runs as personal

# Terminal C, D, …       # ccenv use <profile> → and so on
```

Or launch one without touching your shell:

```sh
ccenv run work                              # a claude session as 'work'
ccenv run work -- -p "summarize this repo"  # pass args straight through
```

`ccenv use` changes only the current shell; `ccenv run` only that one
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
| `update [--check] [--force]` | Fetch the latest build and swap it in (clone installs `git pull`) |
| `uninstall [--purge] [-y]` | Remove ccenv itself (`--purge` also deletes profiles) |
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
| **Copied** (independent) | `settings.json`, `settings.local.json`, `mcp_config.json` | mutable at runtime — copying keeps concurrent accounts from racing; each can diverge. `ccenv sync` re-copies |
| **Fresh** per profile | sessions, projects, history, credentials | identity/write-heavy state stays isolated |

> On platforms without symlink support (e.g. Git Bash without Developer Mode),
> the symlinked items are **copied** instead.

> **Custom hooks** are shared. If you run accounts concurrently, keep them
> account-agnostic — read per-profile state via `$CLAUDE_CONFIG_DIR` (set for the
> active profile), not hard-coded `~/.claude` paths.

## Security

- **ccenv stores no secrets.** Tokens live in the OS credential store
  (macOS Keychain, or a per-profile credentials file on Linux/Windows), managed
  by Claude Code via `claude auth`. `~/.ccenv` is `0700`; copied config files
  are `0600`.
- **`remove` is guarded:** signs the profile out first (`--keep-creds` skips),
  refuses symlinked profile dirs, refuses any path not under `~/.ccenv/profiles`,
  and refuses `default`.
- **`rm -rf` guard:** `CCENV_HOME` must be a real directory **under `$HOME`**,
  no `..`, not a symlink. Profile names are restricted to `[A-Za-z0-9._-]`.
- **rc edits are injection-safe** (`printf %q`, atomic rewrite), and the shell
  snippet is copied to `~/.ccenv/shell/` so startup never runs code from the
  repo.
- **Web install fetches over HTTPS.** `install.sh` pulls the binary and shell
  snippet from `ccenv.dev` and refuses to install anything that doesn't look like
  the expected script (guards against truncated downloads / error pages). Pin the
  origin with `CCENV_BASE_URL` if you self-host.
- **Trust assumption:** a clone install symlinks `ccenv` back to the repo, so
  whoever can write the repo can run code as you. Keep it somewhere only you can
  write — the installer warns if the repo is group/other-writable. (A web install
  copies the binary instead, so there's no repo to protect.)

## Update

```sh
ccenv update           # fetch the latest build and swap it in
ccenv update --check   # just report the available version
```

`update` always fetches the newest `ccenv` from `ccenv.dev`, verifies it, and
atomically replaces the running binary (safe — rename swaps the directory entry,
not the inode the process is reading). For a clone install the PATH symlink is
replaced with the downloaded copy; your repo working tree is left untouched.
Override the origin with `CCENV_BASE_URL` (handy for testing a preview deploy).

## Uninstall

```sh
ccenv uninstall            # removes the CLI + rc lines; keeps your profiles
ccenv uninstall --purge    # also signs out every profile and deletes ~/.ccenv
```

Works from anywhere — no repo needed. Add `-y` to skip the confirmation. A clone
is never deleted (symlink installs print its location). Equivalent forms:
`./uninstall.sh [--purge] [-y]` from a clone, or
`curl -fsSL https://ccenv.dev/uninstall.sh | bash -s -- --purge`.

## License

MIT — see [LICENSE](LICENSE).
