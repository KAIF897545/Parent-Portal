// POST /api/admin/set-student-email
// { studentId, email }
//
// Sets the email a student signs in and resets their password with.
// Can't be cleared to blank — that would leave the account with no way
// to sign in at all; use Deactivate for that instead. Goes through
// admin_set_student_email rather than a plain students.update() because
// it also has to update the matching auth.users/auth.identities row,
// which the browser can't reach directly.

import { requireAdmin, serviceClient, rateLimit, clientIp, sendJson, HttpError, PW_MESSAGES } from "../_auth.js";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return sendJson(res, 405, { error: "Method not allowed." });
  }

  try {
    const admin = await requireAdmin(req);

    const ip = clientIp(req);
    if (!rateLimit(`admin-set-student-email:${admin.id}:${ip}`, { max: 30, windowMs: 10 * 60 * 1000 })) {
      return sendJson(res, 429, { error: "Too many attempts. Wait a few minutes and try again." });
    }

    const body = req.body || {};
    const studentId = typeof body.studentId === "string" ? body.studentId : "";
    const email = typeof body.email === "string" ? body.email.trim() : "";
    if (!studentId) {
      return sendJson(res, 400, { error: "studentId is required." });
    }
    if (!email) {
      return sendJson(res, 400, { error: "Enter a valid email address." });
    }

    const client = serviceClient();
    const { error } = await client.rpc("admin_set_student_email", {
      p_student: studentId,
      p_email: email,
    });

    if (error) {
      return sendJson(res, 400, { error: PW_MESSAGES[error.code] || "Couldn't save that email." });
    }

    return sendJson(res, 200, { ok: true });
  } catch (err) {
    if (err instanceof HttpError) return sendJson(res, err.status, { error: err.message });
    return sendJson(res, 500, { error: "Something went wrong. Try again." });
  }
}
