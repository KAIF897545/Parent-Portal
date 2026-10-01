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

function moduleTotals(unitList, tickSet) {
  let done = 0;
  let total = 0;
  for (const u of unitList) {
    total += u.items.length;
    done += u.items.filter((it) => tickSet.has(it.id)).length;
  }
  return { done, total, pct: total ? Math.round((done / total) * 100) : 0 };
}

// A unit counts as done if its checkpoint is passed (when it has one), or
// if every item in it is ticked (when it doesn't) -- checkpoints are a
// formally-assessed pass, not just casual ticking, so they take priority.
function isUnitDone(u, tickSet, cpSet) {
  if (u.checkpoint) return cpSet.has(u.checkpoint.id);
  return u.items.length > 0 && u.items.every((it) => tickSet.has(it.id));
}

// One status per unit, in order: everything before the first not-done unit
// is "done", that first one is "now", everything after is "next". Shared by
// the path stepper and the topics table so both agree on the same student's
// current position.
function unitStatuses(unitList, tickSet, cpSet) {
  const doneFlags = unitList.map((u) => isUnitDone(u, tickSet, cpSet));
  const currentIndex = doneFlags.findIndex((d) => !d);
  return unitList.map((_, i) => {
    if (currentIndex === -1) return "done";
    if (i < currentIndex) return "done";
    if (i === currentIndex) return "now";
    return "next";
  });
}

function renderHero(student, unitList, tickSet, cpSet, feedback) {
  const prog = moduleTotals(unitList, tickSet);
  const statuses = unitStatuses(unitList, tickSet, cpSet);
  const nowIndex = statuses.indexOf("now");
  const currentUnit = nowIndex === -1 ? null : unitList[nowIndex];
  const topicsTotal = unitList.length;
  const topicsDone = statuses.filter((s) => s === "done").length;

  const firstName = (student.full_name || "").split(" ")[0] || student.full_name;

  const headline = currentUnit
    ? `${escapeHtml(firstName)} is now learning <span class="p-hero__gold">${escapeHtml(currentUnit.name)}.</span>`
    : `${escapeHtml(firstName)} has completed every topic in this module.`;

  const lede = currentUnit
    ? `${escapeHtml(firstName)} has finished ${topicsDone} of ${topicsTotal} topics in this module. Their coach signs off each skill once they can show it at the board.`
    : `Every topic in this module is signed off. Ask the coach about moving up to the next one.`;

  const now = new Date();
  const thisMonthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
  // Only count a rating as "this month's effort" if the feedback row is
  // actually for the current calendar month -- otherwise this stat would
  // silently show a stale rating from whenever feedback was last written.
  const thisMonthFeedback = (feedback || []).find((f) => String(f.month).slice(0, 7) === thisMonthKey && f.rating);
  const monthName = now.toLocaleDateString("en-GB", { month: "long" });
  const effortStat = thisMonthFeedback
    ? `<div class="p-stat__stars" role="img" aria-label="Effort ${thisMonthFeedback.rating} out of 5">${"★".repeat(
        thisMonthFeedback.rating
      )}${"☆".repeat(5 - thisMonthFeedback.rating)}</div>`
    : `<div class="p-stat__num">—</div>`;

  const card = document.getElementById("pHero");
  card.hidden = false;
  card.innerHTML = `
    <p class="p-hero__module">Module ${student.module?.number ?? ""}: ${escapeHtml(student.module?.name ?? "")}</p>
    <h2 class="p-hero__headline">${headline}</h2>
    <p class="p-hero__lede">${lede}</p>
    <div class="p-hero__stats">
      <div class="p-stat"><div class="p-stat__num">${prog.done}<small> / ${prog.total}</small></div><div class="p-stat__label">Skills signed off</div></div>
      <div class="p-stat"><div class="p-stat__num">${topicsDone}<small> / ${topicsTotal}</small></div><div class="p-stat__label">Topics complete</div></div>
      <div class="p-stat"><div class="p-stat__num">${prog.pct}%</div><div class="p-stat__label">Through this module</div></div>
      <div class="p-stat">${effortStat}<div class="p-stat__label">${escapeHtml(monthName)} effort</div></div>
    </div>`;
}

