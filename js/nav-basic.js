// Shared header behavior for simple pages (about.html, contact.html) that
// don't need the full portal-home.js -- just the scroll shadow and the
// mobile hamburger toggle, same markup/classes as portals.html's header.
const nav = document.getElementById("nav");
const navToggle = document.getElementById("navToggle");
const navLinksEl = document.getElementById("navLinks");

function onScroll() {
  nav.classList.toggle("scrolled", document.documentElement.scrollTop > 8);
}
addEventListener("scroll", onScroll, { passive: true });
onScroll();

function setMenu(open) {
  nav.classList.toggle("menu-open", open);
  navToggle.setAttribute("aria-expanded", String(open));
}
navToggle?.addEventListener("click", () => setMenu(!nav.classList.contains("menu-open")));
navLinksEl?.addEventListener("click", (e) => {
  if (e.target.closest("a")) setMenu(false);
});
