import { supabase } from "./supabase.js";
import { escapeHtml, formatDate } from "./utils.js";

const el = (id) => document.getElementById(id);

const state = {
  accessToken: null,
  schools: [],
  schoolCounts: new Map(), // school_id -> {students, coaches}
  modules: [],
  groupsBySchool: new Map(), // school_id -> [{id,name}]
  students: [],
  coaches: [],
  editingSchoolId: null,
  editingStudentId: null,
  selfId: null,
};

function setStatus(text, kind) {
  el("status").textContent = text;
  el("status").className = kind ? `form-message form-message--${kind}` : "form-message";
}

function setFormMessage(id, text, kind) {
  const box = el(id);
  box.textContent = text;
  box.className = kind ? `form-message form-message--${kind}` : "form-message";
}

async function callApi(path, body) {
  const res = await fetch(`/api/admin/${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${state.accessToken}`,
    },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || "Something went wrong. Try again.");
  return data;
}

function passwordBanner({ title, lines }) {
  return `<div class="pw-banner">
    <div class="pw-banner__title">${escapeHtml(title)}</div>
    ${lines
      .map(
        (l) =>
          `<div class="pw-banner__line"><span>${escapeHtml(l.label)}</span><code>${escapeHtml(l.value)}</code></div>`
      )
      .join("")}
    <p class="pw-banner__hint">Shown once — write it down now. There is no way to look it up again.</p>
  </div>`;
}

// --- Boot -------------------------------------------------------------

async function init() {
  const { data: sessionData } = await supabase.auth.getSession();
  if (!sessionData?.session) {
    window.location.href = "login.html";
    return;
  }
  state.accessToken = sessionData.session.access_token;

  const uid = sessionData.session.user.id;
  state.selfId = uid;
  const { data: coachRow, error } = await supabase
    .from("coaches")
    .select("id, name, role, active")
    .eq("id", uid)
    .single();

  if (error || !coachRow || !coachRow.active) {
    await supabase.auth.signOut();
    window.location.href = "login.html";
    return;
  }
  if (coachRow.role !== "admin") {
    window.location.href = "coach.html";
    return;
  }

  el("roleLine").textContent = `${coachRow.name} · Admin · all schools`;

  await Promise.all([loadSchools(), loadModules()]);
  await loadSchoolCounts();
  renderSchoolList();
  populateSchoolSelects();

  if (state.schools.length) {
    await onStudentsSchoolChange();
    await loadCoaches();
  }
}

async function loadSchools() {
  const { data } = await supabase
    .from("schools")
    .select("id, name, location, prefix")
    .order("name");
  state.schools = data || [];
}

async function loadModules() {
  const { data } = await supabase.from("modules").select("id, number, name").order("number");
  state.modules = data || [];
  const options = state.modules
    .map((m) => `<option value="${m.id}">Module ${m.number} · ${escapeHtml(m.name)}</option>`)
    .join("");
  el("stuModule").innerHTML = options;
}

async function loadGroupsForSchool(schoolId) {
  if (state.groupsBySchool.has(schoolId)) return state.groupsBySchool.get(schoolId);
  const { data } = await supabase
    .from("school_groups")
    .select("id, name")
    .eq("school_id", schoolId)
    .order("name");
  const groups = data || [];
  state.groupsBySchool.set(schoolId, groups);
  return groups;
}

function populateSchoolSelects() {
  const options = state.schools
    .map((s) => `<option value="${s.id}">${escapeHtml(s.name)} (${escapeHtml(s.prefix)})</option>`)
    .join("");
  el("stuSchoolFilter").innerHTML = options;
  el("stuSchool").innerHTML = options;
  el("coachSchool").innerHTML = options;
}

el("signOutButton").addEventListener("click", async () => {
  await supabase.auth.signOut();
  window.location.href = "login.html";
});

// --- Top-level tabs -----------------------------------------------------

