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
    this.chunks = []
    this.audioUrl = null
    this.recording = false
  }

  disconnect() {
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

    this.chunks = []
    this.mediaRecorder = new MediaRecorder(this.stream)

    this.mediaRecorder.addEventListener("dataavailable", (event) => {
      if (event.data.size > 0) this.chunks.push(event.data)
    })

    this.mediaRecorder.addEventListener("stop", () => {
      if (this.audioUrl) URL.revokeObjectURL(this.audioUrl)
      const blob = new Blob(this.chunks, { type: this.mediaRecorder.mimeType })
      this.audioUrl = URL.createObjectURL(blob)
      if (this.hasPlayButtonTarget) this.playButtonTarget.disabled = false
      this.setStatus(t("js.recorder.ready"))
      this.stopStream()
      this.report((performance.now() - this.startedAt) / 1000)
    })

    this.mediaRecorder.start()
    this.startedAt = performance.now()
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
