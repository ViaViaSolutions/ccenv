import { Redis } from "@upstash/redis";

// Single shared Upstash client. Reads UPSTASH_REDIS_REST_URL and
// UPSTASH_REDIS_REST_TOKEN from the environment (provisioned by the Vercel ↔
// Upstash marketplace integration). Returns null when those are unset — e.g.
// local dev — so callers can no-op instead of crashing.
let client: Redis | null = null;

export function getRedis(): Redis | null {
  if (client) return client;
  // The Vercel ↔ Upstash marketplace integration injects the REST creds under
  // one of two naming schemes depending on how the store was connected. Accept
  // either so it works regardless of which one Vercel picked.
  const url =
    process.env.UPSTASH_REDIS_REST_URL ?? process.env.KV_REST_API_URL;
  const token =
    process.env.UPSTASH_REDIS_REST_TOKEN ?? process.env.KV_REST_API_TOKEN;
  if (!url || !token) return null;
  client = new Redis({ url, token });
  return client;
}
