import { Controller } from "@hotwired/stimulus"
import { t } from "translations"

// Records a question for a native speaker. The learner listens back before
// sending, since a question takes up a real person's time: record, stop,
// listen, then send or record again. Recording stops on its own after a while.
const MAX_SECONDS = 120

export default class extends Controller {
  static targets = ["recordButton", "stopButton", "review", "preview", "audio", "status", "timer"]

  connect() {
    this.show("idle")
  }

  disconnect() {
    clearInterval(this.ticker)
    this.discard = true
    if (this.recorder?.state === "recording") this.recorder.stop()
    this.stopStream()
    if (this.previewUrl) URL.revokeObjectURL(this.previewUrl)
  }

  async start() {
    if (!navigator.mediaDevices?.getUserMedia || !window.MediaRecorder) {
      this.statusTarget.textContent = t("js.question_recorder.not_supported")
      return
    }

    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    } catch (_) {
      this.statusTarget.textContent = t("js.question_recorder.no_permission")
      return
    }

    const chunks = []
    this.discard = false
    this.recorder = new MediaRecorder(this.stream)
    this.recorder.addEventListener("dataavailable", (event) => {
      if (event.data.size > 0) chunks.push(event.data)
    })
    this.recorder.addEventListener("stop", () => {
      clearInterval(this.ticker)
      this.stopStream()
      if (!this.discard && chunks.length) this.review(new Blob(chunks, { type: this.recorder.mimeType }))
    })

    this.recorder.start()
    this.startedAt = Date.now()
    this.ticker = setInterval(() => this.tick(), 250)
    this.show("recording")
  }

  stop() {
    if (this.recorder?.state === "recording") this.recorder.stop()
  }

  again() {
    this.audioTarget.value = ""
    this.show("idle")
  }

  // Puts the recording in the form and lets the learner hear it before sending.
  review(blob) {
    const file = new File([blob], `question.${this.extensionFor(blob.type)}`, { type: blob.type })
    const files = new DataTransfer()
    files.items.add(file)
    this.audioTarget.files = files.files

    if (this.previewUrl) URL.revokeObjectURL(this.previewUrl)
    this.previewUrl = URL.createObjectURL(blob)
    this.previewTarget.src = this.previewUrl
    this.show("review")
  }

  tick() {
    const seconds = Math.floor((Date.now() - this.startedAt) / 1000)
    this.timerTarget.textContent = `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`
    if (seconds >= MAX_SECONDS) this.stop()
  }

  // Chrome and Firefox record WebM or Ogg; Safari records MP4.
  extensionFor(type) {
    if (type.includes("mp4")) return "mp4"
    if (type.includes("ogg")) return "ogg"
    return "webm"
  }

  show(state) {
    this.element.dataset.state = state
    this.recordButtonTarget.hidden = state !== "idle"
    this.stopButtonTarget.hidden = state !== "recording"
    this.reviewTarget.hidden = state !== "review"
    this.statusTarget.textContent = state === "recording" ? t("js.question_recorder.recording") : ""
  }

  stopStream() {
    this.stream?.getTracks().forEach((track) => track.stop())
    this.stream = null
  }
}
