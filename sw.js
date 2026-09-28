// Minimal service worker — exists only to satisfy the "installable PWA"
// requirement (Chrome/Android require a registered service worker with a
// fetch handler before it will offer "Add to Home screen" as a real app
// install rather than a plain bookmark shortcut).
//
// Deliberately does no caching: this app's pages call Supabase for live,
// per-user data, so caching responses here would risk serving stale
// student/coach data or an out-of-date build. Every request just passes
// straight through to the network.

self.addEventListener("install", () => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener("fetch", (event) => {
  event.respondWith(fetch(event.request));
});
