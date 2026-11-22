import { Controller } from "@hotwired/stimulus"
import { t } from "translations"

// Lets the learner record their own pronunciation and play it back
// straight away to compare against the native speaker audio. The recording
// stays in the browser; only its length is reported, so it counts towards
// minutes spoken.
export default class extends Controller {
  static targets = ["recordButton", "playButton", "status"]
  static values = { reportUrl: String }

  connect() {
    this.mediaRecorder = null
    this.take = null
    this.audioUrl = null
    this.recording = false
    // One recorder at a time (the word list has one per word), so time isn't counted twice.
    this.onOtherStarted = (event) => { if (event.detail !== this && this.recording) this.stop() }
    // Leaving mid-recording still counts what was said.
    this.onPageHide = () => { if (this.recording) this.reportTake(this.take) }
    window.addEventListener("recorder:started", this.onOtherStarted)
    window.addEventListener("pagehide", this.onPageHide)
  }

  disconnect() {
    window.removeEventListener("recorder:started", this.onOtherStarted)
    window.removeEventListener("pagehide", this.onPageHide)
    if (this.recording) {
      this.reportTake(this.take)
      this.stop()
    }
    this.stopStream()
    if (this.audioUrl) URL.revokeObjectURL(this.audioUrl)
  }

  async toggle() {
    if (this.recording) {
      this.stop()
    } else {
      await this.start()
    }
  }

  async start() {
    this.pausePageAudio()
    if (!navigator.mediaDevices?.getUserMedia) {
      this.setStatus(t("js.recorder.not_supported"), true)
      return
    }

    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    } catch (e) {
      this.setStatus(t("js.recorder.no_permission"), true)
      return
    }

    // Kept per recording, so a late stop event can't touch the next one.
    const stream = this.stream
    const chunks = []
    const recorder = new MediaRecorder(stream)
    const take = { startedAt: performance.now(), reported: false }
    this.mediaRecorder = recorder
    this.take = take

    recorder.addEventListener("dataavailable", (event) => {
      if (event.data.size > 0) chunks.push(event.data)
    })

    recorder.addEventListener("stop", () => {
      if (this.audioUrl) URL.revokeObjectURL(this.audioUrl)
      const blob = new Blob(chunks, { type: recorder.mimeType })
      this.audioUrl = URL.createObjectURL(blob)
      if (this.hasPlayButtonTarget) this.playButtonTarget.disabled = false
      this.setStatus(t("js.recorder.ready"))
      stream.getTracks().forEach((track) => track.stop())
      if (this.stream === stream) this.stream = null
      this.reportTake(take)
    })

    recorder.start()
    take.startedAt = performance.now()
    window.dispatchEvent(new CustomEvent("recorder:started", { detail: this }))
    this.recording = true
    this.recordButtonTarget.classList.add("text-red-600", "animate-pulse")
    this.setStatus(t("js.recorder.recording"))
  }

  stop() {
    if (this.mediaRecorder && this.mediaRecorder.state !== "inactive") {
      this.mediaRecorder.stop()
    }
    this.recording = false
    this.recordButtonTarget.classList.remove("text-red-600", "animate-pulse")
  }

  play() {
    if (!this.audioUrl) return
    this.pausePageAudio()
    const audio = new Audio(this.audioUrl)
    audio.play()
  }

  // Stop the speaker's audio (even a clip set to repeat) so the mic doesn't
  // pick it up and the learner's recording doesn't play over it.
  pausePageAudio() {
    document.querySelectorAll("audio").forEach((audio) => audio.pause())
  }

  reportTake(take) {
    if (!take || take.reported) return
    take.reported = true
    this.report((performance.now() - take.startedAt) / 1000)
  }

  // The server caps each recording, so one left running counts as half a minute at most.
  report(seconds) {
    seconds = Math.round(seconds)
    if (seconds < 1 || !this.hasReportUrlValue) return

    const body = new FormData()
    body.append("seconds", seconds)
    fetch(this.reportUrlValue, {
      method: "POST",
      body,
      keepalive: true,
      headers: { "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content }
    }).catch(() => {})
  }

  stopStream() {
    if (this.stream) {
      this.stream.getTracks().forEach((track) => track.stop())
      this.stream = null
    }
  }

  setStatus(text, isError = false) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = text
    this.statusTarget.classList.toggle("text-red-500", isError)
    this.statusTarget.classList.toggle("text-stone-400", !isError)
  }
}
