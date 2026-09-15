import { serviceClient, rateLimit, clientIp, sendJson } from "./_auth.js";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return sendJson(res, 405, { error: "Method not allowed." });
  }

  const ip = clientIp(req);
  if (!rateLimit(`resolve-login:${ip}`, { max: 20, windowMs: 5 * 60 * 1000 })) {
    return sendJson(res, 429, { error: "Too many attempts. Wait a few minutes and try again." });
  }

  const body = req.body || {};
  const school = typeof body.school === "string" ? body.school : "";
  const name = typeof body.name === "string" ? body.name : "";
  const password = typeof body.password === "string" ? body.password : "";
  const studentCode = typeof body.student_code === "string" && body.student_code.trim()
    ? body.student_code
    : null;

  if (!school || !name.trim() || !password) {
    return sendJson(res, 400, { error: "Enter your name and password." });
  }

  const client = serviceClient();
  const { data, error } = await client.rpc("resolve_login", {
    p_school: school,
    p_name: name,
    p_password: password,
    p_student_code: studentCode,
  });

  if (error) {
    return sendJson(res, 500, { error: "Something went wrong. Try again." });
  }

  const row = Array.isArray(data) ? data[0] : data;
  const status = row?.status;

  if (status === "ok") {
    return sendJson(res, 200, { email: row.email });
  }
  if (status === "ambiguous") {
    return sendJson(res, 409, { ambiguous: true });
  }
  return sendJson(res, 401, { error: "Name or password not recognised. Ask your coach for help." });
}
