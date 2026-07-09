import { NextResponse } from "next/server";
import type { NextRequest, NextFetchEvent } from "next/server";
import { getRedis } from "@/lib/redis";

// Count downloads of the install script and the ccenv binary. Runs before the
// static file is served, then falls through (NextResponse.next()) so serving is
// untouched. Counting is fire-and-forget via event.waitUntil, so it adds no
// latency to the curl and never breaks a download if Redis is slow/down.
//
// /bin/ccenv is fetched by three distinct flows, disambiguated by the ?e= tag
// the client sends:  install  (fresh web install, from install.sh)
//                    update   (`ccenv update`)
//                    check    (`ccenv update --check`)
// Requests with no/unknown tag (older clients, manual curls) count as "untagged".
// /install.sh is the fresh-web-install entry point — also hit by people who curl
// it just to read the script, so treat it as install *intent*, not a clean count.
export function middleware(req: NextRequest, event: NextFetchEvent) {
  const redis = getRedis();
  if (redis) {
    const { pathname, searchParams } = req.nextUrl;
    const kind =
      pathname === "/install.sh"
        ? "install.sh"
        : `bin:${tag(searchParams.get("e")) ?? "untagged"}`;
    const day = new Date().toISOString().slice(0, 10); // UTC YYYY-MM-DD
    event.waitUntil(
      redis
        .pipeline()
        .incr(`dl:${kind}`) // running total
        .incr(`dl:${kind}:${day}`) // per-day bucket for trend lines
        .exec()
        .catch(() => {}),
    );
  }
  return NextResponse.next();
}

// Allowlist the tag so ?e= can't inject arbitrary Redis keys.
function tag(e: string | null): string | null {
  return e && ["install", "update", "check"].includes(e) ? e : null;
}

export const config = {
  // Scope tight: middleware runs ONLY for these two paths.
  matcher: ["/install.sh", "/bin/ccenv"],
};
