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
  openUnits: new Set(), // units manually forced OPEN, overriding the auto open-while-incomplete default
  closedUnits: new Set(), // units manually forced CLOSED, overriding the default
  openTips: new Set(), // item/checkpoint ids with their inline "Tip" box expanded
  autosaveNote: "Ticks save as you go.",
  studentPane: "checklist", // "checklist" | "feedback" | "notes", within the student detail page
  feedback: [],
  notes: [],
  fbMonthCursor: null, // "YYYY-MM" currently shown in the feedback month-switcher
  fbEditingId: null, // feedback row id currently loaded into the form, or null for "new"
  ntEditingId: null, // coach_notes row id currently loaded into the form, or null for "new"
  syllabusModuleId: null,
  syllabusOpenUnits: new Set(),
  syllabusOpenItems: new Set(),
  rosterTicks: new Map(), // student_id -> Map(item_id -> {on, coachName})
  rosterCps: new Map(), // student_id -> Map(item_id -> {on, evidence, coachName})
  rosterFeedbackMonths: new Map(), // student_id -> [month, ...]

  cameFromList: false, // true once the student page was reached by tapping a row / prev / next, for real back-button support
  listScroll: null, // scrollY captured when leaving the progress list, restored when returning to it

  attSelectedDate: null, // "YYYY-MM-DD"
  attSavedByDate: new Map(), // "YYYY-MM-DD" -> Map(student_id -> {coachName, markedAt}), lazily filled per date visited
  attDrafts: new Map(), // "YYYY-MM-DD" -> Set(student_id), only for dates with unsaved edits
  attLog: [], // attendance_log rows for the selected date, newest first
};

function setStatus(text, kind) {
  el("status").textContent = text;
  el("status").className = kind ? `form-message form-message--${kind}` : "form-message";
}

let toastTimer;
function toast(msg) {
  const t = el("toast");
  t.textContent = msg;
  t.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => t.classList.remove("show"), 2200);
}

const TICK_SVG =
  '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M3 8.5l3.2 3L13 4.5"/></svg>';

