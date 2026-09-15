// Small helpers shared by the dashboard pages.

export function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (c) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  }[c]));
}

// Parses a `date` column (YYYY-MM-DD) as a local date instead of UTC
// midnight, so it never prints a day early in timezones west of UTC.
function parseDateOnly(value) {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(value);
  return m ? new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3])) : new Date(value);
}

export function formatDate(value) {
  if (!value) return "";
  const d = parseDateOnly(value);
  if (Number.isNaN(d.getTime())) return String(value);
  return d.toLocaleDateString("en-GB", { day: "numeric", month: "short", year: "numeric" });
}

export function formatMonth(value) {
  if (!value) return "";
  const d = parseDateOnly(value);
  if (Number.isNaN(d.getTime())) return String(value);
  return d.toLocaleDateString("en-GB", { month: "long", year: "numeric" });
}
