import { supabase } from "./supabase.js";

const $ = (s, el = document) => el.querySelector(s);
const $$ = (s, el = document) => [...el.querySelectorAll(s)];
const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

const toast = (msg) => {
  const t = $("#toast");
  t.textContent = msg;
  t.classList.add("show");
  clearTimeout(t._h);
  t._h = setTimeout(() => t.classList.remove("show"), 2200);
};
const esc = (s) =>
  String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const norm = (t) => t.toLowerCase().normalize("NFD").replace(/[̀-ͯ'’]/g, "");

/* ---------- schools: fetched from the database, not hardcoded ---------- */
const SCHOOL_LOGOS = {
  "brightway international school": "assets/brightway-logo.jpg",
  "private tutoring": "assets/private-tutoring-logo.jpg",
};

let SCHOOLS = [];
let schoolsLoaded = false;

function abbr(name) {
  return name
    .split(/\s+/)
    .map((w) => w[0])
    .filter(Boolean)
    .slice(0, 2)
    .join("")
    .toUpperCase();
}

function schoolBadge(school) {
  const logo = SCHOOL_LOGOS[school.name.trim().toLowerCase()];
  return logo
    ? `<span class="badge" aria-hidden="true"><img src="${esc(logo)}" alt="" /></span>`
    : `<span class="badge" aria-hidden="true">${esc(abbr(school.name))}</span>`;
}

function match(q) {
  return SCHOOLS.filter((s) => !q || norm(`${s.name} ${s.place} ${abbr(s.name)}`).includes(norm(q)));
}

async function loadSchools() {
  const { data, error } = await supabase.from("schools").select("id, name, location").order("name");
  SCHOOLS = (data || []).map((s) => ({ id: s.id, name: s.name, place: s.location || "" }));
  schoolsLoaded = true;
  if (error) toast("Couldn't load schools. Refresh to try again.");
  renderPanel();
}

/* ---------- nav: progress bar, shadow, scroll-spy ---------- */
const nav = $("#nav"),
  bar = $("#progress");
function onScroll() {
  const h = document.documentElement;
  const p = h.scrollTop / Math.max(1, h.scrollHeight - h.clientHeight);
  bar.style.transform = `scaleX(${p})`;
  nav.classList.toggle("scrolled", h.scrollTop > 8);
}
addEventListener("scroll", onScroll, { passive: true });
onScroll();
const spy = new IntersectionObserver(
  (es) => es.forEach((e) => {
    if (e.isIntersecting) $$("[data-spy]").forEach((a) => a.classList.toggle("active", a.dataset.spy === e.target.id));
  }),
  { rootMargin: "-45% 0px -50% 0px" }
);
["inside", "devs", "hello", "signin"].forEach((id) => {
  const el = document.getElementById(id);
  if (el) spy.observe(el);
});

/* ---------- sign-in panel: real school picker, real handoff to login.html ---------- */
const S = { step: "school", q: "", school: null, role: "student" };
const panel = $("#panel");

function renderPanel(focusSel) {
  if (S.step === "school") {
    if (!schoolsLoaded) {
      panel.innerHTML = `
        <div class="view">
          <div class="panel-head"><div><h3 class="panel-title">Sign in</h3><span class="school-place">Loading your schools…</span></div></div>
        </div>`;
      return;
    }
    const list = match(S.q);
    panel.innerHTML = `
      <div class="view">
        <div class="panel-head"><div><h3 class="panel-title">Sign in</h3><span class="school-place">Start by choosing your school</span></div></div>
        <div class="field"><label class="sr-only" for="s-q">Search schools</label>
          <input class="input" id="s-q" type="search" autocomplete="off" placeholder="School or island" value="${esc(S.q)}"></div>
        <div id="s-list">${
          list
            .map(
              (s) => `
          <button type="button" class="school" data-school="${s.id}">
            ${schoolBadge(s)}
            <span><span class="school-name">${esc(s.name)}</span><span class="school-place">${esc(s.place)}</span></span>
            <span class="go" aria-hidden="true"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12h14M13 6l6 6-6 6"/></svg></span>
          </button>`
            )
            .join("") ||
          `<p class="hint" style="margin:6px 0 0">No school matches &ldquo;${esc(
            S.q
          )}&rdquo;. Check the spelling, or <a href="#hello" style="color:var(--red);font-weight:800">ask the club about joining</a>.</p>`
        }</div>
      </div>`;
  } else {
    const s = S.school,
      st = S.role === "student";
    panel.innerHTML = `
      <div class="view">
        <div class="panel-head">
          <div style="display:flex;align-items:center;gap:14px">${schoolBadge(s)}
            <div><h3 class="panel-title" style="font-size:24px">${esc(s.name)}</h3><span class="school-place">${esc(s.place)}</span></div></div>
          <button type="button" class="pill" data-act="back">Change</button>
        </div>
        <div class="seg" role="tablist" aria-label="I am a">
          <button type="button" role="tab" aria-selected="${st}" data-role="student">I&rsquo;m a student</button>
          <button type="button" role="tab" aria-selected="${!st}" data-role="coach">I&rsquo;m a coach</button>
        </div>
        <a class="btn btn-maroon btn-wide" style="text-decoration:none;margin-top:4px"
          href="login.html?school=${encodeURIComponent(s.id)}&role=${st ? "student" : "coach"}">Continue to sign in</a>
        <p class="hint">${
          st
            ? "You'll enter your email and password on the next page."
            : "Coach and admin accounts are set up by the club admin."
        }</p>
      </div>`;
  }
  if (focusSel) {
    const el = $(focusSel, panel);
    if (el) el.focus();
  }
}

function pickSchool(id, scroll) {
  S.school = SCHOOLS.find((s) => s.id === id);
  S.step = "role";
  renderPanel();
  if (scroll) document.getElementById("signin").scrollIntoView({ behavior: reduce ? "auto" : "smooth" });
}

panel.addEventListener("input", (e) => {
  if (e.target.id === "s-q") {
    S.q = e.target.value;
    renderPanel("#s-q");
  }
});
panel.addEventListener("click", (e) => {
  const b = e.target.closest("button");
  if (!b) return;
  if (b.dataset.school) pickSchool(b.dataset.school);
  if (b.dataset.role) {
    S.role = b.dataset.role;
    renderPanel();
  }
  if (b.dataset.act === "back") {
    S.step = "school";
    renderPanel("#s-q");
  }
});

renderPanel();
loadSchools();

$$('a[href="#signin"]').forEach((a) =>
  a.addEventListener("click", () =>
    setTimeout(() => {
      const f = $("#s-q");
      if (f) f.focus({ preventScroll: true });
    }, reduce ? 0 : 450)
  )
);
addEventListener("keydown", (e) => {
  if (e.key === "/" && !/input|textarea/i.test(document.activeElement.tagName)) {
    const q = $("#s-q");
    if (q) {
      e.preventDefault();
      q.focus();
    }
  }
});

/* ---------- sheet curtain: rises over the hero, words fill in as you scroll ---------- */
const hero = $(".hero"),
  sheet = $("#sheet"),
  stmt = $("#statement");
const sig = stmt.querySelector(".sig");
const sigText = sig ? sig.textContent : "";
if (sig) sig.remove();
const stmtBody = stmt.textContent.trim();
stmt.innerHTML =
  stmtBody
    .split(/\s+/)
    .map((w) => `<span class="w">${esc(w)}</span>`)
    .join(" ") +
  (sigText ? ` <span class="sig">${sigText.split(/\s+/).map((w) => `<span class="w">${esc(w)}</span>`).join(" ")}</span>` : "");
const words = $$(".w", stmt);
const navH = () => nav.offsetHeight;
function pinHero() {
  hero.style.top = Math.min(navH(), innerHeight - hero.offsetHeight) + "px";
}
function onSheet() {
  const vh = innerHeight,
    r = sheet.getBoundingClientRect();
  const q = Math.min(1, Math.max(0, (vh - r.top) / vh));
  if (!reduce) {
    hero.style.transform = `scale(${1 - q * 0.06})`;
    hero.style.opacity = String(1 - q * 0.55);
  }
  const p = Math.min(1, Math.max(0, (vh * 0.55 - r.top) / (vh * 0.8)));
  const n = reduce ? words.length : Math.round(p * words.length);
  words.forEach((w, i) => w.classList.toggle("lit", i < n));
}
addEventListener("scroll", onSheet, { passive: true });
addEventListener("resize", () => {
  pinHero();
  onSheet();
});
pinHero();
onSheet();

/* ---------- what's inside tabs (illustrative preview, not a live session) ---------- */
const TABS = {
  student: { head: "Growth, tracked.", body: "Track every module and checkpoint. Tap one to try it." },
  coach: { head: "Attendance and progress, live.", body: "Mark attendance live. Tap a student to change it." },
  notes: { head: "Feedback while it's fresh.", body: "A coach's note every month. Pick a month to read it." },
};
const demoState = {
  cps: [true, true, false],
  roster: [
    ["Aiman R.", true],
    ["Zara H.", true],
    ["Ibrahim N.", false],
    ["Maryam S.", true],
  ],
  month: "September",
  notes: {
    July: "Welcome to the program! Learned how each piece moves and set up the board without help.",
    August: "Good progress on piece movement. Keep practicing at home, especially knight moves.",
    September: "Great focus this month. Board setup and notation are solid. Ready for opening principles next.",
  },
};
let tab = "student",
  lastPct = 82;
const demo = $("#demo");
function renderDemo() {
  const t = TABS[tab];
  $("#ex-body").textContent = t.body;
  if (tab === "student") {
    const done = demoState.cps.filter(Boolean).length;
    const pct = [34, 58, 82, 100][done];
    demo.innerHTML = `
      <div class="demo-top"><strong>Module 2: Piece movement</strong><span class="big" id="d-pct">${pct}%</span></div>
      <div class="bar"><i id="d-bar" style="width:${lastPct}%"></i></div>
      <div class="cps">${demoState.cps
        .map(
          (c, i) =>
            `<button type="button" class="cp" aria-pressed="${c}" data-cp="${i}"><span class="t">${
              c ? "&check;" : "&#9675;"
            }</span>Checkpoint ${i + 1}</button>`
        )
        .join("")}</div>
      <p class="hint">${
        done === 3 ? "Module complete. Module 3 unlocks at the next session." : `${3 - done} checkpoint${3 - done > 1 ? "s" : ""} left in this module.`
      }</p>`;
    const from = lastPct;
    lastPct = pct;
    if (from !== pct) {
      requestAnimationFrame(() => {
        const b = $("#d-bar");
        if (b) b.style.width = pct + "%";
      });
      const el = $("#d-pct");
      if (el && !reduce) {
        const t0 = performance.now();
        const tick = (now) => {
          const k = Math.min(1, (now - t0) / 500);
          el.textContent = Math.round(from + (pct - from) * (1 - Math.pow(1 - k, 3))) + "%";
          if (k < 1) requestAnimationFrame(tick);
        };
        requestAnimationFrame(tick);
      }
    }
  } else if (tab === "coach") {
    const present = demoState.roster.filter((r) => r[1]).length;
    demo.innerHTML = `
      <div class="demo-top"><strong>Today's session, Module 1</strong><span class="big" style="font-size:44px">${present}/${demoState.roster.length}</span></div>
      <div>${demoState.roster
        .map(
          (r, i) => `
        <div class="row"><span style="font-weight:700">${esc(r[0])}</span>
        <button type="button" class="att" aria-pressed="${r[1]}" data-att="${i}" aria-label="${esc(r[0])}: ${
            r[1] ? "present" : "absent"
          }. Tap to change.">${r[1] ? "Present" : "Absent"}</button></div>`
        )
        .join("")}</div>`;
  } else {
    demo.innerHTML = `
      <div class="demo-top"><strong>Zara H.</strong></div>
      <div class="months" role="tablist" aria-label="Month">${Object.keys(demoState.notes)
        .map((m) => `<button type="button" role="tab" aria-selected="${m === demoState.month}" data-month="${m}">${m}</button>`)
        .join("")}</div>
      <div class="note"><b>${demoState.month}</b>${esc(demoState.notes[demoState.month])}</div>`;
  }
}
const tabsBox = $(".tabs");
const ind = document.createElement("span");
ind.className = "tab-ind";
ind.setAttribute("aria-hidden", "true");
tabsBox.prepend(ind);
function moveInd() {
  const b = $(`[data-tab="${tab}"]`, tabsBox);
  if (!b) return;
  ind.style.width = b.offsetWidth + "px";
  ind.style.transform = `translateX(${b.offsetLeft - 6}px)`;
}
addEventListener("resize", moveInd);
function setTab(id) {
  const order = Object.keys(TABS),
    dir = order.indexOf(id) >= order.indexOf(tab) ? 1 : -1;
  const changed = id !== tab;
  tab = id;
  if (changed && !reduce) {
    demo.style.setProperty("--dx", dir * 40 + "px");
    demo.classList.remove("swap");
    void demo.offsetWidth;
    demo.classList.add("swap");
  }
  moveInd();
  $$(".tabs [role=tab]").forEach((b) => {
    const on = b.dataset.tab === id;
    b.setAttribute("aria-selected", on);
    b.tabIndex = on ? 0 : -1;
  });
  renderDemo();
}
$(".tabs").addEventListener("click", (e) => {
  const b = e.target.closest("[data-tab]");
  if (b) setTab(b.dataset.tab);
});
$(".tabs").addEventListener("keydown", (e) => {
  const ids = Object.keys(TABS);
  let i = ids.indexOf(tab);
  if (e.key === "ArrowRight") i = (i + 1) % ids.length;
  else if (e.key === "ArrowLeft") i = (i - 1 + ids.length) % ids.length;
  else return;
  e.preventDefault();
  setTab(ids[i]);
  $(`[data-tab="${ids[i]}"]`).focus();
});
demo.addEventListener("click", (e) => {
  const b = e.target.closest("button");
  if (!b) return;
  if (b.dataset.cp) {
    const i = +b.dataset.cp;
    demoState.cps[i] = !demoState.cps[i];
    renderDemo();
    $(`[data-cp="${i}"]`).focus();
    if (demoState.cps.every(Boolean)) toast("Module 2 complete");
  }
  if (b.dataset.att) {
    const i = +b.dataset.att;
    demoState.roster[i][1] = !demoState.roster[i][1];
    renderDemo();
    $(`[data-att="${i}"]`).focus();
  }
  if (b.dataset.month) {
    demoState.month = b.dataset.month;
    renderDemo();
    $(`[data-month="${b.dataset.month}"]`).focus();
  }
});
renderDemo();
requestAnimationFrame(moveInd);
document.fonts && document.fonts.ready.then(moveInd);

/* ---------- launch story curtain ---------- */
const inside = $("#inside"),
  story = $("#story"),
  sFrame = $("#story-frame"),
  sImg = $("#story-img"),
  sScrim = $("#story-scrim"),
  sCopy = $("#story-copy"),
  sKick = $("#story-kicker");
const lerp = (a, b, t) => a + (b - a) * t;
const clamp01 = (v) => Math.min(1, Math.max(0, v));
function pinInside() {
  inside.style.top = Math.min(navH(), innerHeight - inside.offsetHeight) + "px";
}
function onStory() {
  if (reduce) return;
  const vh = innerHeight,
    r = story.getBoundingClientRect(),
    top = navH();
  const cover = clamp01((vh * 0.6 - r.top) / (vh * 0.5));
  inside.style.transform = `scale(${1 - cover * 0.05})`;
  inside.style.filter = `brightness(${1 - cover * 0.35})`;
  const p = clamp01(((top - r.top) / Math.max(1, r.height - (vh - top))) * 1.35);
  const e = 1 - Math.pow(1 - p, 3);
  const mob = innerWidth <= 760;
  const [t0, s0, b0] = mob ? [18, 6, 12] : [16, 22, 10];
  sFrame.style.clipPath = `inset(${lerp(t0, 0, e)}% ${lerp(s0, 0, e)}% ${lerp(b0, 0, e)}% ${lerp(s0, 0, e)}% round ${lerp(
    mob ? 20 : 28,
    0,
    e
  )}px)`;
  sImg.style.transform = `scale(${lerp(1.18, 1, e)})`;
  sKick.style.opacity = String(1 - clamp01(p / 0.35));
  sKick.style.transform = `translateY(${-clamp01(p / 0.35) * 30}px)`;
  const c = clamp01((p - 0.55) / 0.35);
  sScrim.style.opacity = String(c);
  sCopy.style.opacity = String(c);
  sCopy.style.transform = `translateY(${(1 - c) * 24}px)`;
  sCopy.style.pointerEvents = c > 0.5 ? "auto" : "none";
}
addEventListener("scroll", onStory, { passive: true });
addEventListener("resize", () => {
  pinInside();
  onStory();
});
pinInside();
onStory();
const tabsEl = $(".tabs");
if (tabsEl) tabsEl.addEventListener("click", () => requestAnimationFrame(pinInside));

/* ---------- developer cards: stack on scroll ---------- */
const dcards = $$(".dcard"),
  rail = $$(".rail [data-go]");
document.documentElement.style.setProperty("--navh", nav.offsetHeight + "px");
function onCards() {
  let active = 0;
  dcards.forEach((c, i) => {
    const next = dcards[i + 1];
    const stickTop = parseFloat(getComputedStyle(c).top) || 0;
    if (c.getBoundingClientRect().top <= stickTop + 2) active = i;
    let k = 0;
    if (next) {
      const nTop = next.getBoundingClientRect().top,
        nStick = parseFloat(getComputedStyle(next).top) || 0;
      k = Math.min(1, Math.max(0, 1 - (nTop - nStick) / Math.max(1, c.offsetHeight)));
    }
    if (!reduce) {
      const depth = next ? dcards.length - 1 - i : 0;
      const sc = 1 - k * (0.07 + 0.015 * depth);
      c.style.transform = `translateY(${-k * 10}px) scale(${sc})`;
      c.style.filter = `brightness(${1 - k * 0.32}) saturate(${1 - k * 0.25})`;
    }
  });
  rail.forEach((b, i) => b.setAttribute("aria-current", i === active ? "true" : "false"));
}
addEventListener("scroll", onCards, { passive: true });
addEventListener("resize", () => {
  document.documentElement.style.setProperty("--navh", nav.offsetHeight + "px");
  onCards();
});
onCards();
rail.forEach((b) =>
  b.addEventListener("click", () => {
    const i = +b.dataset.go,
      c = dcards[i];
    const wrapTop = scrollY + c.parentElement.getBoundingClientRect().top;
    let y = wrapTop;
    for (let j = 0; j < i; j++) y += dcards[j].offsetHeight + (parseFloat(getComputedStyle(dcards[j]).marginBottom) || 0);
    scrollTo({ top: y - (parseFloat(getComputedStyle(c).top) || 0) + 2, behavior: reduce ? "auto" : "smooth" });
  })
);

/* ---------- feedback: opens a prefilled email, since there's no inbox behind this form ---------- */
const fb = $("#fb");
fb.addEventListener("click", (e) => {
  const w = e.target.closest("[data-who]");
  if (!w) return;
  $$("[data-who]", fb).forEach((x) => x.setAttribute("aria-pressed", x === w ? "true" : "false"));
});
fb.addEventListener("submit", (e) => {
  e.preventDefault();
  const t = $("#fb-msg"),
    err = $("#fb-err");
  if (t.value.trim().length < 5) {
    t.classList.add("bad");
    err.textContent = "Write a few words so we know what to look at.";
    t.focus();
    return;
  }
  t.classList.remove("bad");
  err.textContent = "";
  const who = $("[data-who][aria-pressed=\"true\"]", fb).dataset.who;
  const subject = encodeURIComponent(`Portal feedback from a ${who}`);
  const body = encodeURIComponent(t.value.trim());
  window.location.href = `mailto:info@maldiveschessclub.com?subject=${subject}&body=${body}`;
  toast("Opening your email app…");
});
$("#fb-msg").addEventListener("input", (e) => {
  e.target.classList.remove("bad");
  $("#fb-err").textContent = "";
});

/* ---------- reveal on scroll ---------- */
const rv = new IntersectionObserver(
  (es) =>
    es.forEach((e) => {
      if (e.isIntersecting) {
        e.target.classList.add("in");
        rv.unobserve(e.target);
      }
    }),
  { threshold: 0.2 }
);
$$(".reveal").forEach((el) => (reduce ? el.classList.add("in") : rv.observe(el)));

/* ---------- copy buttons ---------- */
$$("[data-copy]").forEach((b) =>
  b.addEventListener("click", async () => {
    const v = b.dataset.copy;
    try {
      await navigator.clipboard.writeText(v);
      toast(`Copied ${v}`);
    } catch {
      toast(v);
    }
  })
);