function renderPath(unitList, tickSet, cpSet) {
  const statuses = unitStatuses(unitList, tickSet, cpSet);
  const doneCount = statuses.filter((s) => s === "done").length;
  const summary = document.getElementById("pathSummary");
  if (summary) summary.textContent = `${doneCount} of ${unitList.length} complete`;

  const nowIndex = statuses.indexOf("now");
  const progressIndex = nowIndex === -1 ? unitList.length - 1 : nowIndex;
  const doneWidth = unitList.length > 1 ? (Math.max(progressIndex, 0) / (unitList.length - 1)) * 88.9 : 0;

  const pathList = document.getElementById("pathList");
  if (pathList) {
    pathList.style.setProperty("--done-width", `${doneWidth}%`);
    pathList.innerHTML = unitList
      .map((u, i) => {
        const s = statuses[i];
        const label = s === "done" ? "Complete" : s === "now" ? "Learning now" : "Coming up";
        return `<li class="p-step p-step--${s}">
          <span class="p-step__node">${s === "done" ? "✓" : i + 1}</span>
          <span class="p-step__name">${escapeHtml(u.name)}<span class="visually-hidden">, ${label}</span></span>
        </li>`;
      })
      .join("");
  }

  const segments = document.getElementById("pathSegments");
  if (segments) {
    segments.innerHTML = unitList.map((_, i) => `<i class="p-segment p-segment--${statuses[i]}"></i>`).join("");
  }
}

