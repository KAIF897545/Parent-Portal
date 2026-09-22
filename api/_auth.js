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

// Maps the PWxxx errcodes raised by the SQL functions in 002_functions.sql
// to the message shown to the admin. PW004 always renders as exactly
// "Password rejected." — a fuller message would confirm that some other
// account uses that string.
export const PW_MESSAGES = {
  PW001: "Password must be at least 8 characters.",
  PW004: "Password rejected.",
  PW007: "Unknown student.",
  PW008: "Unknown coach.",
  PW009: "Unknown school.",
  PW015: "Full name is required.",
  PW016: "Unknown module.",
  PW017: "Unknown group for that school.",
  PW018: "Enter a valid email address.",
  PW019: "That email is already in use.",
  PW020: "Role must be coach or admin.",
  PW021: "Choose a school for this coach.",
  PW022: "Admins don't belong to a school.",
  PW023: "School name is required.",
  PW024: "Prefix must be 2 to 6 letters.",
  PW025: "That prefix is already in use.",
  PW026: "Remove every student and coach from this school before deleting it.",
  PW027: "This coach has recorded activity. Deactivate them instead of deleting.",
  PW028: "Coaches can only change a student's group.",
  PW029: 'That email is already used by another account. For siblings on one email, try a "+" alias (e.g. name+child2@gmail.com) — it still reaches the same inbox.',
  PW030: "Student ID must be at least 8 characters — it also becomes their starting password.",
  PW031: "That student ID is already in use at this school.",
};

// Chess/Maldives-themed word + 4 digits, matching the passwords already
// seeded for test accounts. Not shown to anyone but the admin, once.
const PASSWORD_WORDS = [
  "knight", "bishop", "castle", "gambit", "endgame",
  "opening", "tactic", "island", "atoll", "lagoon",
];

export function randomPassword() {
  const word = PASSWORD_WORDS[Math.floor(Math.random() * PASSWORD_WORDS.length)];
  const digits = String(Math.floor(1000 + Math.random() * 9000));
  return word + digits;
}
