import { Controller } from "@hotwired/stimulus"

// Plays a clip at three-quarter speed, and back again, and can repeat it, for
// working out fast speech. "Back 5 s" catches the word just missed. On a
// keyboard, Space plays or pauses, and the left and right arrows go back or
// forward five seconds, unless the learner is typing or on another control.
// The keys work the player played last, else the first one in view; with
// none in view they do nothing, so Space still scrolls the page.
const SKIP = 5
const players = []
let lastPlayed = null

export default class extends Controller {
  static targets = ["audio", "toggle", "loop"]

  connect() {
    players.push(this)
    // Kept, so disconnect can still reach it once the page has gone.
    this.audio = this.audioTarget
    this.onPlay = () => { lastPlayed = this }
    this.audio.addEventListener("play", this.onPlay)
    if (players.length === 1) window.addEventListener("keydown", keydown)
  }

  disconnect() {
    players.splice(players.indexOf(this), 1)
    this.audio.removeEventListener("play", this.onPlay)
    if (lastPlayed === this) lastPlayed = null
    if (players.length === 0) window.removeEventListener("keydown", keydown)
  }

  toggleSlow() {
    const slow = this.audioTarget.playbackRate === 1
    this.audioTarget.playbackRate = slow ? 0.75 : 1
    this.toggleTarget.setAttribute("aria-pressed", slow)
  }

  toggleLoop() {
    this.audioTarget.loop = !this.audioTarget.loop
    this.loopTarget.setAttribute("aria-pressed", this.audioTarget.loop)
  }

  back() {
    this.skip(-SKIP)
  }

  forward() {
    this.skip(SKIP)
  }

  playPause() {
    const audio = this.audioTarget
    audio.paused ? audio.play().catch(() => {}) : audio.pause()
  }

  // Tells the transcript, if there is one, so Repeat line lets go of a line
  // the learner has skipped out of.
  skip(seconds) {
    const audio = this.audioTarget
    const end = Number.isFinite(audio.duration) ? audio.duration : Infinity
    audio.currentTime = Math.min(Math.max(audio.currentTime + seconds, 0), end)
    this.dispatch("skipped", { detail: { time: audio.currentTime } })
  }
}

const KEYS = { " ": "playPause", ArrowLeft: "back", ArrowRight: "forward" }
// Places where the keys already mean something else.
const TYPING = "input, textarea, select, audio, video, [contenteditable], [role=slider]"

function keydown(event) {
  const action = KEYS[event.key]
  if (!action || event.defaultPrevented || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return
  // Holding Space down would flip between play and pause.
  if (event.key === " " && event.repeat) return
  if (event.target.closest?.(TYPING)) return
  // Space presses a focused button or link; the arrows mean nothing to those, so they still skip.
  if (event.key === " " && event.target.closest?.("button, a, summary")) return

  const player = players.includes(lastPlayed) ? lastPlayed : players.find(inView)
  if (!player) return
  event.preventDefault()
  player[action]()
}

function inView(player) {
  const box = player.element.getBoundingClientRect()
  return box.bottom > 0 && box.top < window.innerHeight
}
