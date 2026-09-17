import { supabase } from "./supabase.js";
import { escapeHtml, formatDate, formatMonth, initials, feedbackCalendarHtml } from "./utils.js";

// All feedback for the signed-in student, and the month-picker calendar's
// current view — both are module-scoped since the calendar filters the
// list in place rather than re-fetching.
let fbRows = [];
let fbCalYear = null;
let fbSelectedMonth = null;

function setStatus(text, kind) {
  const box = document.getElementById("status");
  box.textContent = text;
  box.className = kind ? `form-message form-message--${kind}` : "form-message";
}

function ringSvg(pct) {
  const r = 52;
  const c = 2 * Math.PI * r;
  const off = c * (1 - pct / 100);
  return `<svg width="130" height="130" viewBox="0 0 130 130" role="img" aria-label="${pct} percent of this module signed off">
    <circle cx="65" cy="65" r="${r}" fill="none" stroke="rgba(247,241,232,.22)" stroke-width="11"/>
    <circle cx="65" cy="65" r="${r}" fill="none" stroke="#b00f2e" stroke-width="11" stroke-linecap="round"
      stroke-dasharray="${c}" stroke-dashoffset="${off}" transform="rotate(-90 65 65)"/>
    <text x="65" y="72" text-anchor="middle" font-family="Newsreader, Georgia, serif" font-size="28" fill="#f7f1e8">${pct}%</text>
  </svg>`;
}

function moduleTotals(unitList, tickSet) {
  let done = 0;
  let total = 0;
  for (const u of unitList) {
    total += u.items.length;
    done += u.items.filter((it) => tickSet.has(it.id)).length;
  }
  return { done, total, pct: total ? Math.round((done / total) * 100) : 0 };
}

function renderRing(student, unitList, tickSet, cpSet) {
  const prog = moduleTotals(unitList, tickSet);
  const cpTotal = unitList.filter((u) => u.checkpoint).length;
  const cpDone = unitList.filter((u) => u.checkpoint && cpSet.has(u.checkpoint.id)).length;

  const card = document.getElementById("ringCard");
  card.hidden = false;
  card.innerHTML = `
    <span class="ring-card__mark" aria-hidden="true">♞</span>
    <div class="ring-card__ring">${ringSvg(prog.pct)}</div>
    <div class="ring-card__text">
      <div class="mod">${escapeHtml(student.module?.name ?? "")}</div>
      <div class="sub">Module ${student.module?.number ?? ""}</div>
      <div class="ring-card__counts">
        <div><span>Signed off</span><b>${prog.done} of ${prog.total}</b></div>
        <div><span>Checkpoints</span><b>${cpDone} of ${cpTotal}</b></div>
      </div>
    </div>`;
}

function renderBadges(unitList, cpSet) {
  const withCheckpoint = unitList.filter((u) => u.checkpoint);
  const earned = withCheckpoint.filter((u) => cpSet.has(u.checkpoint.id)).length;
  const summary = document.getElementById("badgeSummary");
  if (summary) summary.textContent = `${earned} of ${withCheckpoint.length} earned`;

  document.getElementById("badgeRow").innerHTML = unitList
    .map((u, i) => {
      const got = u.checkpoint && cpSet.has(u.checkpoint.id);
      const shortLabel = (u.number.split(".")[1] || "?").trim();
      return `<span class="badge${got ? "" : " is-locked"}" style="animation-delay:${i * 40}ms">
        <span class="badge__mark">${got ? "✓" : escapeHtml(shortLabel)}</span>
        ${escapeHtml(u.name)}
      </span>`;
    })
    .join("");
}

function renderNextUp(unitList, tickSet) {
  const next = [];
  outer: for (const u of unitList) {
    for (const it of u.items) {
      if (next.length >= 3) break outer;
      if (!tickSet.has(it.id)) next.push(it.description);
    }
  }
  const box = document.getElementById("nextUp");
  box.innerHTML = next.length
    ? `<h3>Working towards</h3><ol>${next.map((t) => `<li>${escapeHtml(t)}</li>`).join("")}</ol>`
    : `<h3>Module complete</h3><p class="field__hint">Everything in this module is signed off. Ask your coach about moving up.</p>`;
}

