// POST /api/admin/delete-coach
// { coachId }
//
// Permanent. Blocked (PW027) if the coach has ever marked attendance,
// ticks, checkpoints, feedback, or notes — that history stays with the
// students it belongs to, so deleting is only for an account that was
// never used. Deactivating a coach (which keeps them if they have any
// activity) does not go through this endpoint at all; it's a plain table
// update from the browser.

import { requireAdmin, serviceClient, rateLimit, clientIp, sendJson, HttpError, PW_MESSAGES } from "../_auth.js";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return sendJson(res, 405, { error: "Method not allowed." });
  }

  try {
    const admin = await requireAdmin(req);

    const ip = clientIp(req);
    if (!rateLimit(`admin-delete-coach:${admin.id}:${ip}`, { max: 20, windowMs: 10 * 60 * 1000 })) {
      return sendJson(res, 429, { error: "Too many attempts. Wait a few minutes and try again." });
    }

    const body = req.body || {};
    const coachId = typeof body.coachId === "string" ? body.coachId : "";
    if (!coachId) {
      return sendJson(res, 400, { error: "coachId is required." });
    }
    if (coachId === admin.id) {
      return sendJson(res, 400, { error: "You can't delete your own account." });
    }

    const client = serviceClient();
    const { error } = await client.rpc("admin_delete_coach", { p_coach_id: coachId });

    if (error) {
      return sendJson(res, 400, { error: PW_MESSAGES[error.code] || "Couldn't delete the coach." });
    }

    return sendJson(res, 200, { ok: true });
  } catch (err) {
    if (err instanceof HttpError) return sendJson(res, err.status, { error: err.message });
    return sendJson(res, 500, { error: "Something went wrong. Try again." });
  }
}
