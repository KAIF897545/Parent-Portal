// POST /api/admin/bulk-students
// { schoolId, rows: [{ fullName, studentCode, email, groupId? }] }
//
// Creates each row server-side, one admin_create_student call per row, and
// returns the whole list once. A row failing doesn't stop the rest; each
// result says ok or not. studentCode doubles as the starting password.

import { requireAdmin, serviceClient, rateLimit, clientIp, sendJson, HttpError, PW_MESSAGES } from "../_auth.js";

const MAX_ROWS = 100;

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return sendJson(res, 405, { error: "Method not allowed." });
  }

  try {
    const admin = await requireAdmin(req);

    const ip = clientIp(req);
    if (!rateLimit(`admin-bulk-students:${admin.id}:${ip}`, { max: 10, windowMs: 10 * 60 * 1000 })) {
      return sendJson(res, 429, { error: "Too many attempts. Wait a few minutes and try again." });
    }

    const body = req.body || {};
    const schoolId = typeof body.schoolId === "string" ? body.schoolId : "";
    const rows = Array.isArray(body.rows) ? body.rows : [];

    if (!schoolId || rows.length === 0) {
      return sendJson(res, 400, { error: "School and at least one row are required." });
    }
    if (rows.length > MAX_ROWS) {
      return sendJson(res, 400, { error: `Bulk add is limited to ${MAX_ROWS} students at a time.` });
    }

    const client = serviceClient();
    const results = [];

    for (const row of rows) {
      const fullName = typeof row?.fullName === "string" ? row.fullName.trim() : "";
      const moduleId = typeof row?.moduleId === "string" ? row.moduleId : "";
      const studentCode = typeof row?.studentCode === "string" ? row.studentCode.trim() : "";
      const email = typeof row?.email === "string" ? row.email.trim() : "";

      if (!fullName || !moduleId || !studentCode || !email) {
        results.push({
          fullName: fullName || "(blank)",
          ok: false,
          error: "Student ID, email, full name, and module are required.",
        });
        continue;
      }

      const { data, error } = await client.rpc("admin_create_student", {
        p_school_id: schoolId,
        p_full_name: fullName,
        p_group_id: typeof row.groupId === "string" && row.groupId ? row.groupId : null,
        p_module_id: moduleId,
        p_student_code: studentCode,
        p_email: email,
      });

      if (error) {
        results.push({ fullName, ok: false, error: PW_MESSAGES[error.code] || "Couldn't create this student." });
        continue;
      }

      const r = Array.isArray(data) ? data[0] : data;
      results.push({ fullName, ok: true, studentCode: r.student_code });
    }

    return sendJson(res, 200, { results });
  } catch (err) {
    if (err instanceof HttpError) return sendJson(res, err.status, { error: err.message });
    return sendJson(res, 500, { error: "Something went wrong. Try again." });
  }
}