function selectTab(name) {
  const tabs = { schools: "tabSchools", students: "tabStudents", coaches: "tabCoaches" };
  const panels = { schools: "panelSchools", students: "panelStudents", coaches: "panelCoaches" };
  for (const key of Object.keys(tabs)) {
    el(tabs[key]).setAttribute("aria-selected", String(key === name));
    el(panels[key]).hidden = key !== name;
  }
}

el("tabSchools").addEventListener("click", async () => {
  selectTab("schools");
  await loadSchoolCounts();
  renderSchoolList();
});
el("tabStudents").addEventListener("click", () => selectTab("students"));
el("tabCoaches").addEventListener("click", () => selectTab("coaches"));

// --- Schools --------------------------------------------------------------

async function loadSchoolCounts() {
  const [{ data: students }, { data: coaches }] = await Promise.all([
    supabase.from("students").select("school_id"),
    supabase.from("coaches").select("school_id"),
  ]);
  const counts = new Map();
  for (const s of state.schools) counts.set(s.id, { students: 0, coaches: 0 });
  for (const row of students || []) {
    const c = counts.get(row.school_id);
    if (c) c.students++;
  }
  for (const row of coaches || []) {
    if (!row.school_id) continue; // admin accounts have no school
    const c = counts.get(row.school_id);
    if (c) c.coaches++;
  }
  state.schoolCounts = counts;
}

function renderSchoolList() {
  el("schoolList").innerHTML = state.schools.length
    ? state.schools.map((s) => renderSchoolCard(s)).join("")
    : `<p class="empty-state">No schools yet — add the first one below.</p>`;

  state.schools.forEach(async (s) => {
    const groups = await loadGroupsForSchool(s.id);
    const target = document.querySelector(`[data-groups-for="${s.id}"]`);
    if (target) target.innerHTML = renderGroupsBlock(s.id, groups);
  });
}

function renderGroupsBlock(schoolId, groups) {
  const chips = groups.length
    ? groups
        .map(
          (g) => `<span class="group-chip">${escapeHtml(g.name)}
        <button type="button" class="group-chip__remove" data-remove-group="${g.id}" data-remove-group-school="${schoolId}" aria-label="Remove ${escapeHtml(
            g.name
          )}">&times;</button>
      </span>`
        )
        .join("")
    : `<span class="field__hint">No groups yet</span>`;

  return `<div class="group-chips">${chips}</div>
    <form class="group-add-form" data-add-group-school="${schoolId}">
      <input type="text" class="group-add-input" placeholder="New group name" required>
      <button type="submit" class="btn btn--secondary btn--xs">Add group</button>
    </form>`;
}

async function refreshGroupsForSchool(schoolId) {
  state.groupsBySchool.delete(schoolId);
  const groups = await loadGroupsForSchool(schoolId);
  const target = document.querySelector(`[data-groups-for="${schoolId}"]`);
  if (target) target.innerHTML = renderGroupsBlock(schoolId, groups);

  if (el("stuSchoolFilter").value === schoolId) {
    const groupOptions = groups.map((g) => `<option value="${g.id}">${escapeHtml(g.name)}</option>`).join("");
    el("stuGroupFilter").innerHTML = '<option value="">All groups</option>' + groupOptions;
    el("stuGroup").innerHTML = '<option value="">No group</option>' + groupOptions;
  }
  return groups;
}

