import { createClient } from "@supabase/supabase-js";

export function serviceClient() {
  return createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

export class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

// Verifies the caller's own Supabase access token (sent from the browser) and
// that the matching coach is an active admin. Throws HttpError otherwise.
export async function requireAdmin(req) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) throw new HttpError(401, "Sign in required.");

  const client = serviceClient();
  const { data: userData, error: userError } = await client.auth.getUser(token);
  if (userError || !userData?.user) throw new HttpError(401, "Sign in required.");

  const { data: coach, error: coachError } = await client
    .from("coaches")
    .select("id, role, active")
    .eq("id", userData.user.id)
    .single();

  if (coachError || !coach || coach.role !== "admin" || !coach.active) {
    throw new HttpError(403, "Admin only.");
  }

  return coach;
}

// Coarse in-memory rate limiting. Serverless instances are short-lived and
// this map is not shared across them, so it's a speed bump, not a guarantee —
// adequate for a club-sized app with no external store in scope.
const hits = new Map();

export function rateLimit(key, { max, windowMs }) {
  const now = Date.now();
  const entry = hits.get(key);
  if (!entry || now - entry.start > windowMs) {
    hits.set(key, { start: now, count: 1 });
    return true;
  }
  entry.count += 1;
  return entry.count <= max;
}

export function clientIp(req) {
  const forwarded = req.headers["x-forwarded-for"];
  if (typeof forwarded === "string" && forwarded.length) {
    return forwarded.split(",")[0].trim();
  }
  return req.socket?.remoteAddress || "unknown";
}

export function sendJson(res, status, body) {
  res.status(status).json(body);
}
