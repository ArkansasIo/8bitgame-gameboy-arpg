/*
 * ARPG GB Quest web player.
 * Runs the Game Boy Color ROM in binjgb (MIT, Ben Smith). Emulator glue adapted from
 * binjgb's docs/simple.js (MIT) and GB Studio's web player (MIT); see LICENSES.txt.
 */
"use strict";

const ROM_URL = "arpg_gb_quest.gbc";
const SRAM_KEY = "arpggbquest.sram.v1";
const MUTE_KEY = "arpggbquest.muted";
const W = 160, H = 144;
const CPU_HZ = 4194304;
const AUDIO_FRAMES = 4096;
const AUDIO_LATENCY = 0.1;
const MAX_STEP_SEC = 5 / 60;
const EV_FRAME = 1, EV_AUDIO = 2, EV_UNTIL = 4;
const CGB_COLOR_CURVE = 0;  // raw colours, as drawn

const $ = (s) => document.querySelector(s);
const store = {
  get(k) { try { return localStorage.getItem(k); } catch (e) { return null; } },
  set(k, v) { try { localStorage.setItem(k, v); } catch (e) { /* storage unavailable */ } },
};

// ---------------------------------------------------------------- layout
function fit() {
  const frame = $("#frame");
  const touch = document.body.classList.contains("touch");
  const availH = window.innerHeight * (touch ? 0.56 : 0.70);
  const availW = window.innerWidth * 0.92 - 28;
  let s = Math.min(availW / W, availH / H);
  s = s >= 2 ? Math.floor(s) : Math.max(1, Math.round(s * 4) / 4);
  frame.style.setProperty("--s", s);
}
window.addEventListener("resize", fit);

// ---------------------------------------------------------------- embers
(function embers() {
  const c = $("#embers"), g = c.getContext("2d");
  const motes = [];
  let w = 0, h = 0;
  const size = () => { w = c.width = innerWidth; h = c.height = innerHeight; };
  size(); addEventListener("resize", size);
  const spawn = (y) => ({
    x: Math.random() * w, y: y ?? h + 10, r: Math.random() * 1.6 + .4,
    vy: -(Math.random() * .35 + .12), vx: (Math.random() - .5) * .25,
    life: Math.random() * .6 + .4, ph: Math.random() * 6.28,
  });
  for (let i = 0; i < 55; i++) motes.push(spawn(Math.random() * h));
  const still = matchMedia("(prefers-reduced-motion: reduce)").matches;
  function tick(t) {
    g.clearRect(0, 0, w, h);
    for (const m of motes) {
      if (!still) { m.x += m.vx + Math.sin(t / 1400 + m.ph) * .15; m.y += m.vy; }
      if (m.y < -10) Object.assign(m, spawn());
      const a = m.life * (0.35 + 0.35 * Math.sin(t / 500 + m.ph));
      g.fillStyle = `rgba(255,${120 + (m.r * 40) | 0},40,${a})`;
      g.beginPath(); g.arc(m.x, m.y, m.r, 0, 6.283); g.fill();
    }
    if (!still) requestAnimationFrame(tick);
  }
  requestAnimationFrame(tick);
})();

// ---------------------------------------------------------------- input
const BTN = ["up", "down", "left", "right", "a", "b", "start", "select"];
const held = { key: new Set(), pad: new Set(), touch: new Set() };
const KEYMAP = {
  ArrowUp: "up", ArrowDown: "down", ArrowLeft: "left", ArrowRight: "right",
  KeyW: "up", KeyS: "down", KeyA: "left", KeyD: "right",
  KeyX: "a", KeyJ: "a", KeyZ: "b", KeyK: "b",
  Enter: "start", NumpadEnter: "start", ShiftLeft: "select", ShiftRight: "select", Backspace: "select",
};
addEventListener("keydown", (e) => {
  const b = KEYMAP[e.code];
  if (b) { held.key.add(b); e.preventDefault(); }
  else if (e.code === "KeyM" && !e.repeat) toggleMute();
  else if (e.code === "KeyF" && !e.repeat) toggleFullscreen();
});
addEventListener("keyup", (e) => { const b = KEYMAP[e.code]; if (b) { held.key.delete(b); e.preventDefault(); } });
addEventListener("blur", () => { held.key.clear(); held.touch.clear(); });

