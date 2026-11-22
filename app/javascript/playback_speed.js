// The learner's listening speed: 1×, 0.9× or 0.75×, kept on this device only
// (localStorage) and used by every learner's player, so a speed set once
// sticks. Nothing is sent to the server. The steps stay near 1× because native
// speed is the goal, and slower than 0.75× distorts the speech.
export const SPEEDS = [1, 0.9, 0.75]
const KEY = "playback:speed"

// Kept here too, so the choice still lasts for this page when storage is blocked.
let current = stored()

function stored() {
  try {
    const speed = Number(localStorage.getItem(KEY))
    return SPEEDS.includes(speed) ? speed : 1
  } catch {
    return 1
  }
}

export function savedSpeed() {
  return current
}

export function saveSpeed(speed) {
  current = speed
  try {
    speed === 1 ? localStorage.removeItem(KEY) : localStorage.setItem(KEY, String(speed))
  } catch { /* private mode: lasts for this page only */ }
}

export function nextSpeed(speed) {
  return SPEEDS[(SPEEDS.indexOf(speed) + 1) % SPEEDS.length]
}

// Loading a new source resets playbackRate to defaultPlaybackRate, so set both.
export function applySpeed(audio, speed = current) {
  audio.defaultPlaybackRate = speed
  audio.playbackRate = speed
  audio.preservesPitch = true
}

// Word audio on review cards, Say it and the lesson word list has no speed
// button of its own; marked data-saved-speed, it plays at the saved speed.
// Unmarked players (an editor judging a submission, a learner's own question)
// keep the real speed, and so does recorder playback, which is never in the
// page. A speed picked in the browser's own player menu is left alone.
document.addEventListener("play", (event) => {
  const audio = event.target
  if (!(audio instanceof HTMLAudioElement) || !audio.hasAttribute("data-saved-speed")) return
  if (audio.playbackRate === audio.defaultPlaybackRate && audio.playbackRate !== current) applySpeed(audio)
}, true)

// A speed changed in another tab.
window.addEventListener("storage", (event) => {
  if (event.key !== KEY && event.key !== null) return
  current = stored()
  window.dispatchEvent(new CustomEvent("playback-speed:changed", { detail: { speed: current } }))
})
