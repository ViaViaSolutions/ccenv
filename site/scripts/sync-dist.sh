#!/usr/bin/env bash
# Copy the installable artifacts from the repo root into site/public/ so they are
# served at ccenv.dev/{install.sh,uninstall.sh,bin/ccenv,shell/ccenv.sh}.
#
# Runs automatically before `next dev` / `next build` (see package.json), so the
# hosted copies never drift from the real scripts. Safe to run by hand too.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd -P)"
root="$(cd "$here/../.." && pwd -P)"
pub="$here/../public"

# If the repo sources aren't in this build context (e.g. a site-only deploy that
# only checks out site/), don't fail — fall back to the copies already committed
# under public/ so the deploy still serves a valid install.sh.
if [ ! -f "$root/bin/ccenv" ]; then
  if [ -f "$pub/bin/ccenv" ] && [ -f "$pub/install.sh" ]; then
    echo "sync-dist: repo sources not found at $root — keeping committed public/ copies" >&2
    exit 0
  fi
  echo "sync-dist: repo sources not found at $root and no committed public/ copies — cannot proceed" >&2
  exit 1
fi

mkdir -p "$pub/bin" "$pub/shell"
cp "$root/bin/ccenv"      "$pub/bin/ccenv"
cp "$root/shell/ccenv.sh" "$pub/shell/ccenv.sh"
cp "$root/install.sh"     "$pub/install.sh"
cp "$root/uninstall.sh"   "$pub/uninstall.sh"

# Publish the current version as a tiny file so `ccenv` can check for updates
# (served at ccenv.dev/version) without downloading the whole ~40KB binary.
grep -m1 'CCENV_VERSION=' "$root/bin/ccenv" | sed -E 's/.*"([^"]+)".*/\1/' > "$pub/version"

echo "sync-dist: install.sh, uninstall.sh, bin/ccenv, shell/ccenv.sh, version → public/"
