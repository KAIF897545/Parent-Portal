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

// `value` here is a real instant (a timestamptz column, e.g. attendance's
// marked_at), not a date-only string, so it's rendered directly in
// Maldives time (UTC+5, no DST) rather than going through parseDateOnly.
export function maldivesDateParts(value) {
  if (!value) return { date: "", time: "" };
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return { date: "", time: "" };
  const date = d.toLocaleDateString("en-GB", {
    day: "numeric",
    month: "short",
    year: "numeric",
    timeZone: "Indian/Maldives",
  });
  const time = d
    .toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit", timeZone: "Indian/Maldives" })
    .toLowerCase();
  return { date, time };
}

export function formatDateTime(value) {
  const { date, time } = maldivesDateParts(value);
  return date ? `${date}, ${time}` : "";
}

// Adds a Show/Hide button to every password input on the page, so typed
// passwords don't have to stay hidden behind dots to be checked.
export function enablePasswordToggles() {
  document.querySelectorAll('input[type="password"]').forEach((input) => {
    if (input.dataset.toggleWired) return;
    input.dataset.toggleWired = "true";

    const wrap = document.createElement("div");
    wrap.className = "field__password-wrap";
    input.parentNode.insertBefore(wrap, input);
    wrap.appendChild(input);

    const toggle = document.createElement("button");
    toggle.type = "button";
    toggle.className = "field__toggle-visibility";
    toggle.textContent = "Show";
    toggle.setAttribute("aria-label", "Show password");
    wrap.appendChild(toggle);

    toggle.addEventListener("click", () => {
      const showing = input.type === "text";
      input.type = showing ? "password" : "text";
      toggle.textContent = showing ? "Show" : "Hide";
      toggle.setAttribute("aria-label", showing ? "Show password" : "Hide password");
    });
  });
}
