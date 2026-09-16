// POST /api/admin/create-coach
// { email, name, role, schoolId?, password? }
//
// role is "coach" (schoolId required) or "admin" (schoolId must be absent).
// If no password is supplied, one is generated and returned once — coaches
// never get a self-service way to change it; only the admin ever sets it.

import { requireAdmin, serviceClient, rateLimit, clientIp, sendJson, HttpError, PW_MESSAGES, randomPassword } from "../_auth.js";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return sendJson(res, 405, { error: "Method not allowed." });
  }

  try {
    const admin = await requireAdmin(req);

    const ip = clientIp(req);
    if (!rateLimit(`admin-create-coach:${admin.id}:${ip}`, { max: 20, windowMs: 5 * 60 * 1000 })) {
      return sendJson(res, 429, { error: "Too many attempts. Wait a few minutes and try again." });
    }

    const body = req.body || {};
    const email = typeof body.email === "string" ? body.email.trim() : "";
    const name = typeof body.name === "string" ? body.name.trim() : "";
    const role = body.role === "admin" ? "admin" : "coach";
    const schoolId = typeof body.schoolId === "string" && body.schoolId ? body.schoolId : null;
    const requestedPassword = typeof body.password === "string" && body.password.trim() ? body.password.trim() : null;

    if (!email || !name) {
      return sendJson(res, 400, { error: "Email and name are required." });
    }

    const client = serviceClient();
    const attempts = requestedPassword ? 1 : 5;
    let lastCode = null;

    for (let i = 0; i < attempts; i++) {
      const password = requestedPassword || randomPassword();
      const { data, error } = await client.rpc("admin_create_coach", {
        p_email: email,
        p_name: name,
        p_role: role,
        p_school_id: schoolId,
        p_password: password,
      });

      if (!error) {
        const row = Array.isArray(data) ? data[0] : data;
        return sendJson(res, 200, { id: row.id, email, name, role, password });
      }

      lastCode = error.code;
      if (error.code !== "PW004" || requestedPassword) break;
    }

    return sendJson(res, 400, { error: PW_MESSAGES[lastCode] || "Couldn't create the account." });
  } catch (err) {
    if (err instanceof HttpError) return sendJson(res, err.status, { error: err.message });
    return sendJson(res, 500, { error: "Something went wrong. Try again." });
  }
}
