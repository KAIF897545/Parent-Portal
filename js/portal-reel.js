(function () {
  var frame = document.getElementById("portalReelFrame");
  if (!frame) return;

  var scenes = Array.prototype.slice.call(frame.querySelectorAll(".portal-reel__scene"));
  var progressWrap = document.getElementById("portalReelProgress");
  var playPauseBtn = document.getElementById("portalReelPlayPause");
  var replayBtn = document.getElementById("portalReelReplay");
  var sceneLabel = document.getElementById("portalReelSceneLabel");
  var wipeEl = document.getElementById("portalReelWipe");
  var flashEl = document.getElementById("portalReelFlash");
  var reduceMotion = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  var segs = scenes.map(function () {
    var seg = document.createElement("div");
    seg.className = "portal-reel__seg";
    var fill = document.createElement("span");
    fill.className = "portal-reel__seg-fill";
    seg.appendChild(fill);
    progressWrap.appendChild(seg);
    return seg;
  });

  var current = -1;
  var paused = false;
  var timer = null;

  function playTransitionFx() {
    if (reduceMotion) return;
    wipeEl.classList.remove("is-sweeping");
    flashEl.classList.remove("is-flashing");
    void wipeEl.offsetWidth;
    wipeEl.classList.add("is-sweeping");
    flashEl.classList.add("is-flashing");
  }

  function showScene(i) {
    current = i;
    playTransitionFx();

    scenes.forEach(function (s, idx) {
      s.classList.toggle("is-active", idx === i);
    });

    var dur = scenes[i].getAttribute("data-duration");

    segs.forEach(function (seg, idx) {
      seg.classList.remove("is-active", "is-done");
      if (idx < i) seg.classList.add("is-done");
    });

    var activeSeg = segs[i];
    var fillEl = activeSeg.querySelector(".portal-reel__seg-fill");
    fillEl.style.transition = "none";
    fillEl.style.width = "0%";
    activeSeg.style.setProperty("--seg-dur", dur + "ms");
    void fillEl.offsetWidth;
    activeSeg.classList.add("is-active");

    sceneLabel.textContent = "Scene " + (i + 1) + " / " + scenes.length;

    if (timer) clearTimeout(timer);
    if (!paused) {
      timer = setTimeout(function () {
        showScene((i + 1) % scenes.length);
      }, Number(dur));
    }
  }

  playPauseBtn.addEventListener("click", function () {
    paused = !paused;
    playPauseBtn.innerHTML = paused ? "&#9654;" : "&#10073;&#10073;";
    playPauseBtn.setAttribute("aria-label", paused ? "Play" : "Pause");

    var activeSeg = segs[current];
    var fillEl = activeSeg.querySelector(".portal-reel__seg-fill");

    if (paused) {
      if (timer) clearTimeout(timer);
      var computedWidth = getComputedStyle(fillEl).width;
      fillEl.style.animation = "none";
      fillEl.style.transition = "none";
      fillEl.style.width = computedWidth;
    } else {
      var dur = Number(scenes[current].getAttribute("data-duration"));
      var trackPx = activeSeg.clientWidth || 1;
      var startWidth = parseFloat(fillEl.style.width) || 0;
      var remainingRatio = 1 - startWidth / trackPx;
      var remainingMs = Math.max(dur * remainingRatio, 200);
      fillEl.style.transition = "width " + remainingMs + "ms linear";
      requestAnimationFrame(function () {
        fillEl.style.width = "100%";
      });
      timer = setTimeout(function () {
        showScene((current + 1) % scenes.length);
      }, remainingMs);
    }
  });

  replayBtn.addEventListener("click", function () {
    paused = false;
    playPauseBtn.innerHTML = "&#10073;&#10073;";
    playPauseBtn.setAttribute("aria-label", "Pause");
    showScene(0);
  });

  showScene(0);
})();
