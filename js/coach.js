import { supabase } from "./supabase.js";
import { escapeHtml, formatDate, formatMonth, formatDateTime, maldivesDateParts, initials } from "./utils.js";

const el = (id) => document.getElementById(id);

const state = {
  coach: null,
  isAdmin: false,
  schools: [],
  schoolId: null,
  groups: [],
  students: [],
  selectedStudent: null,
  curriculum: [],
  moduleId: null,
  openUnits: new Set(),
  notePane: "feedback",
  feedback: [],
  notes: [],
  rosterTicks: new Map(), // student_id -> Map(item_id -> {on, coachName})
  rosterCps: new Map(), // student_id -> Map(item_id -> {on, evidence, coachName})
  rosterFeedbackMonths: new Map(), // student_id -> [month, ...]

  attCalendarMonth: null, // Date, first-of-month, local
  attSelectedDate: null, // "YYYY-MM-DD"
  attMonthCounts: new Map(), // "YYYY-MM-DD" -> present count, for the visible month
  attSavedByDate: new Map(), // "YYYY-MM-DD" -> Map(student_id -> {coachName, markedAt}), lazily filled per date visited
  attDrafts: new Map(), // "YYYY-MM-DD" -> Set(student_id), only for dates with unsaved edits
  attLog: [], // attendance_log rows for the selected date, newest first
};

function setStatus(text, kind) {
  el("status").textContent = text;
  el("status").className = kind ? `form-message form-message--${kind}` : "form-message";
}

function thisMonthKey() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
}

// Maldives is UTC+5 with no daylight saving; "today" for attendance always
// means the current calendar day there, regardless of the coach's own
// device timezone. en-CA formats as YYYY-MM-DD, matching Postgres `date`.
function todayKey() {
  return new Date().toLocaleDateString("en-CA", { timeZone: "Indian/Maldives" });
}

// --- Boot ---------------------------------------------------------------

async function init() {
  const { data: sessionData } = await supabase.auth.getSession();
  if (!sessionData?.session) {
    window.location.href = "login.html";
    return;
  }

  const uid = sessionData.session.user.id;
  const { data: coachRow, error } = await supabase
    .from("coaches")
    .select("id, name, role, school_id, active")
    .eq("id", uid)
    .single();

  if (error || !coachRow || !coachRow.active) {
    await supabase.auth.signOut();
    window.location.href = "login.html";
    return;
  }

  state.coach = coachRow;
  state.isAdmin = coachRow.role === "admin";

  const { data: schools } = await supabase.from("schools").select("id, name").order("name");
  state.schools = schools || [];

  populateSchoolSelect();
  state.schoolId = state.isAdmin ? state.schools[0]?.id ?? null : coachRow.school_id;

  const schoolName = state.schools.find((s) => s.id === coachRow.school_id)?.name ?? "";
  el("roleLine").textContent = `${coachRow.name} · ${
    state.isAdmin ? "Admin · all schools" : `Coach · ${schoolName}`
  }`;

  await loadCurriculum();

  if (!state.schoolId) {
    setStatus("No school portals are set up yet.", "error");
    return;
  }

  await onSchoolChange();
}

function populateSchoolSelect() {
  const sel = el("schoolSelect");
  sel.innerHTML = state.schools
    .map((s) => `<option value="${s.id}">${escapeHtml(s.name)}</option>`)
    .join("");

  if (!state.isAdmin) {
    sel.value = state.coach.school_id;
    sel.hidden = true;
  } else {
    sel.value = state.schools[0]?.id ?? "";
  }
}

el("schoolSelect").addEventListener("change", async (e) => {
  state.schoolId = e.target.value;
  await onSchoolChange();
});

// --- Curriculum (fetched once) ------------------------------------------

async function loadCurriculum() {
  const [{ data: modules }, { data: units }, { data: items }] = await Promise.all([
    supabase.from("modules").select("id, number, name").order("number"),
    supabase.from("units").select("id, module_id, number, name, sort_order").order("sort_order"),
    supabase
      .from("items")
      .select("id, unit_id, description, pass_standard, is_checkpoint, sort_order")
      .order("sort_order"),
  ]);

  state.curriculum = (modules || []).map((m) => ({
    ...m,
    units: (units || [])
      .filter((u) => u.module_id === m.id)
      .map((u) => ({
        ...u,
        items: (items || []).filter((it) => it.unit_id === u.id && !it.is_checkpoint),
        checkpoint: (items || []).find((it) => it.unit_id === u.id && it.is_checkpoint) || null,
      })),
  }));
}

// --- School-scoped data ---------------------------------------------------