function groupName(groupId) {
  return state.groups.find((g) => g.id === groupId)?.name || "";
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
    window.location.replace("login.html");
    return;
  }

  const uid = sessionData.session.user.id;
  const { data: coachRow, error } = await supabase
    .from("coaches")
    .select("id, name, role, school_id, active")
    .eq("id", uid)
    .single();

  if (error && error.code !== "PGRST116") {
    // A real fetch error (network blip, Supabase hiccup) -- not evidence
    // the account is gone, so don't sign out over it. Let the user retry
    // rather than silently destroying a valid session.
    setStatus("Couldn't load your account. Check your connection and try again.", "error");
    return;
  }
  if (!coachRow || !coachRow.active) {
    await supabase.auth.signOut();
    window.location.replace("login.html");
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
    sel.hidden = false;
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
      .select(
        "id, unit_id, description, pass_standard, is_checkpoint, sort_order, how_to_teach, how_to_check, puzzles, assignments"
      )
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
  setStatus("");

  await loadGroups();
  await loadStudents();

  const ids = state.students.map((s) => s.id);
  await Promise.all([loadRosterProgress(ids), loadRosterFeedbackMonths(ids)]);

  renderProgressList();
  await initAttendanceTab();

  // The student we were looking at may belong to a school we've just
  // switched away from -- fall back to the list rather than show stale data.
  if (location.hash.startsWith("#student/")) {
    location.hash = "progress";
  } else {
    route();
  }
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

// Shared by the progress list's due/done badge and the Feedback tab's dot,
// so the two can never disagree about whether this month is covered.
function feedbackDueForStudent(studentId) {
  const months = state.rosterFeedbackMonths.get(studentId) || [];
  const ym = thisMonthKey();
  return !months.some((m) => String(m).slice(0, 7) === ym);
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
// so every dirty date is also a cached one -- dirty-checking never needs to
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

// Filters the roster shown while marking attendance by group, so "Mark
// everyone present"/"Clear all" (which only need to act on the group
// currently in view) stays independent of the whole-school student list.
function filteredAttendanceStudents() {
  const group = el("attGroupFilter").value;
  return group ? state.students.filter((s) => s.group_id === group) : state.students;
}

async function initAttendanceTab() {
  const t = todayKey();
  state.attSelectedDate = t;
  state.attSavedByDate = new Map();
  state.attDrafts = new Map();
  state.attLog = [];
  await loadAttendanceDate(t);
  renderSession();
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

async function goToAttDate(dateKey) {
  state.attSelectedDate = dateKey;
  if (!state.attSavedByDate.has(dateKey)) await loadAttendanceDate(dateKey);
  renderSession();
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
  el("attDatePicker").max = todayKey();
  el("attDatePicker").value = dateKey;
  el("attNext").disabled = dateKey >= todayKey();
  el("attTodayLink").hidden = isToday;

  const rosterStudents = filteredAttendanceStudents();
  const presentCount = rosterStudents.filter((s) => draftSet.has(s.id)).length;

  const statusEl = el("attStatus");
  const hasSaved = state.attLog.length > 0 || savedIds.size > 0;
  if (isDirty) {
    statusEl.textContent = "Changes not saved";
    statusEl.className = "status edited";
  } else if (hasSaved) {
    statusEl.textContent = `Saved: ${presentCount} present, ${rosterStudents.length - presentCount} absent`;
    statusEl.className = "status saved";
  } else {
    statusEl.textContent = "Not recorded yet";
    statusEl.className = "status todo";
  }
  el("saveAttendance").textContent = hasSaved && isDirty ? "Save changes" : "Save attendance";

  el("attendanceList").innerHTML = rosterStudents.length
    ? rosterStudents
        .map((s, i) => {
          const on = draftSet.has(s.id);
          const was = savedIds.has(s.id);
          const info = savedMap.get(s.id);
          const markedLine =
            on && was && info
              ? `<span class="meta meta--marked">Marked by ${escapeHtml(info.coachName)}, ${formatDateTime(
                  info.markedAt
                )}</span>`
              : "";
          const grp = groupName(s.group_id);
          return `<li><button type="button" class="row" data-att="${s.id}" aria-pressed="${on}">
            <span class="avatar" aria-hidden="true">${escapeHtml(initials(s.full_name))}</span>
            <span class="info">
              <span class="name">${escapeHtml(s.full_name)}</span>
              <span class="meta">${grp ? `${escapeHtml(grp)} · ` : ""}${escapeHtml(s.student_code)}</span>
              ${markedLine}
            </span>
            <span class="tick" aria-hidden="true">${TICK_SVG}</span>
          </button></li>`;
        })
        .join("")
    : `<li class="empty">${
        state.students.length ? "No students in this group." : "No active students at this school yet."
      }</li>`;

  const allPresent = rosterStudents.length > 0 && presentCount === rosterStudents.length;
  el("markAllPresent").textContent = allPresent ? "Clear all" : "Mark everyone present";
  el("markAllPresent").setAttribute("aria-pressed", String(allPresent));

  el("attCountText").textContent = `${presentCount} of ${rosterStudents.length}`;
  el("attBarFill").style.width = rosterStudents.length ? `${Math.round((presentCount / rosterStudents.length) * 100)}%` : "0%";
  el("saveAttendance").disabled = !isDirty;
  el("discardAttendance").hidden = !isDirty;
  syncSavebarVisibility();

  el("attendanceLogWrap").hidden = state.attLog.length === 0;
  el("attendanceLogList").innerHTML = state.attLog
    .map((l) => {
      const name = l.student?.full_name || "—";
      const code = l.student?.student_code;
      const verb = l.action === "added" ? "marked" : "removed";
      return `<li><div>${escapeHtml(l.coach?.name || "—")} ${verb} ${escapeHtml(name)}${
        code ? ` (${escapeHtml(code)})` : ""
      }</div><div class="by">${formatDateTime(l.created_at)}</div></li>`;
    })
    .join("");
}

// The save bar belongs to the Attendance tab only.
function syncSavebarVisibility() {
  const onAttendance = currentView() === "today";
  const hasRoster = filteredAttendanceStudents().length > 0;
  el("attSavebar").hidden = !(onAttendance && hasRoster);
  document.body.classList.toggle("has-savebar", onAttendance && hasRoster);
}

el("attPrev").addEventListener("click", () => {
  const d = parseKey(state.attSelectedDate);
  d.setDate(d.getDate() - 1);
  goToAttDate(ymd(d));
});

el("attNext").addEventListener("click", () => {
  if (state.attSelectedDate >= todayKey()) return;
  const d = parseKey(state.attSelectedDate);
  d.setDate(d.getDate() + 1);
  goToAttDate(ymd(d));
});

el("attTodayLink").addEventListener("click", () => goToAttDate(todayKey()));

el("attDatePicker").addEventListener("change", (e) => {
  const v = e.target.value;
  if (!v || v > todayKey()) {
    e.target.value = state.attSelectedDate;
    return;
  }
  goToAttDate(v);
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
  renderSession();
});

el("markAllPresent").addEventListener("click", () => {
  const dateKey = state.attSelectedDate;
  const draft = new Set(attDraftFor(dateKey));
  const rosterStudents = filteredAttendanceStudents();
  const allPresent = rosterStudents.length > 0 && rosterStudents.every((s) => draft.has(s.id));
  if (allPresent) rosterStudents.forEach((s) => draft.delete(s.id));
  else rosterStudents.forEach((s) => draft.add(s.id));
  state.attDrafts.set(dateKey, draft);
  renderSession();
});

el("attGroupFilter").addEventListener("change", renderSession);

el("discardAttendance").addEventListener("click", () => {
  state.attDrafts.delete(state.attSelectedDate);
  renderSession();
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
  await loadAttendanceDate(dateKey);
  renderSession();
  const presentNow = attSavedIds(dateKey).size;
  toast(`Attendance saved: ${presentNow} present`);
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

// --- Progress tab: filters + list ------------------------------------------

function filteredStudents() {
  const group = el("groupFilter").value;
  const q = el("searchFilter").value.trim().toLowerCase();
  return state.students.filter((s) => {
    if (group && s.group_id !== group) return false;
    if (q && !`${s.full_name} ${s.student_code}`.toLowerCase().includes(q)) return false;
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

function renderProgressList() {
  const list = filteredStudents();

  el("studentPicker").innerHTML = list.length
    ? list
        .map((s) => {
          const stats = studentModuleStats(s.id, s.current_module_id);
          const due = feedbackDueForStudent(s.id);
          const badge = due
            ? '<span class="badge due">Feedback due</span>'
            : '<span class="badge done">Feedback done</span>';
          return `<li><button type="button" class="row" data-student="${s.id}">
            <span class="avatar" aria-hidden="true">${escapeHtml(initials(s.full_name))}</span>
            <span class="info">
              <span class="name">${escapeHtml(s.full_name)}</span>
              <span class="meta">${moduleLabel(s.current_module_id)}: ${stats.done} of ${stats.total} · ${escapeHtml(
            s.student_code
          )}</span>
              <span class="mini-bar"><span style="width:${stats.pct}%"></span></span>
            </span>
            ${badge}
            <span class="chev" aria-hidden="true">&rsaquo;</span>
          </button></li>`;
        })
        .join("")
    : `<li class="empty">No students match those filters.</li>`;
}

["groupFilter", "searchFilter"].forEach((id) => {
  el(id).addEventListener("input", renderProgressList);
  el(id).addEventListener("change", renderProgressList);
});

el("studentPicker").addEventListener("click", (e) => {
  const btn = e.target.closest("[data-student]");
  if (!btn) return;
  state.listScroll = window.scrollY;
  state.cameFromList = true;
  location.hash = `student/${btn.getAttribute("data-student")}`;
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

// --- Student detail page ----------------------------------------------------

async function openStudentPage(id) {
  const student = state.students.find((s) => s.id === id);
  if (!student) {
    // Direct/stale link to a student that doesn't exist (or isn't active)
    // on the currently-selected school -- send back to the list instead.
    location.hash = "progress";
    return;
  }

  const isNewStudent = state.selectedStudent !== id;
  state.selectedStudent = id;

  if (isNewStudent) {
    state.moduleId = student.current_module_id;
    state.openUnits = new Set();
    state.closedUnits = new Set();
    state.openTips = new Set();
    state.autosaveNote = "Ticks save as you go.";
    state.studentPane = "checklist";
    state.fbMonthCursor = null;
    state.fbEditingId = null;
    state.ntEditingId = null;
    renderStudentHead(student);
    el("pane-checklist").innerHTML = '<p class="form-message">Loading…</p>';
    await loadStudentNotes(id);
  }

  renderStudentHead(student);
  showStudentPane(state.studentPane);
}

function renderStudentHead(student) {
  el("studentAvatar").textContent = initials(student.full_name);
  el("studentName").textContent = student.full_name;
  el("studentMeta").textContent = `${groupName(student.group_id) || "No group"} · ${student.student_code}`;

  const list = filteredStudents();
  const idx = list.findIndex((s) => s.id === student.id);
  el("studentPos").textContent = idx >= 0 ? `${idx + 1} of ${list.length}` : "";
  el("studentPrevBtn").disabled = idx <= 0;
  el("studentNextBtn").disabled = idx < 0 || idx >= list.length - 1;

  el("fbDueDot").hidden = !feedbackDueForStudent(student.id);
}

function showStudentPane(pane) {
  state.studentPane = pane;
  ["checklist", "feedback", "notes"].forEach((p) => {
    el("studentTabs").querySelector(`[data-pane="${p}"]`).setAttribute("aria-selected", String(p === pane));
    el(`pane-${p}`).hidden = p !== pane;
  });

  const student = state.students.find((s) => s.id === state.selectedStudent);
  if (!student) return;
  if (pane === "checklist") renderChecklistPane(student);
  else if (pane === "feedback") renderFeedbackPane(student);
  else renderNotesPane(student);
}

el("studentTabs").addEventListener("click", (e) => {
  const btn = e.target.closest("[data-pane]");
  if (!btn) return;
  showStudentPane(btn.getAttribute("data-pane"));
});

el("studentBack").addEventListener("click", () => {
  if (state.cameFromList) history.back();
  else location.hash = "progress";
});

function stepStudent(dir) {
  const list = filteredStudents();
  const idx = list.findIndex((s) => s.id === state.selectedStudent);
  const next = list[idx + dir];
  if (!next) return;
  state.cameFromList = true;
  location.replace(`#student/${next.id}`);
}

el("studentPrevBtn").addEventListener("click", () => stepStudent(-1));
el("studentNextBtn").addEventListener("click", () => stepStudent(1));

// --- Student detail: Checklist pane -----------------------------------------

function renderChecklistPane(student) {
  const mod =
    state.curriculum.find((m) => m.id === state.moduleId) ||
    state.curriculum.find((m) => m.id === student.current_module_id);
  if (!mod) {
    el("pane-checklist").innerHTML = "";
    return;
  }

  const modsHtml = state.curriculum
    .map((m) => {
      const s = studentModuleStats(student.id, m.id);
      const complete = s.total > 0 && s.done === s.total;
      const isCurrent = m.id === student.current_module_id;
      const tag = complete ? "✓ Done" : isCurrent ? '<span class="now">Current</span>' : `${s.done}/${s.total}`;
      return `<button type="button" class="mod" role="tab" data-module="${m.id}" aria-selected="${m.id === mod.id}">
        <small><span>Module ${m.number}</span><span>${tag}</span></small>
        <strong>${escapeHtml(m.name)}</strong>
        <span class="mini-bar"><span style="width:${s.pct}%"></span></span>
      </button>`;
    })
    .join("");

  const groupOptions =
    '<option value="">No group</option>' +
    state.groups
      .map(
        (g) =>
          `<option value="${g.id}" ${g.id === student.group_id ? "selected" : ""}>${escapeHtml(g.name)}</option>`
      )
      .join("");

  const unitsHtml = mod.units.map((u) => renderUnit(student, u)).join("");

  el("pane-checklist").innerHTML = `
    <div class="group-row">
      <label for="checklistGroupSelect">Group</label>
      <select id="checklistGroupSelect" aria-label="Group">${groupOptions}</select>
    </div>
    <div class="mods" role="tablist">${modsHtml}</div>
    ${unitsHtml}
    <p class="autosaved">${escapeHtml(state.autosaveNote)}</p>
  `;
}

function tipBoxHtml(item) {
  return `<div class="tip">${escapeHtml(item.how_to_teach || "No teaching note written yet for this item.")}</div>`;
}

function renderUnit(student, unit) {
  const ticks = state.rosterTicks.get(student.id) || new Map();
  const cps = state.rosterCps.get(student.id) || new Map();
  const done = unit.items.filter((it) => ticks.has(it.id)).length;
  const total = unit.items.length;
  const cp = unit.checkpoint;
  const cpMark = cp ? cps.get(cp.id) : null;
  const unitComplete = total > 0 && done === total && (!cp || !!cpMark);

  // Open while unfinished, collapsed once complete -- unless the coach has
  // manually forced it either way.
  let open;
  if (state.closedUnits.has(unit.id)) open = false;
  else if (state.openUnits.has(unit.id)) open = true;
  else open = !unitComplete;

  const rows = unit.items
    .map((it) => {
      const mark = ticks.get(it.id);
      const tipOpen = state.openTips.has(it.id);
      return `<li><div class="item">
        <button type="button" class="row" data-tick-row="${it.id}" aria-pressed="${!!mark}">
          <span class="tick" aria-hidden="true">${TICK_SVG}</span>
          <span class="info">
            <span class="crit">${escapeHtml(it.description)}</span>
            <span class="pass">Pass: ${escapeHtml(it.pass_standard)}</span>
            ${
              mark
                ? `<span class="when">Passed ${formatDate(mark.on)} · ${escapeHtml(mark.coachName)}</span>`
                : '<span class="when none">Not marked</span>'
            }
          </span>
        </button>
        <button type="button" class="tip-btn" data-tip="${it.id}" aria-expanded="${tipOpen}">Tip</button>
      </div>${tipOpen ? tipBoxHtml(it) : ""}</li>`;
    })
    .join("");

  const cpTipOpen = cp ? state.openTips.has(cp.id) : false;
  const cpHtml = cp
    ? `<div class="checkpoint${cpMark ? " is-passed" : ""}">
        <div class="checkpoint__head">
          <span class="checkpoint__title">${cpMark ? "✓ " : ""}Checkpoint</span>
          <button type="button" class="tip-btn" data-tip="${cp.id}" aria-expanded="${cpTipOpen}">Tip</button>
        </div>
        ${cpTipOpen ? tipBoxHtml(cp) : ""}
        <p>${escapeHtml(cp.pass_standard)}</p>
        ${
          cpMark
            ? `<div class="checkpoint__done">Passed ${formatDate(cpMark.on)} · ${escapeHtml(cpMark.coachName)}<br>
                Evidence: ${escapeHtml(cpMark.evidence)}
                <div><button type="button" class="act" data-undocp="${cp.id}">Undo pass</button></div></div>`
            : `<div class="checkpoint__form">
                <input type="text" class="field" data-ev="${cp.id}" placeholder="Evidence: what you observed">
                <button type="button" class="btn-primary sm" data-passcp="${cp.id}">Mark passed</button>
              </div>`
        }
      </div>`
    : "";

  return `<div class="unit">
    <button type="button" class="unit-head" data-unit="${unit.id}" aria-expanded="${open}">
      <h3><span class="num">${escapeHtml(unit.number)}</span> ${escapeHtml(unit.name)}</h3>
      <span class="frac${unitComplete ? " full" : ""}">${unitComplete ? "✓ " : ""}${done}/${total}</span>
      <span class="caret" aria-hidden="true">›</span>
    </button>
    ${open ? `<ul class="items">${rows}</ul>${cpHtml}` : ""}
  </div>`;
}

el("pane-checklist").addEventListener("click", async (e) => {
  const student = state.students.find((s) => s.id === state.selectedStudent);
  if (!student) return;

  const tipBtn = e.target.closest("[data-tip]");
  if (tipBtn) {
    const id = tipBtn.getAttribute("data-tip");
    if (state.openTips.has(id)) state.openTips.delete(id);
    else state.openTips.add(id);
    renderChecklistPane(student);
    return;
  }

  const modBtn = e.target.closest("[data-module]");
  if (modBtn) {
    state.moduleId = modBtn.getAttribute("data-module");
    renderChecklistPane(student);
    return;
  }

  const unitHead = e.target.closest("[data-unit]");
  if (unitHead) {
    const id = unitHead.getAttribute("data-unit");
    const isOpen = unitHead.getAttribute("aria-expanded") === "true";
    if (isOpen) {
      state.openUnits.delete(id);
      state.closedUnits.add(id);
    } else {
      state.closedUnits.delete(id);
      state.openUnits.add(id);
    }
    renderChecklistPane(student);
    return;
  }

  const tickRow = e.target.closest("[data-tick-row]");
  if (tickRow) {
    const itemId = tickRow.getAttribute("data-tick-row");
    const ticks = state.rosterTicks.get(student.id);
    if (ticks && ticks.has(itemId)) {
      // Tapping a ticked row unmarks it. .select() so we can tell a real
      // delete from RLS silently matching zero rows (policy not applied).
      tickRow.disabled = true;
      const { data: removed, error: delError } = await supabase
        .from("item_ticks")
        .delete()
        .eq("student_id", student.id)
        .eq("item_id", itemId)
        .select("id");
      tickRow.disabled = false;
      if (delError || !removed || !removed.length) {
        setStatus("Couldn't unmark that item. Try again.", "error");
        return;
      }
      ticks.delete(itemId);
      state.autosaveNote = "Unmarked. Saved just now.";
      renderStudentHead(student);
      renderChecklistPane(student);
      toast("Unmarked");
      return;
    }
    const { error } = await supabase
      .from("item_ticks")
      .insert({ student_id: student.id, item_id: itemId, marked_by: state.coach.id });
    if (error) {
      setStatus("Couldn't save that tick. Try again.", "error");
      return;
    }
    if (!state.rosterTicks.has(student.id)) state.rosterTicks.set(student.id, new Map());
    state.rosterTicks.get(student.id).set(itemId, { on: todayKey(), coachName: state.coach.name });
    state.autosaveNote = "Saved just now.";
    renderStudentHead(student);
    renderChecklistPane(student);
    return;
  }

  const undoCp = e.target.closest("[data-undocp]");
  if (undoCp) {
    const itemId = undoCp.getAttribute("data-undocp");
    if (!window.confirm("Remove this checkpoint pass and its evidence?")) return;
    undoCp.disabled = true;
    const { data: removed, error: delError } = await supabase
      .from("checkpoint_passes")
      .delete()
      .eq("student_id", student.id)
      .eq("item_id", itemId)
      .select("id");
    undoCp.disabled = false;
    if (delError || !removed || !removed.length) {
      setStatus("Couldn't undo that checkpoint. Try again.", "error");
      return;
    }
    state.rosterCps.get(student.id)?.delete(itemId);
    renderChecklistPane(student);
    toast("Checkpoint pass removed");
    return;
  }

  const passCp = e.target.closest("[data-passcp]");
  if (passCp) {
    const itemId = passCp.getAttribute("data-passcp");
    const input = el("pane-checklist").querySelector(`[data-ev="${itemId}"]`);
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
    renderChecklistPane(student);
  }
});

el("pane-checklist").addEventListener("change", async (e) => {
  const groupSelect = e.target.closest("#checklistGroupSelect");
  if (!groupSelect) return;
  const student = state.students.find((s) => s.id === state.selectedStudent);
  if (!student) return;

  const newGroupId = groupSelect.value || null;
  const previousGroupId = student.group_id;
  groupSelect.disabled = true;
  const { error } = await supabase.from("students").update({ group_id: newGroupId }).eq("id", student.id);
  groupSelect.disabled = false;
  if (error) {
    setStatus("Couldn't change that student's group. Try again.", "error");
    groupSelect.value = previousGroupId || "";
    return;
  }
  student.group_id = newGroupId;
  // If the active group filter would now hide the student we just reassigned,
  // widen it back to "All groups" so the Progress list doesn't silently drop them.
  const groupFilterEl = el("groupFilter");
  if (groupFilterEl.value && groupFilterEl.value !== newGroupId) {
    groupFilterEl.value = "";
  }
  renderProgressList();
  renderStudentHead(student);
  toast("Group updated");
});

// --- Student detail: Feedback pane ------------------------------------------

function starsHtml(value) {
  return [1, 2, 3, 4, 5]
    .map(
      (n) =>
        `<button type="button" class="star${n <= value ? " on" : ""}" data-star="${n}" role="radio"
          aria-checked="${n === value}" aria-label="${n} of 5">★</button>`
    )
    .join("");
}

function feedbackEntryHtml(f) {
  return `<li>
    <div><strong>${escapeHtml(f.coach?.name || "—")}</strong>, ${formatDate(f.created_at)}${
    f.rating
      ? `<span class="entry-stars" aria-label="${f.rating} out of 5 stars">${"★".repeat(f.rating)}${"☆".repeat(
          5 - f.rating
        )}</span>`
      : ""
  }</div>
    ${
      f.highlight || f.next_focus
        ? `<div class="entry-tags">
            ${f.highlight ? `<div class="hl"><b>Highlight:</b> ${escapeHtml(f.highlight)}</div>` : ""}
            ${f.next_focus ? `<div class="tg"><b>Next month's target:</b> ${escapeHtml(f.next_focus)}</div>` : ""}
          </div>`
        : ""
    }
    <div class="body" style="margin-top:8px">${escapeHtml(f.body)}</div>
    <div class="entry-actions">
      <button type="button" class="act" data-fbedit="${f.id}">Edit</button>
      <button type="button" class="act act--danger" data-fbdelete="${f.id}">Delete</button>
    </div>
  </li>`;
}

function renderFeedbackPane(student) {
  if (!state.fbMonthCursor) {
    state.fbMonthCursor = state.feedback.length ? String(state.feedback[0].month).slice(0, 7) : thisMonthKey();
  }
  const cursor = state.fbMonthCursor;
  const monthEntries = state.feedback.filter((f) => String(f.month).slice(0, 7) === cursor);
  const editingEntry = state.fbEditingId ? state.feedback.find((f) => f.id === state.fbEditingId) : null;
  const canGoNext = cursor < thisMonthKey();
  const latest = monthEntries[0];
  const firstName = student.full_name.split(" ")[0];
  const rating = editingEntry ? editingEntry.rating || 0 : 0;

  let statusText = "Not written yet.";
  let statusCls = "f-status";
  if (editingEntry) statusText = "Editing this entry.";
  else if (latest) {
    statusText = `Saved ${formatDate(latest.created_at)}. Visible to the student.`;
    statusCls = "f-status ok";
  }

  el("pane-feedback").innerHTML = `
    <div class="card">
      <div class="month-row">
        <button type="button" class="arrow" id="fbMonthPrev" aria-label="Previous month">&lsaquo;</button>
        <h3 class="serif">${escapeHtml(formatMonth(`${cursor}-01`))}</h3>
        <button type="button" class="arrow" id="fbMonthNext" aria-label="Next month" ${canGoNext ? "" : "disabled"}>&rsaquo;</button>
      </div>
      <p class="vis-note">The student reads this, so write it to them.</p>

      <label class="f-label first" for="fbText">Monthly summary</label>
      <textarea id="fbText" placeholder="How did ${escapeHtml(firstName)} do this month? Write it to them.">${
        editingEntry ? escapeHtml(editingEntry.body) : ""
      }</textarea>

      <span class="f-label">Effort and growth this month</span>
      <div class="stars" id="fbRating" data-value="${rating}" role="radiogroup" aria-label="Effort and growth">${starsHtml(
    rating
  )}</div>

      <label class="f-label" for="fbHighlight">This month's highlight <span>(optional)</span></label>
      <input class="field" id="fbHighlight" maxlength="120"
        value="${editingEntry ? escapeHtml(editingEntry.highlight || "") : ""}"
        placeholder="E.g. Won their first practice game">

      <label class="f-label" for="fbFocus">Next month's target <span>(optional)</span></label>
      <input class="field" id="fbFocus" maxlength="120"
        value="${editingEntry ? escapeHtml(editingEntry.next_focus || "") : ""}"
        placeholder="E.g. Opening principles and simple tactics">

      <div class="f-actions">
        <button type="button" class="btn-primary" id="fbSave">${editingEntry ? "Update feedback" : "Save feedback"}</button>
        ${editingEntry ? '<button type="button" class="btn-ghost" id="fbCancelEdit">Cancel</button>' : ""}
        <span class="${statusCls}" id="fbSaveNote">${statusText}</span>
      </div>
    </div>
    ${monthEntries.length ? `<ul class="notes">${monthEntries.map(feedbackEntryHtml).join("")}</ul>` : ""}
  `;
}

el("pane-feedback").addEventListener("click", async (e) => {
  const student = state.students.find((s) => s.id === state.selectedStudent);
  if (!student) return;

  if (e.target.closest("#fbMonthPrev")) {
    const [y, m] = state.fbMonthCursor.split("-").map(Number);
    const d = new Date(y, m - 2, 1);
    state.fbEditingId = null;
    state.fbMonthCursor = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
    renderFeedbackPane(student);
    return;
  }

  const nextBtn = e.target.closest("#fbMonthNext");
  if (nextBtn && !nextBtn.disabled) {
    const [y, m] = state.fbMonthCursor.split("-").map(Number);
    const d = new Date(y, m, 1);
    state.fbEditingId = null;
    state.fbMonthCursor = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
    renderFeedbackPane(student);
    return;
  }

  if (e.target.closest("#fbCancelEdit")) {
    state.fbEditingId = null;
    renderFeedbackPane(student);
    return;
  }

  const fbEditBtn = e.target.closest("[data-fbedit]");
  if (fbEditBtn) {
    state.fbEditingId = fbEditBtn.getAttribute("data-fbedit");
    renderFeedbackPane(student);
    return;
  }

  const fbDeleteBtn = e.target.closest("[data-fbdelete]");
  if (fbDeleteBtn) {
    const id = fbDeleteBtn.getAttribute("data-fbdelete");
    const entry = state.feedback.find((f) => f.id === id);
    const sure = window.confirm(
      `Delete the ${entry ? formatMonth(entry.month) : ""} feedback for ${student.full_name}? This can't be undone.`
    );
    if (!sure) return;
    fbDeleteBtn.disabled = true;
    const { error } = await supabase.from("feedback").delete().eq("id", id);
    if (error) {
      fbDeleteBtn.disabled = false;
      setStatus("Couldn't delete that feedback entry. Try again.", "error");
      return;
    }
    if (state.fbEditingId === id) state.fbEditingId = null;
    await loadStudentNotes(student.id);
    await loadRosterFeedbackMonths(state.students.map((s) => s.id));
    renderProgressList();
    renderStudentHead(student);
    renderFeedbackPane(student);
    return;
  }

  // Handled with a direct DOM update, not a re-render, so clicking a star
  // doesn't wipe whatever the coach has already typed into the textarea
  // or the highlight/focus fields in the same form.
  const starBtn = e.target.closest("[data-star]");
  if (starBtn) {
    const value = Number(starBtn.getAttribute("data-star"));
    const row = starBtn.closest(".stars");
    const already = Number(row.dataset.value) === value;
    const next = already ? 0 : value; // click the same star again to clear
    row.dataset.value = String(next);
    row.querySelectorAll("[data-star]").forEach((btn) => {
      const n = Number(btn.getAttribute("data-star"));
      btn.classList.toggle("on", n <= next);
      btn.setAttribute("aria-checked", String(n === next));
    });
    return;
  }

  if (e.target.id === "fbSave") {
    const text = el("fbText").value.trim();
    if (!text) {
      el("fbText").focus();
      return;
    }
    const monthDate = `${state.fbMonthCursor}-01`;
    const ratingValue = Number(el("fbRating")?.dataset.value) || null;
    const highlight = el("fbHighlight")?.value.trim() || null;
    const nextFocus = el("fbFocus")?.value.trim() || null;
    const editingId = state.fbEditingId;
    e.target.disabled = true;

    const payload = {
      student_id: student.id,
      coach_id: state.coach.id,
      month: monthDate,
      body: text,
      rating: ratingValue,
      highlight,
      next_focus: nextFocus,
    };
    const { error } = editingId
      ? await supabase.from("feedback").update(payload).eq("id", editingId)
      : await supabase.from("feedback").insert(payload);

    e.target.disabled = false;
    if (error) {
      setStatus(editingId ? "Couldn't update feedback. Try again." : "Couldn't save feedback. Try again.", "error");
      return;
    }
    if (editingId) {
      state.fbEditingId = null;
      await loadRosterFeedbackMonths(state.students.map((s) => s.id));
    } else {
      if (!state.rosterFeedbackMonths.has(student.id)) state.rosterFeedbackMonths.set(student.id, []);
      state.rosterFeedbackMonths.get(student.id).push(monthDate);
    }
    await loadStudentNotes(student.id);
    renderProgressList();
    renderStudentHead(student);
    renderFeedbackPane(student);
    toast("Feedback saved");
  }
});

// --- Student detail: Notes pane ---------------------------------------------

function renderNotesPane(student) {
  const editingNote = state.ntEditingId ? state.notes.find((n) => n.id === state.ntEditingId) : null;

  const list = state.notes.length
    ? state.notes
        .map(
          (n) => `<li>
            <div class="body">${escapeHtml(n.body)}</div>
            <div class="by">${escapeHtml(n.coach?.name || "—")}, ${formatDate(n.created_at)}</div>
            <div class="entry-actions">
              <button type="button" class="act" data-ntedit="${n.id}">Edit</button>
              <button type="button" class="act act--danger" data-ntdelete="${n.id}">Delete</button>
            </div>
          </li>`
        )
        .join("")
    : '<li class="empty">No notes yet.</li>';

  el("pane-notes").innerHTML = `
    <div class="card">
      <label class="f-label first" for="ntText">${editingNote ? "Edit note" : "Add a note"}</label>
      <p class="vis-note vis-note--left">Only coaches see these. Use them for handovers between instructors.</p>
      <textarea id="ntText" placeholder="E.g. Gets frustrated after losses, give them a quick win to start the session.">${
        editingNote ? escapeHtml(editingNote.body) : ""
      }</textarea>
      <div class="f-actions">
        <button type="button" class="btn-primary" id="ntSave">${editingNote ? "Update note" : "Add note"}</button>
        ${editingNote ? '<button type="button" class="btn-ghost" id="ntCancelEdit">Cancel</button>' : ""}
      </div>
    </div>
    <ul class="notes">${list}</ul>
  `;
}

el("pane-notes").addEventListener("click", async (e) => {
  const student = state.students.find((s) => s.id === state.selectedStudent);
  if (!student) return;

  if (e.target.closest("#ntCancelEdit")) {
    state.ntEditingId = null;
    renderNotesPane(student);
    return;
  }

  const ntEditBtn = e.target.closest("[data-ntedit]");
  if (ntEditBtn) {
    state.ntEditingId = ntEditBtn.getAttribute("data-ntedit");
    renderNotesPane(student);
    return;
  }

  const ntDeleteBtn = e.target.closest("[data-ntdelete]");
  if (ntDeleteBtn) {
    const id = ntDeleteBtn.getAttribute("data-ntdelete");
    const sure = window.confirm(`Delete this note about ${student.full_name}? This can't be undone.`);
    if (!sure) return;
    ntDeleteBtn.disabled = true;
    const { error } = await supabase.from("coach_notes").delete().eq("id", id);
    if (error) {
      ntDeleteBtn.disabled = false;
      setStatus("Couldn't delete that note. Try again.", "error");
      return;
    }
    if (state.ntEditingId === id) state.ntEditingId = null;
    await loadStudentNotes(student.id);
    renderNotesPane(student);
    return;
  }

  if (e.target.id === "ntSave") {
    const text = el("ntText").value.trim();
    if (!text) {
      el("ntText").focus();
      return;
    }
    const editingId = state.ntEditingId;
    e.target.disabled = true;
    const { error } = editingId
      ? await supabase.from("coach_notes").update({ body: text, coach_id: state.coach.id }).eq("id", editingId)
      : await supabase.from("coach_notes").insert({ student_id: student.id, coach_id: state.coach.id, body: text });
    e.target.disabled = false;
    if (error) {
      setStatus(editingId ? "Couldn't update the note. Try again." : "Couldn't save the note. Try again.", "error");
      return;
    }
    state.ntEditingId = null;
    await loadStudentNotes(student.id);
    renderNotesPane(student);
    toast(editingId ? "Note updated" : "Note added");
  }
});

// --- Syllabus tab: read-only teaching reference -----------------------------
//
// Presents the same modules/units/items as the Progress-tab checklist, but as
// a reference "book" rather than something to tick off: each item expands to
// show how to teach it, how to check it, puzzles to use, and assignments to
// give. Only Module 1 has this content written so far (see sql/021); items
// without it show a plain "not written yet" placeholder rather than blanks.

function renderSyllabus() {
  if (!state.curriculum.length) {
    el("syllabusModuleTabs").innerHTML = "";
    el("syllabusUnits").innerHTML = "";
    return;
  }
  if (!state.syllabusModuleId) state.syllabusModuleId = state.curriculum[0].id;
  const mod = state.curriculum.find((m) => m.id === state.syllabusModuleId) || state.curriculum[0];

  el("syllabusModuleTabs").innerHTML = state.curriculum
    .map(
      (m) =>
        `<button type="button" class="module-tab" data-syllabus-module="${m.id}" aria-selected="${m.id === mod.id}">
          Module ${m.number} · ${escapeHtml(m.name)}
        </button>`
    )
    .join("");

  el("syllabusUnits").innerHTML = mod.units.map((u) => renderSyllabusUnit(u)).join("");
}

function renderSyllabusUnit(unit) {
  const open = state.syllabusOpenUnits.has(unit.id);
  const allItems = unit.checkpoint ? [...unit.items, unit.checkpoint] : unit.items;
  const rows = allItems.map((it) => renderSyllabusItem(it)).join("");

  return `<div class="unit">
    <button type="button" class="unit__head" data-syllabus-unit="${unit.id}">
      <span class="unit__name">${escapeHtml(unit.number)} — ${escapeHtml(unit.name)}</span>
      <span class="unit__count">${allItems.length} item${allItems.length === 1 ? "" : "s"}</span>
    </button>
    <div class="unit__body" ${open ? "" : "hidden"}>${rows}</div>
  </div>`;
}

function renderSyllabusItem(item) {
  const open = state.syllabusOpenItems.has(item.id);
  const hasContent = item.how_to_teach || item.how_to_check || item.puzzles || item.assignments;

  const body = hasContent
    ? `<div class="syllabus-section"><h5>How to teach it</h5><p>${escapeHtml(item.how_to_teach || "—")}</p></div>
       <div class="syllabus-section"><h5>How to check it</h5><p>${escapeHtml(item.how_to_check || "—")}</p></div>
       <div class="syllabus-section"><h5>Puzzles</h5><p>${escapeHtml(item.puzzles || "—")}</p></div>
       <div class="syllabus-section"><h5>Assignments</h5><p>${escapeHtml(item.assignments || "—")}</p></div>`
    : `<p class="empty-state">Detailed syllabus content for this item hasn't been written yet.</p>`;

  return `<div class="syllabus-item${item.is_checkpoint ? " syllabus-item--checkpoint" : ""}" data-syllabus-item="${item.id}">
    <button type="button" class="syllabus-item__head" data-syllabus-item-toggle="${item.id}" aria-expanded="${open}">
      <span class="syllabus-item__text">
        ${item.is_checkpoint ? '<span class="syllabus-item__badge">Checkpoint</span>' : ""}${escapeHtml(item.description)}
        <span class="curriculum-item__pass">Pass: ${escapeHtml(item.pass_standard)}</span>
      </span>
      <span class="syllabus-item__chevron" aria-hidden="true">${open ? "▾" : "▸"}</span>
    </button>
    <div class="syllabus-item__body" ${open ? "" : "hidden"}>${body}</div>
  </div>`;
}

el("syllabusModuleTabs").addEventListener("click", (e) => {
  const btn = e.target.closest("[data-syllabus-module]");
  if (!btn) return;
  state.syllabusModuleId = btn.getAttribute("data-syllabus-module");
  renderSyllabus();
});

el("syllabusUnits").addEventListener("click", (e) => {
  const unitHead = e.target.closest("[data-syllabus-unit]");
  if (unitHead) {
    const id = unitHead.getAttribute("data-syllabus-unit");
    if (state.syllabusOpenUnits.has(id)) state.syllabusOpenUnits.delete(id);
    else state.syllabusOpenUnits.add(id);
    renderSyllabus();
    return;
  }

  const itemToggle = e.target.closest("[data-syllabus-item-toggle]");
  if (itemToggle) {
    const id = itemToggle.getAttribute("data-syllabus-item-toggle");
    if (state.syllabusOpenItems.has(id)) state.syllabusOpenItems.delete(id);
    else state.syllabusOpenItems.add(id);
    renderSyllabus();
  }
});

// --- Top-level routing (hash-based) -----------------------------------------
//
// #today | #progress | #syllabus select a main tab; #student/<id> opens the
// student detail page as its own "screen" with real browser history, so the
// phone/browser back button and swipe-back gesture both work naturally.

function currentView() {
  const raw = location.hash.slice(1);
  if (raw.startsWith("student/")) return "student";
  return ["today", "progress", "syllabus"].includes(raw) ? raw : "today";
}

function route() {
  const raw = location.hash.slice(1);
  const studentMatch = raw.match(/^student\/(.+)$/);

  if (studentMatch) {
    el("siteHeader").hidden = true;
    el("schoolSelect").hidden = true;
    el("mainTabs").hidden = true;
    el("panelStudent").hidden = false;
    el("panelToday").hidden = true;
    el("panelProgress").hidden = true;
    el("panelSyllabus").hidden = true;
    syncSavebarVisibility();
    openStudentPage(decodeURIComponent(studentMatch[1]));
    window.scrollTo(0, 0);
    return;
  }

  el("siteHeader").hidden = false;
  el("schoolSelect").hidden = !state.isAdmin;
  el("mainTabs").hidden = false;
  el("panelStudent").hidden = true;

  const tab = ["today", "progress", "syllabus"].includes(raw) ? raw : "today";
  el("tabToday").setAttribute("aria-selected", String(tab === "today"));
  el("tabProgress").setAttribute("aria-selected", String(tab === "progress"));
  el("tabSyllabus").setAttribute("aria-selected", String(tab === "syllabus"));
  el("panelToday").hidden = tab !== "today";
  el("panelProgress").hidden = tab !== "progress";
  el("panelSyllabus").hidden = tab !== "syllabus";

  if (tab === "syllabus") renderSyllabus();
  syncSavebarVisibility();

  if (tab === "progress" && state.listScroll != null) {
    const y = state.listScroll;
    state.listScroll = null;
    requestAnimationFrame(() => window.scrollTo(0, y));
  }
}

window.addEventListener("hashchange", route);

el("tabToday").addEventListener("click", () => {
  location.hash = "today";
});
el("tabProgress").addEventListener("click", () => {
  location.hash = "progress";
});
el("tabSyllabus").addEventListener("click", () => {
  location.hash = "syllabus";
});

el("signOutButton").addEventListener("click", async () => {
  await supabase.auth.signOut();
  window.location.replace("login.html");
});

init();
