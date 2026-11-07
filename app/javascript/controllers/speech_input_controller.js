import { Controller } from "@hotwired/stimulus"
import { t } from "translations"

// Records what the learner says and sends it with the form, as a file for the
// server to pass to the speech recogniser. Tap once to start, again to send.
// Recording stops on its own at the recogniser's 30-second limit. How long the
// learner spoke goes with it, for their minutes spoken.
const MAX_SECONDS = 30

export default class extends Controller {
  static targets = ["micButton", "audio", "input", "status", "spokenSeconds"]

  disconnect() {
    clearTimeout(this.timer)
    this.discard = true
    this.recorder?.state === "recording" && this.recorder.stop()
    this.stopStream()
  }

  async toggle() {
    if (this.recorder?.state === "recording") {
      this.recorder.stop()
    } else {
      await this.start()
    }
  }

  async start() {
    if (!navigator.mediaDevices?.getUserMedia || !window.MediaRecorder) {
      this.setStatus(t("js.speech_input.not_supported"), true)
      return
    }

    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    } catch (_) {
      this.setStatus(t("js.speech_input.no_permission"), true)
      return
    }

    const chunks = []
    this.discard = false
    this.recorder = new MediaRecorder(this.stream)
    this.recorder.addEventListener("dataavailable", (event) => {
      if (event.data.size > 0) chunks.push(event.data)
    })
    this.recorder.addEventListener("stop", () => {
      clearTimeout(this.timer)
      this.stopStream()
      delete this.micButtonTarget.dataset.state
      const seconds = Math.ceil((Date.now() - this.startedAt) / 1000)
      if (!this.discard && chunks.length) this.send(new Blob(chunks, { type: this.recorder.mimeType }), seconds)
    })

    this.recorder.start()
    this.startedAt = Date.now()
    this.timer = setTimeout(() => this.recorder.stop(), MAX_SECONDS * 1000)
    this.micButtonTarget.dataset.state = "recording"
    this.setStatus(t("js.speech_input.recording"))
  }

  send(blob, seconds) {
    const file = new File([blob], `speech.${this.extensionFor(blob.type)}`, { type: blob.type })
    const files = new DataTransfer()
    files.items.add(file)
    this.audioTarget.files = files.files
    if (this.hasSpokenSecondsTarget) this.spokenSecondsTarget.value = seconds
    this.inputTarget.value = ""
    this.setStatus(t("js.speech_input.sending"))
    this.element.requestSubmit()
  }

  // Chrome and Firefox record WebM or Ogg; Safari records MP4.
  extensionFor(type) {
    if (type.includes("mp4")) return "mp4"
    if (type.includes("ogg")) return "ogg"
    return "webm"
  }

  // Nothing typed and nothing recorded: don't send.
  submit(event) {
    if (!this.inputTarget.value.trim() && !this.audioTarget.files.length) event.preventDefault()
  }

  // While the form waits for the reply.
  busy() {
    this.micButtonTarget.disabled = true
  }

  // When the reply has arrived without the page reloading: the learner can
  // ask again, and the last recording isn't sent a second time.
  ready() {
    this.micButtonTarget.disabled = false
    this.audioTarget.value = ""
    this.setStatus("")
  }

  stopStream() {
    this.stream?.getTracks().forEach((track) => track.stop())
    this.stream = null
  }

  setStatus(text, isError = false) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = text
    this.statusTarget.classList.toggle("text-red-600", isError)
  }
}