async function onSchoolChange() {
  state.selectedStudent = null;
  el("checklistWrap").innerHTML = "";
  setStatus("");

  await loadGroups();
  await loadStudents();

  const ids = state.students.map((s) => s.id);
  await Promise.all([loadRosterProgress(ids), loadRosterFeedbackMonths(ids)]);

  renderPicker();
  await initAttendanceTab();
}

async function loadGroups() {
  const { data } = await supabase
    .from("school_groups")
    .select("id, name")
    .eq("school_id", state.schoolId)
    .order("name");
  state.groups = data || [];
  const options =
    '<option value="">All groups</option>' +
    state.groups.map((g) => `<option value="${g.id}">${escapeHtml(g.name)}</option>`).join("");
  el("groupFilter").innerHTML = options;
  el("attGroupFilter").innerHTML = options;
}

async function loadStudents() {
  const { data, error } = await supabase
    .from("students")
    .select("id, full_name, student_code, group_id, current_module_id, must_change_password, active")
    .eq("school_id", state.schoolId)
    .eq("active", true)
    .order("full_name");

  if (error) {
    setStatus("Couldn't load students. Refresh to try again.", "error");
    state.students = [];
    return;
  }
  state.students = data || [];
}

async function loadRosterProgress(studentIds) {
  if (!studentIds.length) {
    state.rosterTicks = new Map();
    state.rosterCps = new Map();
    return;
  }
  const [{ data: ticks }, { data: cps }] = await Promise.all([
    supabase.from("item_ticks").select("student_id, item_id, marked_on, coach:coaches(name)").in("student_id", studentIds),
    supabase
      .from("checkpoint_passes")
      .select("student_id, item_id, marked_on, evidence, coach:coaches(name)")
      .in("student_id", studentIds),
  ]);

  state.rosterTicks = groupByStudent(ticks, (r) => ({ on: r.marked_on, coachName: r.coach?.name || "—" }));
  state.rosterCps = groupByStudent(cps, (r) => ({
    on: r.marked_on,
    evidence: r.evidence,
    coachName: r.coach?.name || "—",
  }));
}

function groupByStudent(rows, mapFn) {
  const out = new Map();
  for (const r of rows || []) {
    if (!out.has(r.student_id)) out.set(r.student_id, new Map());
    out.get(r.student_id).set(r.item_id, mapFn(r));
  }
  return out;
}

async function loadRosterFeedbackMonths(studentIds) {
  if (!studentIds.length) {
    state.rosterFeedbackMonths = new Map();
    return;
  }
  const { data } = await supabase.from("feedback").select("student_id, month").in("student_id", studentIds);
  const map = new Map();
  for (const row of data || []) {
    if (!map.has(row.student_id)) map.set(row.student_id, []);
    map.get(row.student_id).push(row.month);
  }
  state.rosterFeedbackMonths = map;
}

// --- Attendance tab ---------------------------------------------------------
//
// A row in `attendance` for (student_id, session_date) means present; no row
// means absent. There's no immediate-save here: ticking a student only edits
// an in-memory draft for the selected date, and "Save attendance" applies the
// whole batch (and writes the matching attendance_log rows) in one RPC call.
// "Today" is always the current Maldives calendar day (see todayKey()
// above), independent of the coach's own device timezone.

