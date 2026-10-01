// contact.html only: plain copy-to-clipboard buttons, plus the
// "copy email template" buttons that fill in a full mailto-style body.
const toast = document.getElementById("toast");
let toastTimer;
function showToast(msg) {
  if (!toast) return;
  toast.textContent = msg;
  toast.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove("show"), 2200);
}

document.querySelectorAll(".copy").forEach((b) => {
  b.addEventListener("click", async () => {
    const label = b.textContent;
    try {
      await navigator.clipboard.writeText(b.dataset.copy);
      b.textContent = "Copied";
      setTimeout(() => (b.textContent = label), 1600);
    } catch {
      /* clipboard denied -- the value is already visible as a link, nothing more to do */
    }
  });
});

const TEMPLATES = {
  school: `To: info@maldiveschessclub.com
Subject: Portal for my school

School name:
Island:
Age groups we teach:
Approx. number of students:
Contact name and phone:
`,
  coach: `To: info@maldiveschessclub.com
Subject: Independent coach account

Name:
Island:
Where I coach:
Approx. number of students:
Phone:
`,
};

document.querySelectorAll("[data-copy-template]").forEach((b) => {
  b.addEventListener("click", async () => {
    const text = TEMPLATES[b.dataset.copyTemplate];
    if (!text) return;
    try {
      await navigator.clipboard.writeText(text);
      showToast("Template copied -- paste it into an email");
    } catch {
      showToast("Couldn't copy automatically -- please copy by hand");
    }
  });
});
