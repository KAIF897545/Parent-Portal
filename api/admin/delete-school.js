// POST /api/admin/delete-school
// { schoolId }
//
// Refuses to delete a school that still has any student or coach —
// admin_delete_school returns PW026 in that case rather than cascading
// through and destroying their records.

import { requireAdmin, serviceClient, rateLimit, clientIp, sendJson, HttpError, PW_MESSAGES } from "../_auth.js";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return sendJson(res, 405, { error: "Method not allowed." });
  }

  try {
    const admin = await requireAdmin(req);

    const ip = clientIp(req);
    if (!rateLimit(`admin-delete-school:${admin.id}:${ip}`, { max: 20, windowMs: 10 * 60 * 1000 })) {
      return sendJson(res, 429, { error: "Too many attempts. Wait a few minutes and try again." });
    }

    const body = req.body || {};
    const schoolId = typeof body.schoolId === "string" ? body.schoolId : "";
    if (!schoolId) {
      return sendJson(res, 400, { error: "schoolId is required." });
    }

    const client = serviceClient();
    const { error } = await client.rpc("admin_delete_school", { p_school_id: schoolId });

    if (error) {
      return sendJson(res, 400, { error: PW_MESSAGES[error.code] || "Couldn't delete the school." });
    }

    return sendJson(res, 200, { ok: true });
  } catch (err) {
    if (err instanceof HttpError) return sendJson(res, err.status, { error: err.message });
    return sendJson(res, 500, { error: "Something went wrong. Try again." });
  }
}