function renderSchoolCard(s) {
  const counts = state.schoolCounts.get(s.id) || { students: 0, coaches: 0 };
  const empty = counts.students === 0 && counts.coaches === 0;
  const groupsSection = `<div class="entity-card__groups" data-groups-for="${s.id}">Loading groups…</div>`;

  if (state.editingSchoolId === s.id) {
    return `<div class="entity-card">
      <div class="field">
        <label for="editSchName">Name</label>
        <input type="text" id="editSchName" value="${escapeHtml(s.name)}">
      </div>
      <div class="field">
        <label for="editSchLocation">Location</label>
        <input type="text" id="editSchLocation" value="${escapeHtml(s.location || "")}">
      </div>
      <p class="field__hint">ID prefix <strong>${escapeHtml(s.prefix)}</strong> can't be changed here.</p>
      <div class="entity-card__actions">
        <button type="button" class="btn btn--primary btn--xs" data-save-school="${s.id}">Save</button>
        <button type="button" class="btn btn--secondary btn--xs" data-cancel-school-edit="1">Cancel</button>
      </div>
      ${groupsSection}
    </div>`;
  }

  return `<div class="entity-card">
    <h3>${escapeHtml(s.name)}</h3>
    <p>${escapeHtml(s.location || "—")} · ID prefix <strong>${escapeHtml(s.prefix)}</strong></p>
    ${groupsSection}
    <div class="entity-card__actions">
      <button type="button" class="btn btn--secondary btn--xs" data-edit-school="${s.id}">Edit</button>
      <button type="button" class="btn btn--secondary btn--xs" data-delete-school="${s.id}" ${empty ? "" : "disabled"}
        title="${empty ? "Delete this school" : "Remove every student and coach from it first"}">Delete</button>
    </div>
  </div>`;
}

el("schoolList").addEventListener("click", async (e) => {
  const editBtn = e.target.closest("[data-edit-school]");
  if (editBtn) {
    state.editingSchoolId = editBtn.getAttribute("data-edit-school");
    renderSchoolList();
    return;
  }

  const cancelBtn = e.target.closest("[data-cancel-school-edit]");
  if (cancelBtn) {
    state.editingSchoolId = null;
    renderSchoolList();
    return;
  }

  const saveBtn = e.target.closest("[data-save-school]");
  if (saveBtn) {
    const schoolId = saveBtn.getAttribute("data-save-school");
    const name = el("editSchName").value.trim();
    const location = el("editSchLocation").value.trim();

    if (!name) {
      setStatus("School name is required.", "error");
      return;
    }

    saveBtn.disabled = true;
    const { error } = await supabase
      .from("schools")
      .update({ name, location: location || null })
      .eq("id", schoolId);
    saveBtn.disabled = false;

    if (error) {
      setStatus("Couldn't save that school. Try again.", "error");
      return;
    }

    state.editingSchoolId = null;
    await loadSchools();
    populateSchoolSelects();
    renderSchoolList();
    setStatus("School updated.", "success");
    return;
  }

  const deleteBtn = e.target.closest("[data-delete-school]");
  if (deleteBtn && !deleteBtn.disabled) {
    const schoolId = deleteBtn.getAttribute("data-delete-school");
    const school = state.schools.find((s) => s.id === schoolId);
    if (!school) return;

    const sure = window.confirm(`Permanently delete ${school.name}? This can't be undone.`);
    if (!sure) return;

    deleteBtn.disabled = true;
    try {
      await callApi("delete-school", { schoolId });
      await loadSchools();
      populateSchoolSelects();
      await loadSchoolCounts();
      renderSchoolList();
      await onStudentsSchoolChange();
      setStatus(`${school.name} deleted.`, "success");
    } catch (err) {
      setStatus(err.message, "error");
      deleteBtn.disabled = false;
    }
    return;
  }

  const removeGroupBtn = e.target.closest("[data-remove-group]");
  if (removeGroupBtn) {
    const groupId = removeGroupBtn.getAttribute("data-remove-group");
    const schoolId = removeGroupBtn.getAttribute("data-remove-group-school");

    const sure = window.confirm("Remove this group? This only works if no students are currently in it.");
    if (!sure) return;

    removeGroupBtn.disabled = true;
    const { error } = await supabase.from("school_groups").delete().eq("id", groupId);

    if (error) {
      setStatus(
        error.code === "23503" ? "This group still has students in it. Move them to a different group first." : "Couldn't remove that group. Try again.",
        "error"
      );
      removeGroupBtn.disabled = false;
      return;
    }

    await refreshGroupsForSchool(schoolId);
    setStatus("Group removed.", "success");
  }
});

