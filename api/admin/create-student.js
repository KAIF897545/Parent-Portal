// POST /api/admin/create-student
// { schoolId, fullName, groupId?, moduleId, password?, email? }
//
// Creates the student's auth account and her students row. If no password
// is supplied, one is generated and returned once — there is no way to
// look it up afterwards. If no email is supplied, the account gets a
// synthetic placeholder instead; a real email lets the student use
// "Forgot password?" on the sign-in page later.

import { requireAdmin, serviceClient, rateLimit, clientIp, sendJson, HttpError, PW_MESSAGES, randomPassword } from "../_auth.js";

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
    const requestedPassword = typeof body.password === "string" && body.password.trim() ? body.password.trim() : null;
    const email = typeof body.email === "string" && body.email.trim() ? body.email.trim() : null;

    if (!schoolId || !fullName || !moduleId) {
      return sendJson(res, 400, { error: "School, full name, and module are required." });
    }

    const client = serviceClient();
    const attempts = requestedPassword ? 1 : 5;
    let lastCode = null;

    for (let i = 0; i < attempts; i++) {
      const password = requestedPassword || randomPassword();
      const { data, error } = await client.rpc("admin_create_student", {
        p_school_id: schoolId,
        p_full_name: fullName,
        p_group_id: groupId,
        p_module_id: moduleId,
        p_password: password,
        p_email: email,
      });

      if (!error) {
        const row = Array.isArray(data) ? data[0] : data;
        return sendJson(res, 200, {
          id: row.id,
          studentCode: row.student_code,
          fullName,
          password,
        });
      }

      lastCode = error.code;
      // Only worth retrying with a fresh random password on a collision;
      // any other rejection (bad school, bad module, taken email...) won't change.
      if (error.code !== "PW004" || requestedPassword) break;
    }

    return sendJson(res, 400, { error: PW_MESSAGES[lastCode] || "Couldn't create the student." });
  } catch (err) {
    if (err instanceof HttpError) return sendJson(res, err.status, { error: err.message });
    return sendJson(res, 500, { error: "Something went wrong. Try again." });
  }
}
