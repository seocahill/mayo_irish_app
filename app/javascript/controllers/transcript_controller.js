import { Controller } from "@hotwired/stimulus"

// Follows a recording's transcript as it plays: the line being said is marked
// and kept in view, and tapping a line plays from there. Also reports to the
// course, every half minute or so, how long the learner has been listening.
const REPORT_EVERY = 30
// How long a line stays marked after it ends, through a speaker's pause.
const HOLD = 3

export default class extends Controller {
  static targets = ["audio", "line", "english", "englishToggle", "repeatToggle"]
  static values = { start: Number, reportUrl: String }

  connect() {
    this.listened = 0
    this.lastTime = null
    this.audioTarget.addEventListener("loadedmetadata", () => {
      if (this.startValue > 0) this.audioTarget.currentTime = this.startValue
    }, { once: true })
    this.flush = () => this.report()
    window.addEventListener("pagehide", this.flush)
  }

  disconnect() {
    window.removeEventListener("pagehide", this.flush)
    this.report()
  }

  started() {
    this.lastTime = this.audioTarget.currentTime
  }

  follow() {
    const now = this.audioTarget.currentTime
    this.count(now)
    if (this.repeatLine(now)) return
    this.mark(now)
  }

  // With Repeat on, the line being said plays over and over.
  toggleRepeat() {
    const on = this.repeatToggleTarget.getAttribute("aria-pressed") !== "true"
    this.repeating = on ? this.current : null
    if (on && !this.repeating) return
    this.repeatToggleTarget.setAttribute("aria-pressed", on)
  }

  repeatLine(now) {
    if (!this.repeating || this.audioTarget.paused) return false
    // timeupdate is coarse, so jump back a little early
    if (now < Number(this.repeating.dataset.end) - 0.15) return false
    this.audioTarget.currentTime = Number(this.repeating.dataset.start)
    this.lastTime = this.audioTarget.currentTime
    return true
  }

  seek(event) {
    if (this.repeating) this.repeating = event.currentTarget
    this.audioTarget.currentTime = Number(event.currentTarget.dataset.start)
    this.lastTime = this.audioTarget.currentTime
    this.audioTarget.play()
  }

  toggleEnglish() {
    const show = this.englishToggleTarget.getAttribute("aria-pressed") !== "true"
    this.englishTargets.forEach((line) => { line.hidden = !show })
    this.englishToggleTarget.setAttribute("aria-pressed", show)
  }

  // Only time spent playing counts; a jump (seeking) doesn't.
  count(now) {
    if (this.audioTarget.paused || this.lastTime === null) return
    const step = now - this.lastTime
    this.lastTime = now
    if (step <= 0 || step > 1.5) return

    this.listened += step
    if (this.listened >= REPORT_EVERY) this.report()
  }

  // The line being said, held through a short pause. Only checked lines are
  // shown, so a recording can go minutes without one; nothing is marked there,
  // rather than a line from long before.
  mark(now) {
    const current = this.lineTargets.findLast((line) =>
      Number(line.dataset.start) <= now && now < Number(line.dataset.end) + HOLD)
    if (current === this.current) return

    this.current?.removeAttribute("aria-current")
    current?.setAttribute("aria-current", "true")
    current?.scrollIntoView({ block: "center", behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth" })
    this.current = current
  }

  report() {
    const seconds = Math.round(this.listened)
    if (seconds < 1 || !this.hasReportUrlValue) return

    this.listened -= seconds
    const body = new FormData()
    body.append("seconds", seconds)
    fetch(this.reportUrlValue, {
      method: "PATCH",
      body,
      keepalive: true,
      headers: { "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content }
    })
  }
}