el("schoolList").addEventListener("submit", async (e) => {
  const form = e.target.closest("[data-add-group-school]");
  if (!form) return;
  e.preventDefault();

  const schoolId = form.getAttribute("data-add-group-school");
  const input = form.querySelector(".group-add-input");
  const name = input.value.trim();
  if (!name) return;

  const submitBtn = form.querySelector("button[type=submit]");
  submitBtn.disabled = true;
  const { error } = await supabase.from("school_groups").insert({ school_id: schoolId, name });
  submitBtn.disabled = false;

  if (error) {
    setStatus(error.code === "23505" ? "That group already exists." : "Couldn't add that group. Try again.", "error");
    return;
  }

  input.value = "";
  await refreshGroupsForSchool(schoolId);
  setStatus("Group added.", "success");
});

el("schoolForm").addEventListener("submit", async (e) => {
  e.preventDefault();
  setFormMessage("schoolMessage", "");

  const name = el("schName").value.trim();
  const location = el("schLocation").value.trim();
  const prefix = el("schPrefix").value.trim();
  const groups = el("schGroups").value
    .split(",")
    .map((g) => g.trim())
    .filter(Boolean);

  if (!name || !prefix) {
    setFormMessage("schoolMessage", "Name and prefix are required.", "error");
    return;
  }

  el("schoolSubmit").disabled = true;
  try {
    await callApi("create-school", { name, location, prefix, groups });
    el("schoolForm").reset();
    setFormMessage("schoolMessage", "School created.", "success");
    await loadSchools();
    await loadSchoolCounts();
    renderSchoolList();
    populateSchoolSelects();
    await onStudentsSchoolChange();
  } catch (err) {
    setFormMessage("schoolMessage", err.message, "error");
  } finally {
    el("schoolSubmit").disabled = false;
  }
});

// --- Students ---------------------------------------------------------

async function onStudentsSchoolChange() {
  const schoolId = el("stuSchoolFilter").value || state.schools[0]?.id;
  if (!schoolId) return;
  el("stuSchoolFilter").value = schoolId;
  el("stuSchool").value = schoolId;
  state.editingStudentId = null;

  const groups = await loadGroupsForSchool(schoolId);
  const groupOptions = groups.map((g) => `<option value="${g.id}">${escapeHtml(g.name)}</option>`).join("");
  el("stuGroupFilter").innerHTML = '<option value="">All groups</option>' + groupOptions;
  el("stuGroup").innerHTML = '<option value="">No group</option>' + groupOptions;

  await loadStudents(schoolId);
  renderStudentList();
}

async function loadStudents(schoolId) {
  const { data, error } = await supabase
    .from("students")
    .select("id, full_name, student_code, group_id, current_module_id, must_change_password, active")
    .eq("school_id", schoolId)
    .order("full_name");

  if (error) {
    setStatus("Couldn't load students. Refresh to try again.", "error");
    state.students = [];
    return;
  }
  state.students = data || [];
}

function moduleLabel(id) {
  const m = state.modules.find((m) => m.id === id);
  return m ? `Module ${m.number}` : "—";
}

function groupLabel(schoolId, groupId) {
  const groups = state.groupsBySchool.get(schoolId) || [];
  return groups.find((g) => g.id === groupId)?.name || "—";
}

function filteredStudents() {
  const group = el("stuGroupFilter").value;
  const q = el("stuSearch").value.trim().toLowerCase();
  return state.students.filter((s) => {
    if (group && s.group_id !== group) return false;
    if (q && !`${s.full_name} ${s.student_code}`.toLowerCase().includes(q)) return false;
    return true;
  });
}

function renderStudentList() {
  const schoolId = el("stuSchoolFilter").value;
  const list = filteredStudents();

  el("studentList").innerHTML = list.length
    ? list.map((s) => renderStudentRow(s, schoolId)).join("")
    : `<p class="empty-state">No students match those filters.</p>`;
}