function renderFeedbackCal() {
  const box = document.getElementById("feedbackCal");
  if (!box) return;
  box.hidden = fbRows.length === 0;
  if (!fbRows.length) return;
  box.innerHTML = feedbackCalendarHtml(fbRows, fbCalYear, fbSelectedMonth);
}

function renderFeedbackList() {
  const rows = fbSelectedMonth ? fbRows.filter((f) => String(f.month).slice(0, 7) === fbSelectedMonth) : fbRows;

  const summary = document.getElementById("feedbackSummary");
  if (summary) summary.textContent = fbRows.length ? `${fbRows.length} note${fbRows.length === 1 ? "" : "s"}` : "";

  const box = document.getElementById("feedbackList");
  if (rows.length) {
    box.innerHTML = rows
      .map((f, i) => {
        const stars = f.rating
          ? `<div class="feedback-card__rating" aria-label="${f.rating} out of 5 stars">
              <span class="feedback-card__stars">${"★".repeat(f.rating)}${"☆".repeat(5 - f.rating)}</span>
            </div>`
          : "";
        const highlight = f.highlight
          ? `<div class="feedback-card__tag feedback-card__tag--highlight">
              <span class="feedback-card__tag-icon" aria-hidden="true">🏆</span>
              <div class="feedback-card__tag-body">
                <span class="feedback-card__tag-label">This month's highlight</span>
                <span>${escapeHtml(f.highlight)}</span>
              </div>
            </div>`
          : "";
        const nextFocus = f.next_focus
          ? `<div class="feedback-card__tag feedback-card__tag--focus">
              <span class="feedback-card__tag-icon" aria-hidden="true">🎯</span>
              <div class="feedback-card__tag-body">
                <span class="feedback-card__tag-label">Next month's target</span>
                <span>${escapeHtml(f.next_focus)}</span>
              </div>
            </div>`
          : "";
        return `<div class="feedback-card" style="animation-delay:${i * 60}ms">
          <div class="feedback-card__top">
            <div class="feedback-card__month">${formatMonth(f.month)}</div>
            ${stars}
          </div>
          ${highlight}
          <div class="feedback-card__label">Feedback</div>
          <div class="feedback-card__text">${escapeHtml(f.body)}</div>
          ${nextFocus}
          <div class="feedback-card__when">Written ${formatDate(f.created_at)}</div>
        </div>`;
      })
      .join("");
  } else if (fbRows.length) {
    box.innerHTML = `<div class="feedback-card">No feedback for ${escapeHtml(
      formatMonth(`${fbSelectedMonth}-01`)
    )}.</div>`;
  } else {
    box.innerHTML = `<div class="feedback-card">Your coach writes a summary at the end of each month. Your first one will appear here.</div>`;
  }
}

function renderFeedback(rows) {
  fbRows = rows || [];
  fbCalYear = fbRows.length ? Number(String(fbRows[0].month).slice(0, 4)) : new Date().getFullYear();
  fbSelectedMonth = null;
  renderFeedbackCal();
  renderFeedbackList();
}

document.getElementById("feedbackCal")?.addEventListener("click", (e) => {
  const monthBtn = e.target.closest("[data-fbcal-month]");
  if (monthBtn && !monthBtn.disabled) {
    const key = monthBtn.getAttribute("data-fbcal-month");
    fbSelectedMonth = fbSelectedMonth === key ? null : key;
    renderFeedbackCal();
    renderFeedbackList();
    return;
  }
  if (e.target.closest("[data-fbcal-clear]")) {
    fbSelectedMonth = null;
    renderFeedbackCal();
    renderFeedbackList();
    return;
  }
  if (e.target.closest("[data-fbcal-prev]:not(:disabled)")) {
    fbCalYear -= 1;
    renderFeedbackCal();
    return;
  }
  if (e.target.closest("[data-fbcal-next]:not(:disabled)")) {
    fbCalYear += 1;
    renderFeedbackCal();
  }
});

