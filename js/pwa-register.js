// Registers the service worker (see sw.js) and shows a small "Install app"
// button once the browser says the site is actually installable, so people
// don't have to know the browser menu's own "Add to Home Screen" is there.

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/sw.js");
  });
}

(function installButton() {
  const DISMISS_KEY = "pwaInstallDismissed";

  function isStandalone() {
    return (
      window.matchMedia("(display-mode: standalone)").matches ||
      window.navigator.standalone === true
    );
  }

  function isIOS() {
    return /iphone|ipad|ipod/i.test(navigator.userAgent);
  }

  if (isStandalone()) return; // already installed, nothing to offer

  let deferredPrompt = null;
  let toastEl = null;

  function injectStyles() {
    if (document.getElementById("pwaInstallStyles")) return;
    const style = document.createElement("style");
    style.id = "pwaInstallStyles";
    style.textContent = `
      .pwa-install-toast {
        position: fixed;
        left: 50%;
        bottom: 18px;
        transform: translateX(-50%);
        z-index: 9999;
        display: flex;
        align-items: center;
        gap: 10px;
        max-width: calc(100vw - 24px);
        padding: 10px 12px;
        border-radius: 999px;
        background: #280113;
        border: 1px solid rgba(236, 236, 218, 0.16);
        box-shadow: 0 12px 32px rgba(0, 0, 0, 0.4);
        font-family: -apple-system, BlinkMacSystemFont, "Inter", sans-serif;
      }
      .pwa-install-toast img {
        width: 26px;
        height: 26px;
        border-radius: 7px;
        flex-shrink: 0;
      }
      .pwa-install-toast__text {
        color: #ececda;
        font-size: 13.5px;
        font-weight: 600;
        white-space: nowrap;
      }
      .pwa-install-toast__action {
        border: none;
        background: #7b1843;
        color: #fff;
        font-weight: 700;
        font-size: 13px;
        padding: 7px 14px;
        border-radius: 999px;
        cursor: pointer;
        white-space: nowrap;
      }
      .pwa-install-toast__action:hover { background: #40021e; }
      .pwa-install-toast__dismiss {
        border: none;
        background: transparent;
        color: rgba(236, 236, 218, 0.6);
        font-size: 18px;
        line-height: 1;
        cursor: pointer;
        padding: 4px 2px;
      }
      .pwa-install-toast__dismiss:hover { color: #ececda; }
      @media (max-width: 420px) {
        .pwa-install-toast__text { display: none; }
      }
    `;
    document.head.appendChild(style);
  }

  function dismiss() {
    localStorage.setItem(DISMISS_KEY, "1");
    if (toastEl) toastEl.remove();
    toastEl = null;
  }

  function showToast({ label, onAction }) {
    if (toastEl) return;
    injectStyles();
    toastEl = document.createElement("div");
    toastEl.className = "pwa-install-toast";
    toastEl.innerHTML = `
      <img src="/assets/icons/icon-192.png" alt="" />
      <span class="pwa-install-toast__text">Install this app on your device</span>
      <button type="button" class="pwa-install-toast__action">${label}</button>
      <button type="button" class="pwa-install-toast__dismiss" aria-label="Dismiss">×</button>
    `;
    toastEl.querySelector(".pwa-install-toast__action").addEventListener("click", onAction);
    toastEl.querySelector(".pwa-install-toast__dismiss").addEventListener("click", dismiss);
    document.body.appendChild(toastEl);
  }

  function showInstallInstructions() {
    if (document.getElementById("pwaIOSSheet")) return;
    const sheet = document.createElement("div");
    sheet.id = "pwaIOSSheet";
    sheet.style.cssText = `
      position: fixed; inset: 0; z-index: 10000; display: flex;
      align-items: flex-end; justify-content: center;
      background: rgba(0,0,0,0.5); font-family: -apple-system, BlinkMacSystemFont, "Inter", sans-serif;
    `;
    const text = isIOS()
      ? `Tap the <strong>Share</strong> icon <span aria-hidden="true">⬆️</span> in your browser's toolbar, then choose <strong>"Add to Home Screen"</strong>.`
      : `Look for <strong>Install app</strong> or <strong>Add to Home Screen</strong> in your browser's menu (usually the ⋮ or ≡ icon).`;
    sheet.innerHTML = `
      <div style="background:#280113; color:#ececda; width:100%; max-width:420px;
                  border-radius:18px 18px 0 0; padding:20px 22px 26px; box-shadow:0 -12px 32px rgba(0,0,0,0.5);">
        <div style="font-weight:700; font-size:16px; margin-bottom:10px;">Install this app</div>
        <div style="font-size:14px; line-height:1.5; color:rgba(236,236,218,0.85);">${text}</div>
        <button type="button" id="pwaIOSSheetClose"
          style="margin-top:16px; width:100%; border:none; background:#7b1843; color:#fff;
                 font-weight:700; font-size:14px; padding:11px; border-radius:999px; cursor:pointer;">
          Got it
        </button>
      </div>
    `;
    document.body.appendChild(sheet);
    const close = () => sheet.remove();
    sheet.querySelector("#pwaIOSSheetClose").addEventListener("click", close);
    sheet.addEventListener("click", (e) => {
      if (e.target === sheet) close();
    });
  }

  // Shared by the toast's action button and the permanent nav link: use the
  // captured native prompt if we have one, otherwise fall back to manual
  // instructions (always the case on iOS, which never fires beforeinstallprompt).
  async function triggerInstall() {
    if (deferredPrompt) {
      const p = deferredPrompt;
      deferredPrompt = null;
      p.prompt();
      await p.userChoice;
    } else {
      showInstallInstructions();
    }
  }

  window.addEventListener("beforeinstallprompt", (e) => {
    e.preventDefault();
    deferredPrompt = e;
    if (!localStorage.getItem(DISMISS_KEY)) {
      showToast({
        label: "Install",
        onAction: async () => {
          if (toastEl) toastEl.remove();
          toastEl = null;
          await triggerInstall();
        },
      });
    }
  });

  window.addEventListener("appinstalled", () => {
    if (toastEl) toastEl.remove();
    toastEl = null;
    localStorage.setItem(DISMISS_KEY, "1");
  });

  if (isIOS() && !localStorage.getItem(DISMISS_KEY)) {
    // iOS never fires beforeinstallprompt -- offer manual instructions instead.
    window.addEventListener("load", () => {
      showToast({ label: "Install", onAction: showInstallInstructions });
    });
  }

  // Permanent "Add to Home Screen" nav link -- always available (not gated
  // by the toast's dismiss state), so people who dismissed the popup once
  // can still find a way to install later.
  const navBtn = document.getElementById("navInstall");
  if (navBtn) {
    navBtn.style.display = "";
    navBtn.addEventListener("click", (e) => {
      e.preventDefault();
      triggerInstall();
    });
  }
})();