function renderStudentRow(s, schoolId) {
  if (state.editingStudentId === s.id) {
    const groups = state.groupsBySchool.get(schoolId) || [];
    const groupOptions =
      '<option value="">No group</option>' +
      groups
        .map((g) => `<option value="${g.id}" ${g.id === s.group_id ? "selected" : ""}>${escapeHtml(g.name)}</option>`)
        .join("");
    const moduleOptions = state.modules
      .map(
        (m) =>
          `<option value="${m.id}" ${m.id === s.current_module_id ? "selected" : ""}>Module ${m.number} · ${escapeHtml(
            m.name
          )}</option>`
      )
      .join("");
    return `<li class="roster-row roster-row--edit">
      <div class="edit-grid">
        <input type="text" id="editStuName_${s.id}" value="${escapeHtml(s.full_name)}" placeholder="Full name">
        <select id="editStuGroup_${s.id}">${groupOptions}</select>
        <select id="editStuModule_${s.id}">${moduleOptions}</select>
      </div>
      <div class="entity-card__actions">
        <button type="button" class="btn btn--primary btn--xs" data-save-student="${s.id}">Save</button>
        <button type="button" class="btn btn--secondary btn--xs" data-cancel-student-edit="1">Cancel</button>
      </div>
    </li>`;
  }

  return `<li class="roster-row">
    <span class="roster-row__name">${escapeHtml(s.full_name)}
      <span class="roster-row__sub">${escapeHtml(s.student_code)} · ${escapeHtml(
    groupLabel(schoolId, s.group_id)
  )} · ${escapeHtml(moduleLabel(s.current_module_id))}${
    s.must_change_password ? ' · <span class="due-flag">first sign-in pending</span>' : ""
  }${s.active ? "" : ' · <span class="due-flag">inactive</span>'}</span>
    </span>
    <span class="roster-row__buttons">
      <button type="button" class="btn btn--secondary btn--xs" data-edit-student="${s.id}">Edit</button>
      <button type="button" class="btn btn--secondary btn--xs" data-reset-student="${s.id}">Reset password</button>
      <button type="button" class="btn btn--secondary btn--xs" data-toggle-student="${s.id}">${
    s.active ? "Deactivate" : "Reactivate"
  }</button>
      <button type="button" class="btn btn--secondary btn--xs" data-delete-student="${s.id}">Delete</button>
    </span>
  </li>`;
}

["stuGroupFilter", "stuSearch"].forEach((id) => {
  el(id).addEventListener("input", renderStudentList);
  el(id).addEventListener("change", renderStudentList);
});

el("stuSchoolFilter").addEventListener("change", onStudentsSchoolChange);
el("stuSchool").addEventListener("change", async (e) => {
  el("stuSchoolFilter").value = e.target.value;
  await onStudentsSchoolChange();
});