function renderUnits(unitList, tickSet) {
  const overall = moduleTotals(unitList, tickSet);
  const summary = document.getElementById("unitSummary");
  if (summary) summary.textContent = `${overall.done} of ${overall.total} signed off`;

  document.getElementById("unitList").innerHTML = unitList
    .map((u, i) => {
      const total = u.items.length;
      const done = u.items.filter((it) => tickSet.has(it.id)).length;
      const full = total > 0 && done === total;
      const pct = total ? Math.round((done / total) * 100) : 0;
      return `<div class="unit-lite${full ? " is-full" : ""}" style="animation-delay:${i * 40}ms">
        <span class="unit-lite__icon">${full ? "✓" : i + 1}</span>
        <span class="unit-lite__name">${escapeHtml(u.name)}</span>
        <span class="track track--mini"><span class="track__bar" style="width:${pct}%"></span></span>
        <span class="unit-lite__count">${done}/${total}</span>
      </div>`;
    })
    .join("");
}

async function init() {
  const { data: sessionData } = await supabase.auth.getSession();
  if (!sessionData?.session) {
    window.location.href = "login.html";
    return;
  }
  const uid = sessionData.session.user.id;

  const { data: student, error } = await supabase
    .from("students")
    .select(
      `id, full_name, student_code, must_change_password, created_at, current_module_id,
       group:school_groups(name), school:schools(name), module:modules(id, number, name)`
    )
    .eq("id", uid)
    .single();

  if (error || !student) {
    // Not a student account, or the row is gone — nowhere useful but sign-in.
    await supabase.auth.signOut();
    window.location.href = "login.html";
    return;
  }

  // Re-checked on every load, so the URL can't be pasted past first-login.
  if (student.must_change_password) {
    window.location.href = "first-login.html";
    return;
  }

  const avatar = document.getElementById("studentAvatar");
  if (avatar) avatar.textContent = initials(student.full_name);

  document.getElementById("studentName").textContent = student.full_name;
  document.getElementById("studentMeta").textContent = [
    student.school?.name,
    student.group?.name || "—",
    `joined ${formatDate(student.created_at)}`,
  ]
    .filter(Boolean)
    .join(" · ");

  const { data: units, error: unitsError } = await supabase
    .from("units")
    .select("id, number, name, sort_order")
    .eq("module_id", student.current_module_id)
    .order("sort_order");

  if (unitsError) {
    setStatus("Couldn't load your progress. Refresh the page to try again.", "error");
    return;
  }

  const unitIds = (units || []).map((u) => u.id);

  const [{ data: items }, { data: ticks }, { data: cps }, { data: feedback }] = await Promise.all([
    unitIds.length
      ? supabase
          .from("items")
          .select("id, unit_id, description, pass_standard, is_checkpoint, sort_order")
          .in("unit_id", unitIds)
          .order("sort_order")
      : Promise.resolve({ data: [] }),
    supabase.from("item_ticks").select("item_id").eq("student_id", uid),
    supabase.from("checkpoint_passes").select("item_id").eq("student_id", uid),
    // No coach name here on purpose — feedback reads as a note from "the club", not an audit trail.
    supabase
      .from("feedback")
      .select("month, body, rating, highlight, next_focus, created_at")
      .eq("student_id", uid)
      .order("month", { ascending: false })
      .order("created_at", { ascending: false }),
  ]);

  const tickSet = new Set((ticks || []).map((t) => t.item_id));
  const cpSet = new Set((cps || []).map((c) => c.item_id));

  const unitList = (units || []).map((u) => ({
    ...u,
    items: (items || []).filter((it) => it.unit_id === u.id && !it.is_checkpoint),
    checkpoint: (items || []).find((it) => it.unit_id === u.id && it.is_checkpoint) || null,
  }));

  renderRing(student, unitList, tickSet, cpSet);
  renderBadges(unitList, cpSet);
  renderNextUp(unitList, tickSet);
  renderFeedback(feedback || []);
  renderUnits(unitList, tickSet);
}

document.getElementById("signOutButton").addEventListener("click", async () => {
  await supabase.auth.signOut();
  window.location.href = "login.html";
});

init();