function renderCurrentTopic(unitList, tickSet, cpSet) {
  const statuses = unitStatuses(unitList, tickSet, cpSet);
  const nowIndex = statuses.indexOf("now");
  const box = document.getElementById("currentTopic");

  if (nowIndex === -1) {
    box.innerHTML = `<p class="p-current__label">Module complete</p>
      <h2 class="h2 p-current__title">Every topic is signed off</h2>
      <p class="p-current__intro">Ask the coach about moving up to the next module.</p>`;
    return;
  }

  const unit = unitList[nowIndex];
  const total = unit.items.length;
  const done = unit.items.filter((it) => tickSet.has(it.id)).length;

  const skills = unit.items
    .map((it, i) => {
      const isDone = tickSet.has(it.id);
      return `<li class="p-skill">
        <span class="p-skill__n">${i + 1}</span>
        <span class="p-skill__text">${escapeHtml(it.description)}</span>
        <span class="p-skill__pill${isDone ? " is-done" : ""}">${isDone ? "Signed off" : "Practising"}</span>
      </li>`;
    })
    .join("");

  // Prefer the real take-home-assignment text written for the next skill
  // they haven't signed off yet; fall back to any item in the unit that has
  // one, since not every item necessarily has assignments text.
  const tipItem =
    unit.items.find((it) => !tickSet.has(it.id) && it.assignments) || unit.items.find((it) => it.assignments);
  const tip = tipItem
    ? `<div class="p-tip">
        <div class="p-tip__icon" aria-hidden="true">♞</div>
        <div>
          <strong>Try this at home</strong>
          <p>${escapeHtml(tipItem.assignments)}</p>
        </div>
      </div>`
    : "";

  box.innerHTML = `
    <p class="p-current__label">Topic ${nowIndex + 1} of ${unitList.length}, learning now</p>
    <h2 class="h2 p-current__title">${escapeHtml(unit.name)}</h2>
    <p class="p-current__intro">${done} of ${total} skills signed off so far.</p>
    <ol class="p-skills">${skills}</ol>
    ${tip}`;
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
        const highlight = f.highlight
          ? `<div class="feedback-card__highlight">
              <div class="feedback-card__highlight-label">Highlight of the month</div>
              <p>${escapeHtml(f.highlight)}</p>
            </div>`
          : "";
        const effort = f.rating
          ? `<div class="feedback-card__effort">
              <span>Effort</span>
              <span class="feedback-card__stars" aria-label="${f.rating} out of 5">${"★".repeat(f.rating)}${"☆".repeat(
                5 - f.rating
              )}</span>
            </div>`
          : "";
        const goal = f.next_focus
          ? `<div class="feedback-card__block">
              <div class="feedback-card__block-label feedback-card__block-label--goal">Goal for next month</div>
              <p>${escapeHtml(f.next_focus)}</p>
            </div>`
          : "";
        return `<div class="feedback-card" style="animation-delay:${i * 60}ms">
          <div class="feedback-card__month">${formatMonth(f.month)}</div>
          ${highlight}
          ${effort}
          <div class="feedback-card__block">
            <div class="feedback-card__block-label">How they're doing</div>
            <p>${escapeHtml(f.body)}</p>
          </div>
          ${goal}
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

function renderUnits(unitList, tickSet, cpSet) {
  const overall = moduleTotals(unitList, tickSet);
  const summary = document.getElementById("unitSummary");
  if (summary) summary.textContent = `${overall.done} of ${overall.total} signed off`;

  const statuses = unitStatuses(unitList, tickSet, cpSet);
  const label = { done: "Complete", now: "Learning now", next: "Coming up" };

  document.getElementById("unitList").innerHTML = unitList
    .map((u, i) => {
      const total = u.items.length;
      const done = u.items.filter((it) => tickSet.has(it.id)).length;
      const pct = total ? Math.round((done / total) * 100) : 0;
      const s = statuses[i];
      return `<div class="p-topic p-topic--${s}" style="animation-delay:${i * 40}ms">
        <span class="p-topic__n">${String(i + 1).padStart(2, "0")}</span>
        <span class="p-topic__name">${escapeHtml(u.name)}</span>
        <span class="p-topic__status">${label[s]}</span>
        <span class="track track--mini"><span class="track__bar" style="width:${pct}%"></span></span>
        <span class="p-topic__count">${done}/${total}</span>
      </div>`;
    })
    .join("");
}

async function init() {
  const { data: sessionData } = await supabase.auth.getSession();
  if (!sessionData?.session) {
    window.location.replace("login.html");
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

  if (error) {
    // PGRST116 from .single() means zero rows -- the account genuinely no
    // longer exists, so there's nowhere useful but sign-in. Any other error
    // (network blip, Supabase hiccup, a PWA reconnecting after being
    // backgrounded) is transient -- staying signed in and letting the user
    // retry is safer than silently destroying a perfectly valid session.
    if (error.code === "PGRST116") {
      await supabase.auth.signOut();
      window.location.replace("login.html");
      return;
    }
    setStatus("Couldn't load your account. Check your connection and try again.", "error");
    return;
  }
  if (!student) {
    await supabase.auth.signOut();
    window.location.replace("login.html");
    return;
  }

  // Re-checked on every load, so the URL can't be pasted past first-login.
  if (student.must_change_password) {
    window.location.replace("first-login.html");
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

  const printFooter = document.getElementById("printFooter");
  if (printFooter) {
    printFooter.textContent = `${student.full_name} — Maldives Chess Club Parent Portal — printed ${formatDate(
      new Date().toISOString()
    )}`;
  }

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
          .select("id, unit_id, description, pass_standard, is_checkpoint, sort_order, assignments")
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

  renderHero(student, unitList, tickSet, cpSet, feedback || []);
  renderPath(unitList, tickSet, cpSet);
  renderCurrentTopic(unitList, tickSet, cpSet);
  renderFeedback(feedback || []);
  renderUnits(unitList, tickSet, cpSet);
}

document.getElementById("signOutButton").addEventListener("click", async () => {
  await supabase.auth.signOut();
  window.location.replace("login.html");
});

window.addEventListener("beforeprint", () => document.body.classList.add("is-printing"));
window.addEventListener("afterprint", () => document.body.classList.remove("is-printing"));

document.getElementById("savePdfButton").addEventListener("click", () => {
  window.print();
});

init();