el("studentList").addEventListener("click", async (e) => {
  const resetBtn = e.target.closest("[data-reset-student]");
  if (resetBtn) {
    const studentId = resetBtn.getAttribute("data-reset-student");
    const student = state.students.find((s) => s.id === studentId);
    if (!student) return;

    resetBtn.disabled = true;
    try {
      const result = await callApi("reset-student-password", { studentId });
      el("studentResult").innerHTML = passwordBanner({
        title: `New password for ${student.full_name}`,
        lines: [
          { label: "Student ID", value: student.student_code },
          { label: "Password", value: result.password },
        ],
      });
      el("studentResult").scrollIntoView({ behavior: "smooth", block: "center" });
      await loadStudents(el("stuSchoolFilter").value);
      renderStudentList();
    } catch (err) {
      setStatus(err.message, "error");
    } finally {
      resetBtn.disabled = false;
    }
    return;
  }

  const editBtn = e.target.closest("[data-edit-student]");
  if (editBtn) {
    state.editingStudentId = editBtn.getAttribute("data-edit-student");
    renderStudentList();
    return;
  }

  const cancelBtn = e.target.closest("[data-cancel-student-edit]");
  if (cancelBtn) {
    state.editingStudentId = null;
    renderStudentList();
    return;
  }

  const saveBtn = e.target.closest("[data-save-student]");
  if (saveBtn) {
    const studentId = saveBtn.getAttribute("data-save-student");
    const fullName = el(`editStuName_${studentId}`).value.trim();
    const groupId = el(`editStuGroup_${studentId}`).value || null;
    const moduleId = el(`editStuModule_${studentId}`).value;

    if (!fullName) {
      setStatus("Full name is required.", "error");
      return;
    }

    saveBtn.disabled = true;
    const { error } = await supabase
      .from("students")
      .update({ full_name: fullName, group_id: groupId, current_module_id: moduleId })
      .eq("id", studentId);
    saveBtn.disabled = false;

    if (error) {
      setStatus("Couldn't save that student. Try again.", "error");
      return;
    }

    state.editingStudentId = null;
    await loadStudents(el("stuSchoolFilter").value);
    renderStudentList();
    setStatus("Student updated.", "success");
    return;
  }

  const toggleBtn = e.target.closest("[data-toggle-student]");
  if (toggleBtn) {
    const studentId = toggleBtn.getAttribute("data-toggle-student");
    const student = state.students.find((s) => s.id === studentId);
    if (!student) return;

    const next = !student.active;
    if (!next) {
      const sure = window.confirm(
        `Deactivate ${student.full_name}? They won't be able to sign in, but every record they have stays in the database. You can reactivate them any time.`
      );
      if (!sure) return;
    }

    toggleBtn.disabled = true;
    const { error } = await supabase.from("students").update({ active: next }).eq("id", studentId);
    toggleBtn.disabled = false;

    if (error) {
      setStatus("Couldn't update that student. Try again.", "error");
      return;
    }

    await loadStudents(el("stuSchoolFilter").value);
    renderStudentList();
    return;
  }

  const deleteBtn = e.target.closest("[data-delete-student]");
  if (deleteBtn) {
    const studentId = deleteBtn.getAttribute("data-delete-student");
    const student = state.students.find((s) => s.id === studentId);
    if (!student) return;

    const sure = window.confirm(
      `Permanently delete ${student.full_name} (${student.student_code})?\n\n` +
        "This erases ALL of their history — every ticked item, checkpoint, feedback note, and attendance record — forever. This cannot be undone.\n\n" +
        "If you just want to remove them without losing their history, use Deactivate instead."
    );
    if (!sure) return;

    deleteBtn.disabled = true;
    try {
      await callApi("delete-student", { studentId });
      await loadStudents(el("stuSchoolFilter").value);
      renderStudentList();
      await loadSchoolCounts();
      setStatus(`${student.full_name} deleted.`, "success");
    } catch (err) {
      setStatus(err.message, "error");
      deleteBtn.disabled = false;
    }
  }
});

el("studentForm").addEventListener("submit", async (e) => {
  e.preventDefault();
  setFormMessage("studentMessage", "");
  el("studentResult").innerHTML = "";

  const payload = {
    schoolId: el("stuSchool").value,
    fullName: el("stuName").value.trim(),
    groupId: el("stuGroup").value || null,
    moduleId: el("stuModule").value,
    password: el("stuPassword").value.trim() || undefined,
  };

  if (!payload.fullName) {
    setFormMessage("studentMessage", "Full name is required.", "error");
    return;
  }

  el("studentSubmit").disabled = true;
  try {
    const result = await callApi("create-student", payload);
    el("studentForm").reset();
    el("stuSchool").value = payload.schoolId;
    el("studentResult").innerHTML = passwordBanner({
      title: `${result.fullName} created`,
      lines: [
        { label: "Student ID", value: result.studentCode },
        { label: "Password", value: result.password },
      ],
    });
    if (payload.schoolId === el("stuSchoolFilter").value) {
      await loadStudents(payload.schoolId);
      renderStudentList();
    }
    await loadSchoolCounts();
  } catch (err) {
    setFormMessage("studentMessage", err.message, "error");
  } finally {
    el("studentSubmit").disabled = false;
  }
});

