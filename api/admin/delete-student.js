// POST /api/admin/delete-student
// { studentId }
//
// Permanent. Wipes the student's ticks, checkpoint evidence, feedback and
// coach notes, then deletes the account itself. There is no undo — the
// admin panel warns before calling this. Deactivating a student (which
// keeps their history) does not go through this endpoint at all; it's a
// plain table update from the browser.

import { requireAdmin, serviceClient, rateLimit, clientIp, sendJson, HttpError, PW_MESSAGES } from "../_auth.js";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return sendJson(res, 405, { error: "Method not allowed." });
  }

  try {
    const admin = await requireAdmin(req);

    const ip = clientIp(req);
    if (!rateLimit(`admin-delete-student:${admin.id}:${ip}`, { max: 20, windowMs: 10 * 60 * 1000 })) {
      return sendJson(res, 429, { error: "Too many attempts. Wait a few minutes and try again." });
    }

    const body = req.body || {};
    const studentId = typeof body.studentId === "string" ? body.studentId : "";
    if (!studentId) {
      return sendJson(res, 400, { error: "studentId is required." });
    }

    const client = serviceClient();
    const { error } = await client.rpc("admin_delete_student", { p_student_id: studentId });

    if (error) {
      return sendJson(res, 400, { error: PW_MESSAGES[error.code] || "Couldn't delete the student." });
    }

    return sendJson(res, 200, { ok: true });
  } catch (err) {
    if (err instanceof HttpError) return sendJson(res, err.status, { error: err.message });
    return sendJson(res, 500, { error: "Something went wrong. Try again." });
  }
}
