# ccdesktop — multiple Claude Desktop accounts (macOS)

Sibling to [`ccenv`](./README.md). `ccenv` runs multiple **Claude Code (CLI)**
accounts concurrently; `ccdesktop` does the same for the **Claude Desktop macOS
app**.

## Why it's a different mechanism

Claude Code isolation relies on `CLAUDE_CONFIG_DIR` + a per-config-dir Keychain
entry. Claude Desktop has **neither**:

| | Claude Code (CLI) | Claude Desktop |
|---|---|---|
| Config relocation | `CLAUDE_CONFIG_DIR` env var | none — fixed at `~/Library/Application Support/Claude` |
| Credential store | per-config-dir Keychain entry | one app-level `Claude Safe Storage` key; **session lives inside the user-data dir** (Cookies / Local Storage) |
| Concurrency | stateless per shell | Electron single-instance lock keyed to the user-data dir |

Because the login session lives *inside* the user-data directory, "two accounts
at once" reduces to **give each account its own user-data dir and let a second
instance run**. Electron honors Chromium's `--user-data-dir` flag, so:

```
open -n -a Claude --args --user-data-dir=<dir>
```

launches a separate instance with its own cookie jar (= its own account) and its
own MCP config. `ccdesktop` wraps that with profile management and safety guards.

## Usage

```
ccdesktop create work        # make a profile, launch it, sign in
ccdesktop create personal
ccdesktop open work          # later: relaunch that account
ccdesktop list               # profiles + which are running
ccdesktop running            # pids per profile
ccdesktop stop work          # quit one profile's instance
ccdesktop remove work        # delete the profile (you stay signed in elsewhere)
```

A profile is a `--user-data-dir` under `~/.ccdesktop/profiles/<name>`. `default`
(alias `main`) is the normal app at `~/Library/Application Support/Claude`. First
launch of a profile shows a fresh login screen; the session then persists in that
profile's directory. New profiles are seeded with a copy of your MCP config
(`claude_desktop_config.json`) unless you pass `--isolated`.

`ccdesktop` stores **zero credentials** — the login stays in the profile dir,
encrypted by the app's `Claude Safe Storage` Keychain key.

## Install

No shell integration needed (it launches the GUI, it doesn't mutate the parent
shell). Just put it on your `PATH`:

```
ln -s "$(pwd)/bin/ccdesktop" /usr/local/bin/ccdesktop   # or ~/.local/bin
```

Env overrides: `CCDESK_APP` (path to `Claude.app`), `CCDESK_HOME` (default
`~/.ccdesktop`), `CCDESK_BASE_DIR` (the app's base user-data dir).

## Known limitation

All managed profiles share **one Dock icon** (same app bundle) and can't be told
apart in ⌘-Tab. If distinct icons/names matter, clone `Claude.app` with a new
`CFBundleIdentifier` + name and re-sign ad-hoc — the "two WhatsApps" trick — at
the cost of re-cloning on every app update.