el("bulkForm").addEventListener("submit", async (e) => {
  e.preventDefault();
  setFormMessage("bulkMessage", "");
  el("bulkResult").innerHTML = "";

  const names = el("bulkNames").value
    .split("\n")
    .map((n) => n.trim())
    .filter(Boolean);

  if (!names.length) {
    setFormMessage("bulkMessage", "Enter at least one name.", "error");
    return;
  }

  const rows = names.map((fullName) => ({
    fullName,
    groupId: el("stuGroup").value || null,
    moduleId: el("stuModule").value,
  }));

  el("bulkSubmit").disabled = true;
  try {
    const { results } = await callApi("bulk-students", { schoolId: el("stuSchool").value, rows });
    el("bulkForm").reset();

    const okRows = results.filter((r) => r.ok);
    const failRows = results.filter((r) => !r.ok);

    el("bulkResult").innerHTML = `
      <div class="pw-banner">
        <div class="pw-banner__title">${okRows.length} of ${results.length} created</div>
        ${okRows
          .map(
            (r) =>
              `<div class="pw-banner__line"><span>${escapeHtml(r.fullName)} (${escapeHtml(
                r.studentCode
              )})</span><code>${escapeHtml(r.password)}</code></div>`
          )
          .join("")}
        ${failRows.length ? `<p class="form-message form-message--error" style="margin-top:10px">Failed: ${failRows
          .map((r) => `${escapeHtml(r.fullName)} — ${escapeHtml(r.error)}`)
          .join("; ")}</p>` : ""}
        <p class="pw-banner__hint">Shown once — write these down now.</p>
      </div>`;

    if (el("stuSchool").value === el("stuSchoolFilter").value) {
      await loadStudents(el("stuSchoolFilter").value);
      renderStudentList();
    }
    await loadSchoolCounts();
  } catch (err) {
    setFormMessage("bulkMessage", err.message, "error");
  } finally {
    el("bulkSubmit").disabled = false;
  }
});

// --- Coaches ------------------------------------------------------------

async function loadCoaches() {
  const { data, error } = await supabase
    .from("coaches")
    .select("id, name, role, school_id, active")
    .order("name");

  if (error) {
    setStatus("Couldn't load coach accounts. Refresh to try again.", "error");
    state.coaches = [];
    return;
  }
  state.coaches = data || [];
  renderCoachList();
}

function schoolLabel(schoolId) {
  return state.schools.find((s) => s.id === schoolId)?.name || "—";
}

function renderCoachList() {
  el("coachList").innerHTML = state.coaches.length
    ? state.coaches
        .map((c) => {
          const isSelf = c.id === state.selfId;
          const selfTitle = isSelf ? ' title="You can\'t do this to your own account"' : "";
          return `<li class="roster-row">
            <span class="roster-row__name">${escapeHtml(c.name)}
              <span class="roster-row__sub">${
                c.role === "admin" ? "Admin · all schools" : escapeHtml(schoolLabel(c.school_id))
              }${c.active ? "" : " · inactive"}</span>
            </span>
            <span class="roster-row__buttons">
              <button type="button" class="btn btn--secondary btn--xs" data-reset-coach="${c.id}">Set new password</button>
              <button type="button" class="btn btn--secondary btn--xs" data-toggle-coach="${c.id}" ${
            isSelf ? "disabled" : ""
          }${selfTitle}>${c.active ? "Deactivate" : "Reactivate"}</button>
              <button type="button" class="btn btn--secondary btn--xs" data-delete-coach="${c.id}" ${
            isSelf ? "disabled" : ""
          }${selfTitle}>Delete</button>
            </span>
          </li>`;
        })
        .join("")
    : `<p class="empty-state">No coach accounts yet.</p>`;
}