function pollGamepads() {
  held.pad.clear();
  const pads = navigator.getGamepads ? navigator.getGamepads() : [];
  for (const p of pads) {
    if (!p) continue;
    const on = (i) => p.buttons[i] && p.buttons[i].pressed;
    if (on(0) || on(3)) held.pad.add("a");
    if (on(1) || on(2)) held.pad.add("b");
    if (on(9)) held.pad.add("start");
    if (on(8)) held.pad.add("select");
    const ax = p.axes[0] || 0, ay = p.axes[1] || 0;
    if (on(12) || ay < -0.5) held.pad.add("up");
    if (on(13) || ay > 0.5) held.pad.add("down");
    if (on(14) || ax < -0.5) held.pad.add("left");
    if (on(15) || ax > 0.5) held.pad.add("right");
  }
}

function bindTouch() {
  const dpad = $("#dpad");
  const dirs = ["up", "down", "left", "right"];
  const fromPoint = (t) => {
    const r = dpad.getBoundingClientRect();
    const x = (t.clientX - r.left) / r.width * 2 - 1, y = (t.clientY - r.top) / r.height * 2 - 1;
    dirs.forEach((d) => held.touch.delete(d));
    if (Math.abs(x) > .2) held.touch.add(x < 0 ? "left" : "right");
    if (Math.abs(y) > .2) held.touch.add(y < 0 ? "up" : "down");
  };
  const dmove = (e) => { e.preventDefault(); fromPoint(e.targetTouches[0]); };
  dpad.addEventListener("touchstart", dmove, { passive: false });
  dpad.addEventListener("touchmove", dmove, { passive: false });
  dpad.addEventListener("touchend", (e) => { e.preventDefault(); dirs.forEach((d) => held.touch.delete(d)); }, { passive: false });
  document.querySelectorAll("#pad [data-btn]").forEach((el) => {
    const b = el.dataset.btn;
    el.addEventListener("touchstart", (e) => { e.preventDefault(); held.touch.add(b); el.classList.add("on"); begin(); }, { passive: false });
    el.addEventListener("touchend", (e) => { e.preventDefault(); held.touch.delete(b); el.classList.remove("on"); }, { passive: false });
  });
  addEventListener("touchstart", () => { if (!document.body.classList.contains("touch")) { document.body.classList.add("touch"); fit(); } }, { passive: true });
  addEventListener("keydown", () => { if (document.body.classList.contains("touch")) { document.body.classList.remove("touch"); fit(); } });
}

// ---------------------------------------------------------------- audio
let actx = null;
let muted = store.get(MUTE_KEY) === "1";
function audioCtx() {
  if (!actx) {
    const AC = window.AudioContext || window.webkitAudioContext;
    actx = AC ? new AC() : null;
  }
  return actx;
}
function toggleMute() {
  muted = !muted;
  store.set(MUTE_KEY, muted ? "1" : "0");
  $("#muteLabel").textContent = muted ? "Sound off" : "Sound on";
}
function toggleFullscreen() {
  const el = $("#frame");
  try {
    if (document.fullscreenElement) document.exitFullscreen();
    else if (el.requestFullscreen) el.requestFullscreen();
  } catch (e) { /* not allowed here */ }
}
document.addEventListener("fullscreenchange", fit);

// ---------------------------------------------------------------- emulator
let mod = null, e = 0, romPtr = 0, audioBuf = null, frameBuf = null;
let ctx2d = null, image = null;
let lastSec = 0, leftover = 0, audioStart = 0, sramDirty = false, running = false;

const wasmBytes = (ptr, size) => new Uint8Array(mod.HEAP8.buffer, ptr, size);

function withFile(ptr, cb) {
  const buf = wasmBytes(mod._get_file_data_ptr(ptr), mod._get_file_data_size(ptr));
  const out = cb(ptr, buf);
  mod._file_data_delete(ptr);
  mod._free(ptr);
  return out;
}
function loadSram() {
  const s = store.get(SRAM_KEY);
  if (!s) return;
  let bytes;
  try { bytes = Uint8Array.from(atob(s), (c) => c.charCodeAt(0)); } catch (err) { return; }
  withFile(mod._ext_ram_file_data_new(e), (ptr, buf) => {
    if (buf.length === bytes.length) { buf.set(bytes); mod._emulator_read_ext_ram(e, ptr); }
  });
}
function saveSram() {
  if (!e) return;
  const bytes = withFile(mod._ext_ram_file_data_new(e), (ptr, buf) => {
    mod._emulator_write_ext_ram(e, ptr);
    return new Uint8Array(buf);
  });
  let s = "";
  for (let i = 0; i < bytes.length; i += 0x8000) s += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000));
  store.set(SRAM_KEY, btoa(s));
  sramDirty = false;
}
setInterval(() => { if (sramDirty) saveSram(); }, 1000);
addEventListener("pagehide", () => { if (sramDirty) saveSram(); });
document.addEventListener("visibilitychange", () => {
  if (document.hidden) { if (sramDirty) saveSram(); if (actx) actx.suspend(); }
  else if (actx && running) actx.resume();
});

