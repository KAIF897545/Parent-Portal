import { supabase } from "./supabase.js";
import { enablePasswordToggles } from "./utils.js";

enablePasswordToggles();

const params = new URLSearchParams(window.location.search);
const schoolId = params.get("school");
const initialRole = params.get("role");

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

if (initialRole === "coach") {
  tabs.student.setAttribute("aria-selected", "false");
  tabs.student.tabIndex = -1;
  panels.student.hidden = true;
  tabs.coach.setAttribute("aria-selected", "true");
  tabs.coach.tabIndex = 0;
  panels.coach.hidden = false;
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
const studentEmailInput = document.getElementById("studentEmail");
const studentPasswordInput = document.getElementById("studentPassword");
const studentMessage = document.getElementById("studentMessage");
const studentSubmit = document.getElementById("studentSubmit");

function setStudentMessage(text, kind) {
  studentMessage.textContent = text;
  studentMessage.className = kind
    ? `form-message form-message--${kind}`
    : "form-message";
}

studentForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  setStudentMessage("", null);

  const email = studentEmailInput.value.trim();
  const password = studentPasswordInput.value;

  if (!email || !password) {
    setStudentMessage("Enter your email and password.", "error");
    return;
  }

  studentSubmit.disabled = true;
  setStudentMessage("Signing in…", null);

  try {
    const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (signInError || !signInData?.user) {
      setStudentMessage("Email or password not recognised. Ask your coach for help.", "error");
      return;
    }

    const { data: studentRow, error: studentError } = await supabase
      .from("students")
      .select("must_change_password, active")
      .eq("id", signInData.user.id)
      .single();

    if (studentError || !studentRow || !studentRow.active) {
      setStudentMessage("This account is not active. Ask your coach for help.", "error");
      await supabase.auth.signOut();
      return;
    }

    window.location.href = studentRow.must_change_password ? "first-login.html" : "portal.html";
  } catch {
    setStudentMessage("Something went wrong. Try again.", "error");
  } finally {
    studentSubmit.disabled = false;
  }
});

// --- Student "Forgot password?" ---

const studentForgotToggle = document.getElementById("studentForgotToggle");
const studentForgotPanel = document.getElementById("studentForgotPanel");
const studentForgotSubmit = document.getElementById("studentForgotSubmit");
const studentForgotMessage = document.getElementById("studentForgotMessage");

studentForgotToggle.addEventListener("click", () => {
  studentForgotPanel.hidden = !studentForgotPanel.hidden;
  if (!studentForgotPanel.hidden) studentEmailInput.focus();
});

studentForgotSubmit.addEventListener("click", async () => {
  const email = studentEmailInput.value.trim();
  studentForgotMessage.textContent = "";
  studentForgotMessage.className = "form-message";

  if (!email) {
    studentForgotMessage.textContent = "Enter your email above first.";
    studentForgotMessage.className = "form-message form-message--error";
    studentEmailInput.focus();
    return;
  }

  studentForgotSubmit.disabled = true;
  studentForgotMessage.textContent = "Sending…";

  await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${window.location.origin}/reset-password.html`,
  });

  // Same message whether or not that email is on file -- confirming
  // either way would let someone probe which emails are registered.
  studentForgotMessage.textContent = "If that email is on file, a reset link is on its way.";
  studentForgotMessage.className = "form-message form-message--success";
  studentForgotSubmit.disabled = false;
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
