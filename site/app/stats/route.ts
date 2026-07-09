import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { getRedis } from "@/lib/redis";

export const runtime = "edge";
export const dynamic = "force-dynamic";

// GET /stats → JSON download counters.
// If STATS_TOKEN is set, require ?token=… ; otherwise open (counts aren't secret).
export async function GET(req: NextRequest) {
  const gate = process.env.STATS_TOKEN;
  if (gate && req.nextUrl.searchParams.get("token") !== gate) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const redis = getRedis();
  if (!redis) {
    return NextResponse.json({ error: "counter not configured" }, { status: 503 });
  }

  const [installSh, binInstall, binUpdate, binCheck, binUntagged] = (
    await redis.mget<(number | null)[]>(
      "dl:install.sh",
      "dl:bin:install",
      "dl:bin:update",
      "dl:bin:check",
      "dl:bin:untagged",
    )
  ).map((n) => n ?? 0);

  // Last 30 days of fresh installs (dl:bin:install:YYYY-MM-DD) for a trend line.
  const now = Date.now();
  const days: string[] = [];
  for (let i = 29; i >= 0; i--) {
    days.push(new Date(now - i * 86_400_000).toISOString().slice(0, 10));
  }
  const daily = await redis.mget<(number | null)[]>(
    ...days.map((d) => `dl:bin:install:${d}`),
  );

  return NextResponse.json({
    installs: binInstall, // fresh web installs — the clean signal
    install_sh_hits: installSh, // curl of install.sh (installs + readers)
    updates: binUpdate,
    update_checks: binCheck,
    untagged: binUntagged, // pre-tagging clients / manual fetches
    install_daily: Object.fromEntries(days.map((d, i) => [d, daily[i] ?? 0])),
  });
}