function ymd(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function parseKey(key) {
  const [y, m, d] = key.split("-").map(Number);
  return new Date(y, m - 1, d);
}

function attSavedIds(dateKey) {
  const map = state.attSavedByDate.get(dateKey);
  return map ? new Set(map.keys()) : new Set();
}

// A date only ever gets a draft after its saved set has been fetched (you
// have to select a date, which loads it, before you can tick anyone in it),
// so every dirty date is also a cached one — dirty-checking never needs to
// fetch a date that isn't currently on screen.
function attDraftFor(dateKey) {
  return state.attDrafts.get(dateKey) || attSavedIds(dateKey);
}

function attIsDirty(dateKey) {
  const draft = state.attDrafts.get(dateKey);
  if (!draft) return false;
  const saved = attSavedIds(dateKey);
  if (draft.size !== saved.size) return true;
  for (const id of draft) if (!saved.has(id)) return true;
  return false;
}

// Filters the roster shown while marking attendance by group, so the
// "Active students"/"Present" stat cards (whole-school context) stay
// separate from the roster list and "Mark everyone present" (which only
// need to act on the group currently in view).
function filteredAttendanceStudents() {
  const group = el("attGroupFilter").value;
  return group ? state.students.filter((s) => s.group_id === group) : state.students;
}

async function initAttendanceTab() {
  const t = todayKey();
  state.attCalendarMonth = new Date(parseKey(t).getFullYear(), parseKey(t).getMonth(), 1);
  state.attSelectedDate = t;
  state.attMonthCounts = new Map();
  state.attSavedByDate = new Map();
  state.attDrafts = new Map();
  state.attLog = [];

  el("statCount").textContent = state.students.length;
  el("statPending").textContent = state.students.filter((s) => s.must_change_password).length;

  await Promise.all([loadAttendanceMonth(), loadAttendanceDate(t)]);
  renderAttendanceTab();
}

async function loadAttendanceMonth() {
  const start = new Date(state.attCalendarMonth.getFullYear(), state.attCalendarMonth.getMonth(), 1);
  const end = new Date(state.attCalendarMonth.getFullYear(), state.attCalendarMonth.getMonth() + 1, 0);
  const { data, error } = await supabase.rpc("attendance_month_counts", {
    p_school_id: state.schoolId,
    p_start: ymd(start),
    p_end: ymd(end),
  });

  if (error) {
    setStatus("Couldn't load the calendar. Refresh to try again.", "error");
    return;
  }
  state.attMonthCounts = new Map((data || []).map((r) => [r.session_date, Number(r.present_count)]));
}

async function loadAttendanceDate(dateKey) {
  const [{ data: attRows, error: attErr }, { data: logRows, error: logErr }] = await Promise.all([
    supabase
      .from("attendance")
      .select("student_id, marked_at, coach:coaches(name)")
      .eq("school_id", state.schoolId)
      .eq("session_date", dateKey),
    supabase
      .from("attendance_log")
      .select("action, created_at, coach:coaches(name), student:students(full_name, student_code)")
      .eq("school_id", state.schoolId)
      .eq("session_date", dateKey)
      .order("created_at", { ascending: false }),
  ]);

  if (attErr || logErr) {
    setStatus("Couldn't load that date's attendance. Try again.", "error");
    return;
  }

  const map = new Map();
  for (const r of attRows || []) {
    map.set(r.student_id, { coachName: r.coach?.name || "—", markedAt: r.marked_at });
  }
  state.attSavedByDate.set(dateKey, map);
  state.attLog = logRows || [];
}

function renderAttendanceTab() {
  renderCalendar();
  renderSession();
}

function renderCalendar() {
  const month = state.attCalendarMonth;
  el("calTitle").textContent = month.toLocaleDateString("en-GB", { month: "long", year: "numeric" });

  const sessionDays = state.attMonthCounts.size;
  const totalPresent = [...state.attMonthCounts.values()].reduce((sum, n) => sum + n, 0);
  el("calSubtitle").textContent = sessionDays
    ? `${sessionDays} session${sessionDays === 1 ? "" : "s"} · ${totalPresent} present marks`
    : "No sessions recorded yet";

  const firstOfMonth = new Date(month.getFullYear(), month.getMonth(), 1);
  const offset = (firstOfMonth.getDay() + 6) % 7; // grid starts on Monday
  const start = new Date(firstOfMonth);
  start.setDate(1 - offset);

  const today = todayKey();
  let html = "";
  for (let i = 0; i < 42; i++) {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    const key = ymd(d);
    const isFuture = key > today;
    const count = state.attMonthCounts.get(key) || 0;
    const classes = ["cal-day"];
    if (d.getMonth() !== month.getMonth()) classes.push("is-other");
    if (key === today) classes.push("is-today");
    if (attIsDirty(key)) classes.push("is-draft");

    const label =
      d.toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long" }) +
      (count ? `, ${count} present` : "");

    html += `<button type="button" class="${classes.join(" ")}" data-cal-day="${key}" ${isFuture ? "disabled" : ""}
      aria-pressed="${key === state.attSelectedDate}" aria-label="${label}">
      <span>${d.getDate()}</span><span class="cal-day__mark">${count ? `✓${count}` : ""}</span>
    </button>`;
  }
  el("calDays").innerHTML = html;

  const nextMonth = new Date(month.getFullYear(), month.getMonth() + 1, 1);
  el("calNext").disabled = ymd(nextMonth) > today;
}

function renderSession() {
  const dateKey = state.attSelectedDate;
  const savedMap = state.attSavedByDate.get(dateKey) || new Map();
  const savedIds = new Set(savedMap.keys());
  const draftSet = attDraftFor(dateKey);
  const isDirty = attIsDirty(dateKey);
  const isToday = dateKey === todayKey();

  const dateLabel = parseKey(dateKey).toLocaleDateString("en-GB", {
    weekday: "long",
    day: "numeric",
    month: "long",
  });
  el("sessionDate").textContent = (isToday ? "Today, " : "") + dateLabel;

  const statusEl = el("attStatus");
  if (isDirty) {
    statusEl.textContent = "Unsaved changes";
    statusEl.className = "status-line status-line--dirty";
  } else if (state.attLog.length) {
    const last = state.attLog[0];
    const { date, time } = maldivesDateParts(last.created_at);
    statusEl.textContent = `Last change by ${last.coach?.name || "—"}, ${date} at ${time}`;
    statusEl.className = "status-line";
  } else {
    statusEl.textContent = "Not recorded yet";
    statusEl.className = "status-line";
  }

  const rosterStudents = filteredAttendanceStudents();

  el("attendanceList").innerHTML = rosterStudents.length
    ? rosterStudents
        .map((s, i) => {
          const on = draftSet.has(s.id);
          const was = savedIds.has(s.id);
          const info = savedMap.get(s.id);
          const changeTag =
            on !== was ? `<span class="roster-row__changetag">${on ? "Adding" : "Removing"}</span>` : "";
          const markedLine =
            on && was && info
              ? `<span class="roster-row__marked">Marked by ${escapeHtml(info.coachName)}, ${formatDateTime(
                  info.markedAt
                )}</span>`
              : "";
          return `<li class="roster-row${on ? " is-present" : ""}" style="animation-delay:${i * 25}ms">
            <span class="avatar-circle avatar-circle--sm" aria-hidden="true">${escapeHtml(initials(s.full_name))}</span>
            <span class="roster-row__name">${escapeHtml(s.full_name)}
              <span class="roster-row__sub">${escapeHtml(s.student_code)}</span>
              ${markedLine}
            </span>${changeTag}
            <button type="button" class="attend-btn" data-att="${s.id}" aria-pressed="${on}"
              aria-label="Mark ${escapeHtml(s.full_name)} present">✓</button>
          </li>`;
        })
        .join("")
    : `<p class="empty-state">${
        state.students.length ? "No students in that group." : "No active students at this school yet."
      }</p>`;

  const presentShown = state.students.filter((s) => draftSet.has(s.id)).length;
  el("statPresent").textContent = `${presentShown} / ${state.students.length}`;

  const presentShownFiltered = rosterStudents.filter((s) => draftSet.has(s.id)).length;
  el("markAllPresent").hidden = rosterStudents.length > 0 && presentShownFiltered === rosterStudents.length;

  const added = [...draftSet].filter((id) => !savedIds.has(id));
  const removed = [...savedIds].filter((id) => !draftSet.has(id));
  el("saveNote").textContent = isDirty
    ? [added.length && `${added.length} to add`, removed.length && `${removed.length} to remove`]
        .filter(Boolean)
        .join(", ")
    : "No changes to save";
  el("saveAttendance").disabled = !isDirty;
  el("discardAttendance").hidden = !isDirty;

  el("attendanceLogWrap").hidden = state.attLog.length === 0;
  el("attendanceLogList").innerHTML = state.attLog
    .map((l) => {
      const name = l.student?.full_name || "—";
      const code = l.student?.student_code;
      const verb = l.action === "added" ? "marked" : "removed";
      return `<div class="entry"><div class="entry__body">${escapeHtml(l.coach?.name || "—")} ${verb} ${escapeHtml(
        name
      )}${code ? ` (${escapeHtml(code)})` : ""} · ${formatDateTime(l.created_at)}</div></div>`;
    })
    .join("");
}

el("calDays").addEventListener("click", async (e) => {
  const btn = e.target.closest("[data-cal-day]");
  if (!btn || btn.disabled) return;
  state.attSelectedDate = btn.getAttribute("data-cal-day");
  await loadAttendanceDate(state.attSelectedDate);
  renderAttendanceTab();
});

el("calPrev").addEventListener("click", async () => {
  state.attCalendarMonth.setMonth(state.attCalendarMonth.getMonth() - 1);
  await loadAttendanceMonth();
  renderCalendar();
});

el("calNext").addEventListener("click", async () => {
  state.attCalendarMonth.setMonth(state.attCalendarMonth.getMonth() + 1);
  await loadAttendanceMonth();
  renderCalendar();
});

el("calToday").addEventListener("click", async () => {
  const t = todayKey();
  state.attCalendarMonth = new Date(parseKey(t).getFullYear(), parseKey(t).getMonth(), 1);
  state.attSelectedDate = t;
  await Promise.all([loadAttendanceMonth(), loadAttendanceDate(t)]);
  renderAttendanceTab();
});

el("attendanceList").addEventListener("click", (e) => {
  const btn = e.target.closest("[data-att]");
  if (!btn) return;
  const dateKey = state.attSelectedDate;
  const draft = new Set(attDraftFor(dateKey));
  const id = btn.getAttribute("data-att");
  if (draft.has(id)) draft.delete(id);
  else draft.add(id);
  state.attDrafts.set(dateKey, draft);
  renderAttendanceTab();
});

el("markAllPresent").addEventListener("click", () => {
  const dateKey = state.attSelectedDate;
  const draft = new Set(attDraftFor(dateKey));
  filteredAttendanceStudents().forEach((s) => draft.add(s.id));
  state.attDrafts.set(dateKey, draft);
  renderAttendanceTab();
});

el("attGroupFilter").addEventListener("change", renderSession);

el("discardAttendance").addEventListener("click", () => {
  state.attDrafts.delete(state.attSelectedDate);
  renderAttendanceTab();
});

el("saveAttendance").addEventListener("click", async () => {
  const dateKey = state.attSelectedDate;
  const draft = attDraftFor(dateKey);
  const saved = attSavedIds(dateKey);
  const added = [...draft].filter((id) => !saved.has(id));
  const removed = [...saved].filter((id) => !draft.has(id));
  if (!added.length && !removed.length) return;

  const btn = el("saveAttendance");
  btn.disabled = true;
  const { error } = await supabase.rpc("save_attendance", {
    p_school_id: state.schoolId,
    p_session_date: dateKey,
    p_added: added,
    p_removed: removed,
  });

  if (error) {
    btn.disabled = false;
    setStatus("Couldn't save attendance. Try again.", "error");
    return;
  }

  state.attDrafts.delete(dateKey);
  await Promise.all([loadAttendanceDate(dateKey), loadAttendanceMonth()]);
  renderAttendanceTab();
  setStatus("Attendance saved.", "success");
});

window.addEventListener("beforeunload", (e) => {
  for (const key of state.attDrafts.keys()) {
    if (attIsDirty(key)) {
      e.preventDefault();
      e.returnValue = "";
      return;
    }
  }
});

// --- Progress tab: filters + picker ---------------------------------------

function filteredStudents() {
  const group = el("groupFilter").value;
  const q = el("searchFilter").value.trim().toLowerCase();
  return state.students.filter((s) => {
    if (group && s.group_id !== group) return false;
    if (q && !(`${s.full_name} ${s.student_code}`.toLowerCase().includes(q))) return false;
    return true;
  });
}

function moduleLabel(id) {
  const m = state.curriculum.find((m) => m.id === id);
  return m ? `Module ${m.number}` : "";
}

function studentModuleStats(studentId, moduleId) {
  const mod = state.curriculum.find((m) => m.id === moduleId);
  if (!mod) return { done: 0, total: 0, pct: 0 };
  const ticks = state.rosterTicks.get(studentId);
  let done = 0;
  let total = 0;
  for (const u of mod.units) {
    total += u.items.length;
    if (ticks) for (const it of u.items) if (ticks.has(it.id)) done++;
  }
  return { done, total, pct: total ? Math.round((done / total) * 100) : 0 };
}

function feedbackDueForStudent(studentId) {
  const months = state.rosterFeedbackMonths.get(studentId) || [];
  const ym = thisMonthKey();
  return !months.some((m) => String(m).slice(0, 7) === ym);
}

function renderPicker() {
  const list = filteredStudents();

  el("studentPicker").innerHTML = list.length
    ? list
        .map((s, i) => {
          const stats = studentModuleStats(s.id, s.current_module_id);
          const due = feedbackDueForStudent(s.id);
          return `<button type="button" class="picker__item" data-student="${s.id}" aria-pressed="${
            state.selectedStudent === s.id
          }" style="animation-delay:${i * 20}ms">
            <span class="avatar-circle avatar-circle--sm" aria-hidden="true">${escapeHtml(
              initials(s.full_name)
            )}</span>
            <span class="picker__item-text">${escapeHtml(s.full_name)}
              <small>${escapeHtml(s.student_code)} · ${moduleLabel(s.current_module_id)} ${stats.pct}%${
            due ? ' · <span class="picker__due">summary due</span>' : ""
          }</small>
            </span>
          </button>`;
        })
        .join("")
    : `<p class="empty-state">No students match those filters.</p>`;

  if (state.selectedStudent && !list.some((s) => s.id === state.selectedStudent)) {
    state.selectedStudent = null;
    el("checklistWrap").innerHTML = "";
  }
}

["groupFilter", "searchFilter"].forEach((id) => {
  el(id).addEventListener("input", renderPicker);
  el(id).addEventListener("change", renderPicker);
});

el("studentPicker").addEventListener("click", async (e) => {
  const btn = e.target.closest("[data-student]");
  if (!btn) return;
  const id = btn.getAttribute("data-student");
  const student = state.students.find((s) => s.id === id);
  if (!student) return;

  state.selectedStudent = id;
  state.moduleId = student.current_module_id;
  state.openUnits = new Set();
  state.notePane = "feedback";
  renderPicker();

  el("checklistWrap").innerHTML = '<p class="form-message">Loading…</p>';
  await loadStudentNotes(id);
  renderChecklist();
});

async function loadStudentNotes(studentId) {
  const [{ data: fb }, { data: nt }] = await Promise.all([
    supabase
      .from("feedback")
      .select("id, month, body, rating, highlight, next_focus, created_at, coach:coaches(name)")
      .eq("student_id", studentId)
      .order("month", { ascending: false })
      .order("created_at", { ascending: false }),
    supabase
      .from("coach_notes")
      .select("id, body, created_at, coach:coaches(name)")
      .eq("student_id", studentId)
      .order("created_at", { ascending: false }),
  ]);
  state.feedback = fb || [];
  state.notes = nt || [];
}

// --- Progress tab: checklist ------------------------------------------------

function studentGroupName(student) {
  const g = state.groups.find((g) => g.id === student.group_id);
  return g ? g.name : "—";
}

function renderChecklist() {
  const student = state.students.find((s) => s.id === state.selectedStudent);
  if (!student) {
    el("checklistWrap").innerHTML = "";
    return;
  }
  const mod =
    state.curriculum.find((m) => m.id === state.moduleId) ||
    state.curriculum.find((m) => m.id === student.current_module_id);
  if (!mod) {
    el("checklistWrap").innerHTML = "";
    return;
  }
  const stats = studentModuleStats(student.id, mod.id);

  const tabs = state.curriculum
    .map(
      (m) =>
        `<button type="button" class="module-tab" data-module="${m.id}" aria-selected="${m.id === mod.id}">
          Module ${m.number} · ${escapeHtml(m.name)}${m.id === student.current_module_id ? " ★" : ""}
        </button>`
    )
    .join("");

  const unitsHtml = mod.units.map((u) => renderUnit(student, u)).join("");

  el("checklistWrap").innerHTML = `
    <div class="checklist-head">
      <span class="avatar-circle avatar-circle--sm" aria-hidden="true">${escapeHtml(initials(student.full_name))}</span>
      <span class="checklist-head__name">${escapeHtml(student.full_name)} · ${escapeHtml(studentGroupName(student))}</span>
      <span class="track"><span class="track__bar" style="width:${stats.pct}%"></span></span>
      <span class="checklist-head__pct">${stats.done}/${stats.total}</span>
    </div>
    ${notesPaneHtml(student)}
    <div class="module-tabs">${tabs}</div>
    ${unitsHtml}
  `;
}

function renderUnit(student, unit) {
  const ticks = state.rosterTicks.get(student.id) || new Map();
  const cps = state.rosterCps.get(student.id) || new Map();
  const done = unit.items.filter((it) => ticks.has(it.id)).length;
  const total = unit.items.length;
  const pct = total ? Math.round((done / total) * 100) : 0;
  const open = state.openUnits.has(unit.id);

  const rows = unit.items
    .map((it) => {
      const mark = ticks.get(it.id);
      return `<div class="curriculum-item${mark ? " is-done" : ""}">
        <button type="button" class="curriculum-item__check" data-tick="${it.id}" ${mark ? "disabled" : ""}
          aria-label="Mark item done">✓</button>
        <span class="curriculum-item__text">${escapeHtml(it.description)}
          <span class="curriculum-item__pass">Pass: ${escapeHtml(it.pass_standard)}</span>
        </span>
        <span class="curriculum-item__meta">${
          mark ? `${escapeHtml(mark.coachName)}<br>${formatDate(mark.on)}` : "not marked"
        }</span>
      </div>`;
    })
    .join("");

  const cp = unit.checkpoint;
  const cpMark = cp ? cps.get(cp.id) : null;
  const cpHtml = cp
    ? `<div class="checkpoint${cpMark ? " is-passed" : ""}">
        <h4>Checkpoint</h4>
        <p>${escapeHtml(cp.pass_standard)}</p>
        ${
          cpMark
            ? `<div class="checkpoint__done">Passed · ${escapeHtml(cpMark.coachName)} · ${formatDate(cpMark.on)}<br>
                Evidence: ${escapeHtml(cpMark.evidence)}</div>`
            : `<div class="checkpoint__form">
                <input type="text" data-ev="${cp.id}" placeholder="Evidence: what you observed">
                <button type="button" class="btn btn--primary btn--xs" data-passcp="${cp.id}">Mark passed</button>
              </div>`
        }
      </div>`
    : "";

  return `<div class="unit">
    <button type="button" class="unit__head" data-unit="${unit.id}">
      <span class="unit__name">${escapeHtml(unit.number)} — ${escapeHtml(unit.name)}</span>
      <span class="track track--mini"><span class="track__bar" style="width:${pct}%"></span></span>
      <span class="unit__count">${done}/${total}</span>
    </button>
    <div class="unit__body" ${open ? "" : "hidden"}>${rows}${cpHtml}</div>
  </div>`;
}

function notesPaneHtml(student) {
  const showing = state.notePane;
  const due = feedbackDueForStudent(student.id);

  const starRow = (value) =>
    [1, 2, 3, 4, 5]
      .map(
        (n) =>
          `<button type="button" class="star-picker__star${n <= value ? " is-filled" : ""}" data-star="${n}"
            aria-label="${n} star${n > 1 ? "s" : ""}">&#9733;</button>`
      )
      .join("");

  const form =
    showing === "feedback"
      ? `<textarea id="fbText" placeholder="Monthly summary for ${escapeHtml(
          student.full_name
        )}. They will read this, so write it to them."></textarea>
        <div class="fb-extra">
          <label class="fb-extra__label">Effort &amp; growth this month</label>
          <div class="star-picker" id="fbRating" data-value="0">${starRow(0)}</div>
        </div>
        <div class="fb-extra">
          <label class="fb-extra__label" for="fbHighlight">&#127942; This month's highlight (optional)</label>
          <input type="text" id="fbHighlight" class="fb-extra__input" maxlength="120"
            placeholder="e.g. Won their first practice game">
        </div>
        <div class="fb-extra">
          <label class="fb-extra__label" for="fbFocus">&#127919; Focus for next month (optional)</label>
          <input type="text" id="fbFocus" class="fb-extra__input" maxlength="120"
            placeholder="e.g. Opening principles and simple tactics">
        </div>
        <div class="notes__row">
          <input type="month" id="fbMonth" value="${thisMonthKey()}">
          <button type="button" class="btn btn--primary btn--xs" id="fbSave">Save feedback</button>
          <span class="notes__hint">Visible to the student</span>
        </div>`
      : `<textarea id="ntText" placeholder="Note for other coaches. The student never sees this."></textarea>
        <div class="notes__row">
          <button type="button" class="btn btn--primary btn--xs" id="ntSave">Save note</button>
          <span class="notes__hint">Coaches only</span>
        </div>`;

  const history =
    showing === "feedback"
      ? state.feedback.length
        ? state.feedback
            .map(
              (f) => `<div class="entry">
                <div class="entry__meta">${formatMonth(f.month)} · ${escapeHtml(f.coach?.name || "—")} · ${formatDate(
                f.created_at
              )}${f.rating ? ` · <span class="entry__stars">${"&#9733;".repeat(f.rating)}${"&#9734;".repeat(5 - f.rating)}</span>` : ""}</div>
                ${f.highlight ? `<div class="entry__tag entry__tag--highlight">&#127942; ${escapeHtml(f.highlight)}</div>` : ""}
                <div class="entry__body">${escapeHtml(f.body)}</div>
                ${f.next_focus ? `<div class="entry__tag entry__tag--focus">&#127919; ${escapeHtml(f.next_focus)}</div>` : ""}
              </div>`
            )
            .join("")
        : '<div class="entry"><div class="entry__meta">No feedback written yet.</div></div>'
      : state.notes.length
      ? state.notes
          .map(
            (n) => `<div class="entry">
              <div class="entry__meta">${escapeHtml(n.coach?.name || "—")} · ${formatDate(n.created_at)}</div>
              <div class="entry__body">${escapeHtml(n.body)}</div>
            </div>`
          )
          .join("")
      : '<div class="entry"><div class="entry__meta">No notes yet.</div></div>';

  return `<div class="notes">
    <div class="tabs" role="tablist" aria-label="Notes">
      <button type="button" class="tab" data-notetab="feedback" role="tab" aria-selected="${showing === "feedback"}">
        Feedback${due ? ' <span class="due-flag">· due</span>' : ""}
      </button>
      <button type="button" class="tab" data-notetab="notes" role="tab" aria-selected="${showing === "notes"}">
        Notes for instructors
      </button>
    </div>
    ${form}
    <div class="notes__history">${history}</div>
  </div>`;
}

el("checklistWrap").addEventListener("click", async (e) => {
  const student = state.students.find((s) => s.id === state.selectedStudent);
  if (!student) return;

  const noteTab = e.target.closest("[data-notetab]");
  if (noteTab) {
    state.notePane = noteTab.getAttribute("data-notetab");
    renderChecklist();
    return;
  }

  // Handled with direct DOM updates, not a re-render, so clicking a star
  // doesn't wipe whatever the coach has already typed into the textarea
  // or the highlight/focus fields in the same form.
  const starBtn = e.target.closest("[data-star]");
  if (starBtn) {
    const value = Number(starBtn.getAttribute("data-star"));
    const row = starBtn.closest(".star-picker");
    const already = Number(row.dataset.value) === value;
    const next = already ? 0 : value; // click the same star again to clear
    row.dataset.value = String(next);
    row.querySelectorAll("[data-star]").forEach((btn) => {
      btn.classList.toggle("is-filled", Number(btn.getAttribute("data-star")) <= next);
    });
    return;
  }

  if (e.target.id === "fbSave") {
    const text = el("fbText").value.trim();
    if (!text) {
      el("fbText").focus();
      return;
    }
    const monthDate = `${el("fbMonth").value}-01`;
    const ratingValue = Number(el("fbRating")?.dataset.value) || null;
    const highlight = el("fbHighlight")?.value.trim() || null;
    const nextFocus = el("fbFocus")?.value.trim() || null;
    e.target.disabled = true;
    const { error } = await supabase.from("feedback").insert({
      student_id: student.id,
      coach_id: state.coach.id,
      month: monthDate,
      body: text,
      rating: ratingValue,
      highlight,
      next_focus: nextFocus,
    });
    e.target.disabled = false;
    if (error) {
      setStatus("Couldn't save feedback. Try again.", "error");
      return;
    }
    if (!state.rosterFeedbackMonths.has(student.id)) state.rosterFeedbackMonths.set(student.id, []);
    state.rosterFeedbackMonths.get(student.id).push(monthDate);
    await loadStudentNotes(student.id);
    renderPicker();
    renderChecklist();
    return;
  }

  if (e.target.id === "ntSave") {
    const text = el("ntText").value.trim();
    if (!text) {
      el("ntText").focus();
      return;
    }
    e.target.disabled = true;
    const { error } = await supabase
      .from("coach_notes")
      .insert({ student_id: student.id, coach_id: state.coach.id, body: text });
    e.target.disabled = false;
    if (error) {
      setStatus("Couldn't save the note. Try again.", "error");
      return;
    }
    await loadStudentNotes(student.id);
    renderChecklist();
    return;
  }

  const unitHead = e.target.closest("[data-unit]");
  if (unitHead) {
    const id = unitHead.getAttribute("data-unit");
    if (state.openUnits.has(id)) state.openUnits.delete(id);
    else state.openUnits.add(id);
    renderChecklist();
    return;
  }

  const modTab = e.target.closest("[data-module]");
  if (modTab) {
    state.moduleId = modTab.getAttribute("data-module");
    renderChecklist();
    return;
  }

  const tick = e.target.closest("[data-tick]");
  if (tick && !tick.disabled) {
    const itemId = tick.getAttribute("data-tick");
    tick.disabled = true;
    const { error } = await supabase
      .from("item_ticks")
      .insert({ student_id: student.id, item_id: itemId, marked_by: state.coach.id });
    if (error) {
      tick.disabled = false;
      setStatus("Couldn't save that tick. Try again.", "error");
      return;
    }
    if (!state.rosterTicks.has(student.id)) state.rosterTicks.set(student.id, new Map());
    state.rosterTicks.get(student.id).set(itemId, { on: todayKey(), coachName: state.coach.name });
    renderPicker();
    renderChecklist();
    return;
  }

  const passCp = e.target.closest("[data-passcp]");
  if (passCp) {
    const itemId = passCp.getAttribute("data-passcp");
    const input = el("checklistWrap").querySelector(`[data-ev="${itemId}"]`);
    const evidence = input.value.trim();
    if (!evidence) {
      input.focus();
      return;
    }
    passCp.disabled = true;
    const { error } = await supabase
      .from("checkpoint_passes")
      .insert({ student_id: student.id, item_id: itemId, evidence, marked_by: state.coach.id });
    passCp.disabled = false;
    if (error) {
      setStatus("Couldn't save the checkpoint. Try again.", "error");
      return;
    }
    if (!state.rosterCps.has(student.id)) state.rosterCps.set(student.id, new Map());
    state.rosterCps.get(student.id).set(itemId, { on: todayKey(), evidence, coachName: state.coach.name });
    renderPicker();
    renderChecklist();
  }
});

// --- Top-level tabs ---------------------------------------------------------

function selectTab(name) {
  const isToday = name === "today";
  el("tabToday").setAttribute("aria-selected", String(isToday));
  el("tabProgress").setAttribute("aria-selected", String(!isToday));
  el("panelToday").hidden = !isToday;
  el("panelProgress").hidden = isToday;
}

el("tabToday").addEventListener("click", () => selectTab("today"));
el("tabProgress").addEventListener("click", () => selectTab("progress"));

el("signOutButton").addEventListener("click", async () => {
  await supabase.auth.signOut();
  window.location.href = "login.html";
});

init();
