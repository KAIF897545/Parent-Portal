import { supabase } from "./supabase.js";

const params = new URLSearchParams(window.location.search);
const schoolId = params.get("school");

const schoolBanner = document.getElementById("schoolBanner");

const tabs = {
  student: document.getElementById("tab-student"),
  coach: document.getElementById("tab-coach"),
};
const panels = {
  student: document.getElementById("panel-student"),
  coach: document.getElementById("panel-coach"),
};

function selectTab(name) {
  for (const key of Object.keys(tabs)) {
    const active = key === name;
    tabs[key].setAttribute("aria-selected", String(active));
    tabs[key].tabIndex = active ? 0 : -1;
    panels[key].hidden = !active;
  }
  tabs[name].focus();
}

tabs.student.addEventListener("click", () => selectTab("student"));
tabs.coach.addEventListener("click", () => selectTab("coach"));

for (const [name, tab] of Object.entries(tabs)) {
  tab.addEventListener("keydown", (event) => {
    if (event.key === "ArrowRight" || event.key === "ArrowLeft") {
      event.preventDefault();
      selectTab(name === "student" ? "coach" : "student");
    }
  });
}

async function loadSchoolName() {
  if (!schoolId) {
    schoolBanner.textContent = "";
    return;
  }
  const { data, error } = await supabase
    .from("schools")
    .select("name")
    .eq("id", schoolId)
    .single();

  if (error || !data) {
    schoolBanner.textContent = "School not found.";
    return;
  }
  schoolBanner.textContent = `Signing in to ${data.name}`;
}

loadSchoolName();

// --- Student sign-in ---

const studentForm = document.getElementById("studentForm");
const studentNameInput = document.getElementById("studentName");
const studentPasswordInput = document.getElementById("studentPassword");
const studentCodeField = document.getElementById("studentCodeField");
const studentCodeInput = document.getElementById("studentCode");
const studentMessage = document.getElementById("studentMessage");
const studentSubmit = document.getElementById("studentSubmit");

function hideStudentCodeField() {
  studentCodeField.hidden = true;
  studentCodeInput.value = "";
}

studentNameInput.addEventListener("input", hideStudentCodeField);
studentPasswordInput.addEventListener("input", hideStudentCodeField);

function setStudentMessage(text, kind) {
  studentMessage.textContent = text;
  studentMessage.className = kind
    ? `form-message form-message--${kind}`
    : "form-message";
}

studentForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  setStudentMessage("", null);

  if (!schoolId) {
    setStudentMessage("Choose a school portal first.", "error");
    return;
  }

  const name = studentNameInput.value.trim();
  const password = studentPasswordInput.value;

  if (!name || !password) {
    setStudentMessage("Enter your name and password.", "error");
    return;
  }

  studentSubmit.disabled = true;
  setStudentMessage("Signing in…", null);

  try {
    const response = await fetch("/api/resolve-login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        school: schoolId,
        name,
        password,
        student_code: studentCodeField.hidden ? null : studentCodeInput.value.trim(),
      }),
    });

    const body = await response.json().catch(() => ({}));

    if (response.status === 409 && body.ambiguous) {
      studentCodeField.hidden = false;
      studentCodeInput.focus();
      setStudentMessage("Enter your student ID to continue.", null);
      return;
    }

    if (response.status === 429) {
      setStudentMessage(body.error || "Too many attempts. Wait a few minutes and try again.", "error");
      return;
    }

    if (!response.ok || !body.email) {
      setStudentMessage(body.error || "Name or password not recognised. Ask your coach for help.", "error");
      return;
    }

    const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
      email: body.email,
      password,
    });

    if (signInError || !signInData?.user) {
      setStudentMessage("Name or password not recognised. Ask your coach for help.", "error");
      return;
    }

    const { data: studentRow, error: studentError } = await supabase
      .from("students")
      .select("must_change_password")
      .eq("id", signInData.user.id)
      .single();

    if (studentError || !studentRow) {
      setStudentMessage("Something went wrong. Try again.", "error");
      return;
    }

    window.location.href = studentRow.must_change_password ? "first-login.html" : "portal.html";
  } catch {
    setStudentMessage("Something went wrong. Try again.", "error");
  } finally {
    studentSubmit.disabled = false;
  }
});

// --- Coach sign-in ---

const coachForm = document.getElementById("coachForm");
const coachEmailInput = document.getElementById("coachEmail");
const coachPasswordInput = document.getElementById("coachPassword");
const coachMessage = document.getElementById("coachMessage");
const coachSubmit = document.getElementById("coachSubmit");

function setCoachMessage(text, kind) {
  coachMessage.textContent = text;
  coachMessage.className = kind
    ? `form-message form-message--${kind}`
    : "form-message";
}

coachForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  setCoachMessage("", null);

  const email = coachEmailInput.value.trim();
  const password = coachPasswordInput.value;

  if (!email || !password) {
    setCoachMessage("Enter your email and password.", "error");
    return;
  }

  coachSubmit.disabled = true;
  setCoachMessage("Signing in…", null);

  try {
    const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (signInError || !signInData?.user) {
      setCoachMessage("Email or password not recognised. Check both and try again.", "error");
      return;
    }

    const { data: coachRow, error: coachError } = await supabase
      .from("coaches")
      .select("role, active")
      .eq("id", signInData.user.id)
      .single();

    if (coachError || !coachRow || !coachRow.active) {
      setCoachMessage("This account is not active. Contact the administrator.", "error");
      await supabase.auth.signOut();
      return;
    }

    window.location.href = coachRow.role === "admin" ? "admin.html" : "coach.html";
  } catch {
    setCoachMessage("Something went wrong. Try again.", "error");
  } finally {
    coachSubmit.disabled = false;
  }
});