function pushAudio() {
  if (!actx || actx.state !== "running") return;
  const now = actx.currentTime;
  audioStart = audioStart || now + AUDIO_LATENCY;
  if (audioStart < now) { audioStart = now + AUDIO_LATENCY; return; }
  const b = actx.createBuffer(2, AUDIO_FRAMES, actx.sampleRate);
  const l = b.getChannelData(0), r = b.getChannelData(1);
  const vol = muted ? 0 : 0.5 / 255;
  for (let i = 0; i < AUDIO_FRAMES; i++) { l[i] = audioBuf[2 * i] * vol; r[i] = audioBuf[2 * i + 1] * vol; }
  const src = actx.createBufferSource();
  src.buffer = b; src.connect(actx.destination); src.start(audioStart);
  audioStart += AUDIO_FRAMES / actx.sampleRate;
}

function applyInput() {
  pollGamepads();
  const on = (b) => held.key.has(b) || held.pad.has(b) || held.touch.has(b);
  let u = on("up"), d = on("down"), l = on("left"), r = on("right");
  if (u && d) u = d = false;
  if (l && r) l = r = false;
  mod._set_joyp_up(e, u); mod._set_joyp_down(e, d);
  mod._set_joyp_left(e, l); mod._set_joyp_right(e, r);
  mod._set_joyp_A(e, on("a")); mod._set_joyp_B(e, on("b"));
  mod._set_joyp_start(e, on("start")); mod._set_joyp_select(e, on("select"));
}

function runUntil(ticks) {
  for (;;) {
    const ev = mod._emulator_run_until_f64(e, ticks);
    if (ev & EV_FRAME) image.data.set(frameBuf);
    if (ev & EV_AUDIO) pushAudio();
    if (ev & EV_UNTIL) break;
  }
  if (mod._emulator_was_ext_ram_updated(e)) sramDirty = true;
}

function frame(ms) {
  requestAnimationFrame(frame);
  if (document.hidden) { lastSec = 0; return; }
  const sec = ms / 1000;
  const dt = Math.min(Math.max(sec - (lastSec || sec), 0), MAX_STEP_SEC);
  lastSec = sec;
  applyInput();
  const target = mod._emulator_get_ticks_f64(e) + dt * CPU_HZ - leftover;
  runUntil(target);
  leftover = (mod._emulator_get_ticks_f64(e) - target) | 0;
  ctx2d.putImageData(image, 0, 0);
}

async function boot() {
  fit();
  bindTouch();
  $("#muteLabel").textContent = muted ? "Sound off" : "Sound on";
  const canvas = $("#lcd");
  ctx2d = canvas.getContext("2d");
  image = ctx2d.createImageData(W, H);
  ctx2d.fillStyle = "#07060a"; ctx2d.fillRect(0, 0, W, H);
  const [m, rom] = await Promise.all([Binjgb(), fetch(ROM_URL).then((r) => r.arrayBuffer())]);
  mod = m;
  const size = (rom.byteLength + 0x7fff) & ~0x7fff;
  romPtr = mod._malloc(size);
  wasmBytes(romPtr, size).fill(0).set(new Uint8Array(rom));
  const ac = audioCtx();
  e = mod._emulator_new_simple(romPtr, size, ac ? ac.sampleRate : 44100, AUDIO_FRAMES, CGB_COLOR_CURVE);
  if (!e) throw new Error("The ROM could not be loaded.");
  mod._emulator_set_default_joypad_callback(e, mod._joypad_new());
  audioBuf = wasmBytes(mod._get_audio_buffer_ptr(e), mod._get_audio_buffer_capacity(e));
  frameBuf = wasmBytes(mod._get_frame_buffer_ptr(e), mod._get_frame_buffer_size(e));
  loadSram();
  if (pendingBegin) begin();
}

let pendingBegin = false;
function begin() {
  if (running) return;
  if (!e) { pendingBegin = true; return; }
  running = true;
  $("#begin").classList.add("gone");
  const ac = audioCtx();
  if (ac && ac.state !== "running") ac.resume().catch(() => {});
  requestAnimationFrame(frame);
}
$("#begin").addEventListener("click", begin);
addEventListener("keydown", begin);
addEventListener("pointerdown", (ev) => { if (ev.pointerType !== "touch") begin(); });

boot().catch((err) => {
  console.error(err);
  $("#begin .go").textContent = "Could not start the game";
  $("#begin .hint").textContent = String(err.message || err);
});
