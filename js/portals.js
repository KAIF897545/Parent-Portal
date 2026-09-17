import { supabase } from "./supabase.js";

const grid = document.getElementById("schoolGrid");
const status = document.getElementById("status");

const SCHOOL_LOGOS = {
  "brightway international school": "assets/brightway-logo.jpg",
};

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (c) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  }[c]));
}

async function load() {
  status.textContent = "Loading schools…";

  const schoolsRes = await supabase.from("schools").select("id, name, location").order("name");

  if (schoolsRes.error) {
    status.textContent = "Couldn't load schools. Refresh the page to try again.";
    status.className = "form-message form-message--error";
    return;
  }

  const schools = schoolsRes.data || [];

  if (schools.length === 0) {
    grid.innerHTML = "";
    status.textContent = "No school portals are set up yet.";
    return;
  }

  status.textContent = "";
  grid.innerHTML = schools
    .map((school, i) => {
      const logo = SCHOOL_LOGOS[school.name.trim().toLowerCase()];
      const initials = school.name
        .split(/\s+/)
        .map((w) => w[0])
        .filter(Boolean)
        .slice(0, 2)
        .join("")
        .toUpperCase();
      const avatar = logo
        ? `<span class="school-card__avatar school-card__avatar--logo" aria-hidden="true"><img src="${escapeHtml(logo)}" alt="" /></span>`
        : `<span class="school-card__avatar" aria-hidden="true">${escapeHtml(initials)}</span>`;
      return `
        <a class="school-card" href="login.html?school=${encodeURIComponent(school.id)}" style="animation-delay:${i * 60}ms">
          ${avatar}
          <h2>${escapeHtml(school.name)}</h2>
          ${school.location ? `<p>${escapeHtml(school.location)}</p>` : ""}
          <span class="school-card__enter">Enter portal <span aria-hidden="true">&rarr;</span></span>
        </a>
      `;
    })
    .join("");
}

load();
