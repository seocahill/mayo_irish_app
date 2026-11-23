import { Controller } from "@hotwired/stimulus"

// Counts how long a listening clip or a lesson's audio has been playing, Repeat included, and reports
// it to the course about every half minute, and when the learner pauses or
// leaves, so it counts towards minutes listened. Only time spent playing
// counts; a jump (seeking, Back 5 s) doesn't.
const REPORT_EVERY = 30

export default class extends Controller {
  static targets = ["audio"]
  static values = { reportUrl: String }

  connect() {
    this.listened = 0
    this.lastTime = null
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

  count() {
    const audio = this.audioTarget
    if (audio.paused || this.lastTime === null) return
    const now = audio.currentTime
    let step = now - this.lastTime
    // With Repeat on, the clip wraps to the start: count the bit up to the end too.
    if (step < 0 && audio.loop && Number.isFinite(audio.duration) && this.lastTime > audio.duration - 1.5) {
      step = audio.duration - this.lastTime + now
    }
    this.lastTime = now
    if (step <= 0 || step > 1.5) return

    this.listened += step
    if (this.listened >= REPORT_EVERY) this.report()
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
    }).catch(() => {})
  }
}
