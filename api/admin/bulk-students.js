// POST /api/admin/bulk-students
// { schoolId, rows: [{ fullName, category?, groupId?, moduleId }] }
//
// Creates each row server-side, one admin_create_student call per row, and
// returns the whole list — including every generated password — once.
// A row failing doesn't stop the rest; each result says ok or not.

import { requireAdmin, serviceClient, rateLimit, clientIp, sendJson, HttpError, PW_MESSAGES, randomPassword } from "../_auth.js";

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

      if (!fullName || !moduleId) {
        results.push({ fullName: fullName || "(blank)", ok: false, error: "Full name and module are required." });
        continue;
      }

      let ok = false;
      let lastCode = null;

      for (let i = 0; i < 5 && !ok; i++) {
        const password = randomPassword();
        const { data, error } = await client.rpc("admin_create_student", {
          p_school_id: schoolId,
          p_full_name: fullName,
          p_category: typeof row.category === "string" ? row.category : "",
          p_group_id: typeof row.groupId === "string" && row.groupId ? row.groupId : null,
          p_module_id: moduleId,
          p_password: password,
        });

        if (!error) {
          const r = Array.isArray(data) ? data[0] : data;
          results.push({ fullName, ok: true, studentCode: r.student_code, password });
          ok = true;
          break;
        }

        lastCode = error.code;
        if (error.code !== "PW004") break;
      }

      if (!ok) {
        results.push({ fullName, ok: false, error: PW_MESSAGES[lastCode] || "Couldn't create this student." });
      }
    }

    return sendJson(res, 200, { results });
  } catch (err) {
    if (err instanceof HttpError) return sendJson(res, err.status, { error: err.message });
    return sendJson(res, 500, { error: "Something went wrong. Try again." });
  }
}