el("coachList").addEventListener("click", async (e) => {
  const resetBtn = e.target.closest("[data-reset-coach]");
  if (resetBtn) {
    const coachId = resetBtn.getAttribute("data-reset-coach");
    const coach = state.coaches.find((c) => c.id === coachId);
    if (!coach) return;

    resetBtn.disabled = true;
    try {
      const result = await callApi("set-coach-password", { coachId });
      el("coachResult").innerHTML = passwordBanner({
        title: `New password for ${coach.name}`,
        lines: [{ label: "Password", value: result.password }],
      });
      el("coachResult").scrollIntoView({ behavior: "smooth", block: "center" });
    } catch (err) {
      setStatus(err.message, "error");
    } finally {
      resetBtn.disabled = false;
    }
    return;
  }

  const toggleBtn = e.target.closest("[data-toggle-coach]");
  if (toggleBtn && !toggleBtn.disabled) {
    const coachId = toggleBtn.getAttribute("data-toggle-coach");
    const coach = state.coaches.find((c) => c.id === coachId);
    if (!coach) return;

    const next = !coach.active;
    if (!next) {
      const sure = window.confirm(
        `Deactivate ${coach.name}? They won't be able to sign in. You can reactivate them any time.`
      );
      if (!sure) return;
    }

    toggleBtn.disabled = true;
    const { error } = await supabase.from("coaches").update({ active: next }).eq("id", coachId);
    toggleBtn.disabled = false;

    if (error) {
      setStatus("Couldn't update that coach. Try again.", "error");
      return;
    }

    await loadCoaches();
    return;
  }

  const deleteBtn = e.target.closest("[data-delete-coach]");
  if (deleteBtn && !deleteBtn.disabled) {
    const coachId = deleteBtn.getAttribute("data-delete-coach");
    const coach = state.coaches.find((c) => c.id === coachId);
    if (!coach) return;

    const sure = window.confirm(
      `Permanently delete ${coach.name}'s coach account?\n\n` +
        "This cannot be undone. Deleting is only allowed for coaches with no recorded activity — " +
        "if they've ever marked attendance, ticks, checkpoints, feedback, or notes, deactivate them instead."
    );
    if (!sure) return;

    deleteBtn.disabled = true;
    try {
      await callApi("delete-coach", { coachId });
      await loadCoaches();
      setStatus(`${coach.name} deleted.`, "success");
    } catch (err) {
      setStatus(err.message, "error");
      deleteBtn.disabled = false;
    }
  }
});

el("coachRole").addEventListener("change", () => {
  const isAdmin = el("coachRole").value === "admin";
  el("coachSchoolField").hidden = isAdmin;
  el("coachSchool").required = !isAdmin;
});

el("coachForm").addEventListener("submit", async (e) => {
  e.preventDefault();
  setFormMessage("coachFormMessage", "");
  el("coachResult").innerHTML = "";

  const role = el("coachRole").value;
  const payload = {
    email: el("coachEmailInput").value.trim(),
    name: el("coachNameInput").value.trim(),
    role,
    schoolId: role === "admin" ? null : el("coachSchool").value,
    password: el("coachPasswordInput").value.trim() || undefined,
  };

  if (!payload.email || !payload.name) {
    setFormMessage("coachFormMessage", "Email and name are required.", "error");
    return;
  }

  el("coachSubmit").disabled = true;
  try {
    const result = await callApi("create-coach", payload);
    el("coachForm").reset();
    el("coachSchoolField").hidden = false;
    el("coachResult").innerHTML = passwordBanner({
      title: `${result.name} created`,
      lines: [
        { label: "Email", value: result.email },
        { label: "Password", value: result.password },
      ],
    });
    await loadCoaches();
  } catch (err) {
    setFormMessage("coachFormMessage", err.message, "error");
  } finally {
    el("coachSubmit").disabled = false;
  }
});

init();