// Launch splash: a brief logo + title animation on a true PWA cold launch
// (standalone mode), gated by sessionStorage so it plays once per session,
// not on every page. The "pwa-launch" class is set synchronously by an
// inline <head> script before paint, so by the time this (deferred) code
// runs the splash is already on screen -- this just times its exit and
// plays a short chime.
(function pwaSplash() {
  const el = document.getElementById("pwaSplash");
  if (!el || !document.documentElement.classList.contains("pwa-launch")) return;
  sessionStorage.setItem("mccSplashShown", "1");

  // Small synthesized two-note chime -- no audio file needed. Browsers
  // (especially iOS) can block audio that isn't tied to a direct user
  // gesture, so this may not always be audible; it fails silently if so.
  try {
    const Ctx = window.AudioContext || window.webkitAudioContext;
    if (Ctx) {
      const ctx = new Ctx();
      const now = ctx.currentTime;
      [660, 880].forEach((freq, i) => {
        const start = now + i * 0.14;
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "sine";
        osc.frequency.value = freq;
        gain.gain.setValueAtTime(0, start);
        gain.gain.linearRampToValueAtTime(0.18, start + 0.03);
        gain.gain.exponentialRampToValueAtTime(0.0001, start + 0.35);
        osc.connect(gain).connect(ctx.destination);
        osc.start(start);
        osc.stop(start + 0.4);
      });
      setTimeout(() => ctx.close(), 900);
    }
  } catch (e) {}

  setTimeout(() => {
    el.classList.add("pwa-splash--hide");
    setTimeout(() => el.remove(), 650);
  }, 2400);
})();
