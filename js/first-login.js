import { supabase } from "./supabase.js";
import { enablePasswordToggles } from "./utils.js";

enablePasswordToggles();

const loadingMessage = document.getElementById("loadingMessage");
const screenConfirm = document.getElementById("screenConfirm");
const screenPassword = document.getElementById("screenPassword");

let identity = null;

async function init() {
  const { data: sessionData } = await supabase.auth.getSession();
  if (!sessionData?.session) {
    window.location.href = "login.html";
    return;
  }

  const { data, error } = await supabase.rpc("my_identity");
  const row = Array.isArray(data) ? data[0] : data;

  if (error || !row || !row.student_code) {
    // Not a student account (e.g. a coach landed here) — nowhere useful to go but sign in again.
    window.location.href = "login.html";
    return;
  }

  identity = row;

  document.getElementById("identityName").textContent = row.full_name;
  document.getElementById("identityCode").textContent = row.student_code;
  document.getElementById("identityGroup").textContent = row.group_name || "—";
  document.getElementById("identitySchool").textContent = row.school_name;

  loadingMessage.hidden = true;
  screenConfirm.hidden = false;
}

init();

document.getElementById("confirmContinue").addEventListener("click", () => {
  screenConfirm.hidden = true;
  screenPassword.hidden = false;
  document.getElementById("newPassword").focus();
});

document.getElementById("notMeButton").addEventListener("click", async () => {
  await supabase.auth.signOut();
  window.location.href = "login.html";
});

// --- Screen 2: password rules ---

const newPasswordInput = document.getElementById("newPassword");
const confirmPasswordInput = document.getElementById("confirmPassword");
const passwordForm = document.getElementById("passwordForm");
const passwordSubmit = document.getElementById("passwordSubmit");
const passwordMessage = document.getElementById("passwordMessage");

const rules = {
  length: document.getElementById("ruleLength"),
  name: document.getElementById("ruleName"),
  code: document.getElementById("ruleCode"),
  match: document.getElementById("ruleMatch"),
};

function evaluateRules() {
  const pw = newPasswordInput.value;
  const confirm = confirmPasswordInput.value;
  const name = (identity?.full_name || "").trim().toLowerCase();
  const code = (identity?.student_code || "").trim().toLowerCase();
  const pwLower = pw.trim().toLowerCase();

  const met = {
    length: pw.length >= 8,
    name: pwLower.length > 0 && pwLower !== name,
    code: pwLower.length > 0 && pwLower !== code,
    match: pw.length > 0 && pw === confirm,
  };

  for (const key of Object.keys(rules)) {
    rules[key].dataset.met = String(met[key]);
  }

  const allMet = Object.values(met).every(Boolean);
  passwordSubmit.disabled = !allMet;
  return allMet;
}

newPasswordInput.addEventListener("input", evaluateRules);
confirmPasswordInput.addEventListener("input", evaluateRules);

function setPasswordMessage(text) {
  passwordMessage.textContent = text;
}

const errorMessages = {
  PW001: "Password must be at least 8 characters.",
  PW002: "Password cannot be your name.",
  PW003: "Password cannot be your student ID.",
  PW004: "Password rejected.",
  PW005: "Only students change their password here.",
};

passwordForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  setPasswordMessage("");

  if (!evaluateRules()) {
    setPasswordMessage("Check the requirements above.");
    return;
  }

  passwordSubmit.disabled = true;
  setPasswordMessage("Saving…");

  const { error } = await supabase.rpc("set_my_password", {
    password: newPasswordInput.value,
  });

  if (error) {
    setPasswordMessage(errorMessages[error.code] || "Something went wrong. Try again.");
    passwordSubmit.disabled = false;
    return;
  }

  window.location.href = "portal.html";
});
