import { supabase } from "./supabase.js";
import { escapeHtml, formatDate } from "./utils.js";

const el = (id) => document.getElementById(id);

const state = {
  accessToken: null,
  schools: [],
  modules: [],
  groupsBySchool: new Map(), // school_id -> [{id,name}]
  students: [],
  coaches: [],
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

el("tabSchools").addEventListener("click", () => selectTab("schools"));
el("tabStudents").addEventListener("click", () => selectTab("students"));
el("tabCoaches").addEventListener("click", () => selectTab("coaches"));

// --- Schools --------------------------------------------------------------

function renderSchoolList() {
  el("schoolList").innerHTML = state.schools.length
    ? state.schools
        .map(
          (s) => `<div class="entity-card">
            <h3>${escapeHtml(s.name)}</h3>
            <p>${escapeHtml(s.location || "—")} · ID prefix <strong>${escapeHtml(s.prefix)}</strong></p>
            <p class="entity-card__groups" data-groups-for="${s.id}">Loading groups…</p>
          </div>`
        )
        .join("")
    : `<p class="empty-state">No schools yet — add the first one below.</p>`;

  state.schools.forEach(async (s) => {
    const groups = await loadGroupsForSchool(s.id);
    const target = document.querySelector(`[data-groups-for="${s.id}"]`);
    if (target) {
      target.textContent = groups.length ? `Groups: ${groups.map((g) => g.name).join(", ")}` : "No groups yet";
    }
  });
}

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
    .select("id, full_name, student_code, category, group_id, current_module_id, must_change_password, active")
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
    ? list
        .map(
          (s) => `<li class="roster-row">
            <span class="roster-row__name">${escapeHtml(s.full_name)}
              <span class="roster-row__sub">${escapeHtml(s.student_code)} · ${escapeHtml(
            groupLabel(schoolId, s.group_id)
          )} · ${escapeHtml(moduleLabel(s.current_module_id))} · ${escapeHtml(s.category || "—")}${
            s.must_change_password ? " · <span class=\"due-flag\">first sign-in pending</span>" : ""
          }${s.active ? "" : " · inactive"}</span>
            </span>
            <button type="button" class="btn btn--secondary btn--xs" data-reset-student="${s.id}">Reset password</button>
          </li>`
        )
        .join("")
    : `<p class="empty-state">No students match those filters.</p>`;
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
  const btn = e.target.closest("[data-reset-student]");
  if (!btn) return;
  const studentId = btn.getAttribute("data-reset-student");
  const student = state.students.find((s) => s.id === studentId);
  if (!student) return;

  btn.disabled = true;
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
    btn.disabled = false;
  }
});

el("studentForm").addEventListener("submit", async (e) => {
  e.preventDefault();
  setFormMessage("studentMessage", "");
  el("studentResult").innerHTML = "";

  const payload = {
    schoolId: el("stuSchool").value,
    fullName: el("stuName").value.trim(),
    category: el("stuCategory").value,
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
    category: el("stuCategory").value,
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
        .map(
          (c) => `<li class="roster-row">
            <span class="roster-row__name">${escapeHtml(c.name)}
              <span class="roster-row__sub">${
                c.role === "admin" ? "Admin · all schools" : escapeHtml(schoolLabel(c.school_id))
              }${c.active ? "" : " · inactive"}</span>
            </span>
            <button type="button" class="btn btn--secondary btn--xs" data-reset-coach="${c.id}">Set new password</button>
          </li>`
        )
        .join("")
    : `<p class="empty-state">No coach accounts yet.</p>`;
}

el("coachList").addEventListener("click", async (e) => {
  const btn = e.target.closest("[data-reset-coach]");
  if (!btn) return;
  const coachId = btn.getAttribute("data-reset-coach");
  const coach = state.coaches.find((c) => c.id === coachId);
  if (!coach) return;

  btn.disabled = true;
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
    btn.disabled = false;
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
