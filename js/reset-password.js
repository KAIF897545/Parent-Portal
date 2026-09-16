import { supabase } from "./supabase.js";
import { enablePasswordToggles } from "./utils.js";

enablePasswordToggles();

const loadingMessage = document.getElementById("loadingMessage");
const screenExpired = document.getElementById("screenExpired");
const screenPassword = document.getElementById("screenPassword");

async function init() {
  // The Supabase client auto-detects the recovery token in the URL and
  // establishes a session before this runs. No session means the link
  // was already used, expired, or was opened by something other than
  // the person it was sent to (e.g. an email scanner pre-fetching it).
  const { data: sessionData } = await supabase.auth.getSession();

  if (!sessionData?.session) {
    loadingMessage.hidden = true;
    screenExpired.hidden = false;
    return;
  }

  loadingMessage.hidden = true;
  screenPassword.hidden = false;
  document.getElementById("newPassword").focus();
}

init();

// --- Password rules ---

const newPasswordInput = document.getElementById("newPassword");
const confirmPasswordInput = document.getElementById("confirmPassword");
const passwordForm = document.getElementById("passwordForm");
const passwordSubmit = document.getElementById("passwordSubmit");
const passwordMessage = document.getElementById("passwordMessage");

const rules = {
  length: document.getElementById("ruleLength"),
  match: document.getElementById("ruleMatch"),
};

function evaluateRules() {
  const pw = newPasswordInput.value;
  const confirm = confirmPasswordInput.value;

  const met = {
    length: pw.length >= 8,
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

passwordForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  setPasswordMessage("");

  if (!evaluateRules()) {
    setPasswordMessage("Check the requirements above.");
    return;
  }

  passwordSubmit.disabled = true;
  setPasswordMessage("Saving…");

  const { error } = await supabase.auth.updateUser({ password: newPasswordInput.value });

  if (error) {
    setPasswordMessage(error.message || "Something went wrong. Try again.");
    passwordSubmit.disabled = false;
    return;
  }

  setPasswordMessage("Password updated. Redirecting…");

  const { data: sessionData } = await supabase.auth.getSession();
  const uid = sessionData?.session?.user?.id;

  const { data: coachRow } = await supabase
    .from("coaches")
    .select("role")
    .eq("id", uid)
    .single();

  window.location.href = coachRow?.role === "admin" ? "admin.html" : coachRow ? "coach.html" : "login.html";
});
