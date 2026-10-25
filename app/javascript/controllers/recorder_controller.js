import { Controller } from "@hotwired/stimulus"

// Lets the learner record their own pronunciation and play it back
// straight away to compare against the native speaker audio.
export default class extends Controller {
  static targets = ["recordButton", "playButton", "status"]

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
    if (!navigator.mediaDevices?.getUserMedia) {
      this.setStatus("Not supported", true)
      return
    }

    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    } catch (e) {
      this.setStatus("No permission", true)
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
      this.setStatus("Ready")
      this.stopStream()
    })

    this.mediaRecorder.start()
    this.recording = true
    this.recordButtonTarget.classList.add("text-red-600", "animate-pulse")
    this.setStatus("Recording…")
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
    const audio = new Audio(this.audioUrl)
    audio.play()
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
