import { supabase } from "./supabase.js";
import { escapeHtml, formatDate, formatMonth } from "./utils.js";

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
  sessionId: null,
  attendance: new Map(), // student_id -> boolean
};

function setStatus(text, kind) {
  el("status").textContent = text;
  el("status").className = kind ? `form-message form-message--${kind}` : "form-message";
}

function thisMonthKey() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
}

function todayKey() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
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
  await loadTodayTab();
}

async function loadGroups() {
  const { data } = await supabase
    .from("school_groups")
    .select("id, name")
    .eq("school_id", state.schoolId)
    .order("name");
  state.groups = data || [];
  el("groupFilter").innerHTML =
    '<option value="">All groups</option>' +
    state.groups.map((g) => `<option value="${g.id}">${escapeHtml(g.name)}</option>`).join("");
}

async function loadStudents() {
  const { data, error } = await supabase
    .from("students")
    .select("id, full_name, student_code, category, group_id, current_module_id, must_change_password, active")
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

// --- Today tab: attendance -------------------------------------------------

async function ensureTodaySession(schoolId) {
  const today = todayKey();
  const { data: rows, error: selErr } = await supabase
    .from("class_sessions")
    .select("id")
    .eq("school_id", schoolId)
    .is("group_id", null)
    .eq("session_date", today)
    .order("id")
    .limit(1);
  if (selErr) throw selErr;
  if (rows && rows.length) return rows[0].id;

  const { data: created, error: insErr } = await supabase
    .from("class_sessions")
    .insert({ school_id: schoolId, group_id: null, session_date: today, coach_id: state.coach.id })
    .select("id")
    .single();
  if (insErr) throw insErr;
  return created.id;
}

async function loadTodayTab() {
  el("statCount").textContent = state.students.length;
  el("statPending").textContent = state.students.filter((s) => s.must_change_password).length;

  try {
    state.sessionId = await ensureTodaySession(state.schoolId);
  } catch {
    setStatus("Couldn't load today's attendance. Refresh to try again.", "error");
    el("attendanceList").innerHTML = "";
    el("statPresent").textContent = "—";
    return;
  }

  const { data: attRows } = await supabase
    .from("attendance")
    .select("student_id, present")
    .eq("session_id", state.sessionId);
  state.attendance = new Map((attRows || []).map((r) => [r.student_id, r.present]));
  renderAttendance();
}

function renderAttendance() {
  const present = state.students.filter((s) => state.attendance.get(s.id)).length;
  el("statPresent").textContent = `${present} / ${state.students.length}`;

  el("attendanceList").innerHTML = state.students.length
    ? state.students
        .map((s) => {
          const isPresent = !!state.attendance.get(s.id);
          return `<li class="roster-row">
            <button type="button" class="attend-btn" data-att="${s.id}" aria-pressed="${isPresent}"
              aria-label="Mark ${escapeHtml(s.full_name)} present">✓</button>
            <span class="roster-row__name">${escapeHtml(s.full_name)}
              <span class="roster-row__sub">${escapeHtml(s.student_code)}</span>
            </span>
          </li>`;
        })
        .join("")
    : `<p class="empty-state">No active students at this school yet.</p>`;
}

el("attendanceList").addEventListener("click", async (e) => {
  const btn = e.target.closest("[data-att]");
  if (!btn || !state.sessionId) return;
  const studentId = btn.getAttribute("data-att");
  const next = !state.attendance.get(studentId);

  btn.disabled = true;
  const { error } = await supabase
    .from("attendance")
    .upsert({ session_id: state.sessionId, student_id: studentId, present: next }, { onConflict: "session_id,student_id" });
  btn.disabled = false;

  if (error) {
    setStatus("Couldn't save attendance. Try again.", "error");
    return;
  }
  state.attendance.set(studentId, next);
  renderAttendance();
});

// --- Progress tab: filters + picker ---------------------------------------

function filteredStudents() {
  const group = el("groupFilter").value;
  const cat = el("categoryFilter").value;
  const q = el("searchFilter").value.trim().toLowerCase();
  return state.students.filter((s) => {
    if (group && s.group_id !== group) return false;
    if (cat && s.category !== cat) return false;
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
        .map((s) => {
          const stats = studentModuleStats(s.id, s.current_module_id);
          const due = feedbackDueForStudent(s.id);
          return `<button type="button" class="picker__item" data-student="${s.id}" aria-pressed="${
            state.selectedStudent === s.id
          }">${escapeHtml(s.full_name)}
            <small>${escapeHtml(s.student_code)} · ${moduleLabel(s.current_module_id)} ${stats.pct}%${
            due ? ' · <span class="picker__due">summary due</span>' : ""
          }</small>
          </button>`;
        })
        .join("")
    : `<p class="empty-state">No students match those filters.</p>`;

  if (state.selectedStudent && !list.some((s) => s.id === state.selectedStudent)) {
    state.selectedStudent = null;
    el("checklistWrap").innerHTML = "";
  }
}

["groupFilter", "categoryFilter", "searchFilter"].forEach((id) => {
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
      .select("id, month, body, created_at, coach:coaches(name)")
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

  const form =
    showing === "feedback"
      ? `<textarea id="fbText" placeholder="Monthly summary for ${escapeHtml(
          student.full_name
        )}. They will read this, so write it to them."></textarea>
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
              )}</div>
                <div class="entry__body">${escapeHtml(f.body)}</div>
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

  if (e.target.id === "fbSave") {
    const text = el("fbText").value.trim();
    if (!text) {
      el("fbText").focus();
      return;
    }
    const monthDate = `${el("fbMonth").value}-01`;
    e.target.disabled = true;
    const { error } = await supabase
      .from("feedback")
      .insert({ student_id: student.id, coach_id: state.coach.id, month: monthDate, body: text });
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
