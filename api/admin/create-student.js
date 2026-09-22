// POST /api/admin/create-student
// { schoolId, fullName, groupId?, moduleId, studentCode, email }
//
// Creates the student's auth account and her students row. The admin
// picks the student ID directly (at least 8 characters) rather than one
// being generated — it doubles as the starting password until the
// student sets their own on first sign-in. Email is required too:
// students sign in with it directly (supabase.auth.signInWithPassword),
// not by full name.

import { requireAdmin, serviceClient, rateLimit, clientIp, sendJson, HttpError, PW_MESSAGES } from "../_auth.js";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return sendJson(res, 405, { error: "Method not allowed." });
  }

  try {
    const admin = await requireAdmin(req);

    const ip = clientIp(req);
    if (!rateLimit(`admin-create-student:${admin.id}:${ip}`, { max: 30, windowMs: 5 * 60 * 1000 })) {
      return sendJson(res, 429, { error: "Too many attempts. Wait a few minutes and try again." });
    }

    const body = req.body || {};
    const schoolId = typeof body.schoolId === "string" ? body.schoolId : "";
    const fullName = typeof body.fullName === "string" ? body.fullName.trim() : "";
    const groupId = typeof body.groupId === "string" && body.groupId ? body.groupId : null;
    const moduleId = typeof body.moduleId === "string" ? body.moduleId : "";
    const studentCode = typeof body.studentCode === "string" ? body.studentCode.trim() : "";
    const email = typeof body.email === "string" && body.email.trim() ? body.email.trim() : null;

    if (!schoolId || !fullName || !moduleId || !studentCode || !email) {
      return sendJson(res, 400, { error: "School, student ID, email, full name, and module are required." });
    }

    const client = serviceClient();
    const { data, error } = await client.rpc("admin_create_student", {
      p_school_id: schoolId,
      p_full_name: fullName,
      p_group_id: groupId,
      p_module_id: moduleId,
      p_student_code: studentCode,
      p_email: email,
    });

    if (error) {
      return sendJson(res, 400, { error: PW_MESSAGES[error.code] || "Couldn't create the student." });
    }

    const row = Array.isArray(data) ? data[0] : data;
    return sendJson(res, 200, {
      id: row.id,
      studentCode: row.student_code,
      fullName,
    });
  } catch (err) {
    if (err instanceof HttpError) return sendJson(res, err.status, { error: err.message });
    return sendJson(res, 500, { error: "Something went wrong. Try again." });
  }
}
