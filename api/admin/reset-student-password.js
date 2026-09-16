// POST /api/admin/reset-student-password
// { studentId, password? }
//
// Calls admin_set_student_password, which always leaves must_change_password
// true so the student is forced through first-login again. If no password
// is supplied, one is generated and returned once.

import { requireAdmin, serviceClient, rateLimit, clientIp, sendJson, HttpError, PW_MESSAGES, randomPassword } from "../_auth.js";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return sendJson(res, 405, { error: "Method not allowed." });
  }

  try {
    const admin = await requireAdmin(req);

    const ip = clientIp(req);
    if (!rateLimit(`admin-reset-student-pw:${admin.id}:${ip}`, { max: 30, windowMs: 5 * 60 * 1000 })) {
      return sendJson(res, 429, { error: "Too many attempts. Wait a few minutes and try again." });
    }

    const body = req.body || {};
    const studentId = typeof body.studentId === "string" ? body.studentId : "";
    const requestedPassword = typeof body.password === "string" && body.password.trim() ? body.password.trim() : null;

    if (!studentId) {
      return sendJson(res, 400, { error: "studentId is required." });
    }

    const client = serviceClient();
    const attempts = requestedPassword ? 1 : 5;
    let lastCode = null;

    for (let i = 0; i < attempts; i++) {
      const password = requestedPassword || randomPassword();
      const { error } = await client.rpc("admin_set_student_password", {
        p_student: studentId,
        p_password: password,
      });

      if (!error) return sendJson(res, 200, { password });

      lastCode = error.code;
      if (error.code !== "PW004" || requestedPassword) break;
    }

    return sendJson(res, 400, { error: PW_MESSAGES[lastCode] || "Couldn't reset the password." });
  } catch (err) {
    if (err instanceof HttpError) return sendJson(res, err.status, { error: err.message });
    return sendJson(res, 500, { error: "Something went wrong. Try again." });
  }
}
