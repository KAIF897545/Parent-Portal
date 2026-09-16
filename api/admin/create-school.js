// POST /api/admin/create-school
// { name, location?, prefix, groups?: string[] }

import { requireAdmin, serviceClient, rateLimit, clientIp, sendJson, HttpError, PW_MESSAGES } from "../_auth.js";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return sendJson(res, 405, { error: "Method not allowed." });
  }

  try {
    const admin = await requireAdmin(req);

    const ip = clientIp(req);
    if (!rateLimit(`admin-create-school:${admin.id}:${ip}`, { max: 10, windowMs: 10 * 60 * 1000 })) {
      return sendJson(res, 429, { error: "Too many attempts. Wait a few minutes and try again." });
    }

    const body = req.body || {};
    const name = typeof body.name === "string" ? body.name.trim() : "";
    const location = typeof body.location === "string" ? body.location : "";
    const prefix = typeof body.prefix === "string" ? body.prefix : "";
    const groups = Array.isArray(body.groups)
      ? body.groups.filter((g) => typeof g === "string" && g.trim())
      : [];

    if (!name || !prefix) {
      return sendJson(res, 400, { error: "Name and prefix are required." });
    }

    const client = serviceClient();
    const { data, error } = await client.rpc("admin_create_school", {
      p_name: name,
      p_location: location,
      p_prefix: prefix,
      p_groups: groups,
    });

    if (error) {
      return sendJson(res, 400, { error: PW_MESSAGES[error.code] || "Couldn't create the school." });
    }

    const row = Array.isArray(data) ? data[0] : data;
    return sendJson(res, 200, { id: row.id });
  } catch (err) {
    if (err instanceof HttpError) return sendJson(res, err.status, { error: err.message });
    return sendJson(res, 500, { error: "Something went wrong. Try again." });
  }
}
