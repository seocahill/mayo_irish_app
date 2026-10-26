import { Controller } from "@hotwired/stimulus"
import { t } from "translations"

// Plays synthetic speech from a URL. The first play fetches it (and the browser
// keeps it), so the button shows a busy state while it loads. With autoplay it
// plays once on its own; if the browser won't allow that, the button still works.
export default class extends Controller {
  static targets = ["button", "status"]
  static values = { src: String, autoplay: Boolean }

  connect() {
    if (!this.autoplayValue) return
    this.audio = this.buildAudio()
    this.audio.play().catch(() => this.setState(null))
  }

  disconnect() {
    this.audio?.pause()
  }

  // The speakable controller points one button at each new selection.
  srcValueChanged() {
    this.audio?.pause()
    this.audio = null
    if (this.hasButtonTarget) this.setState(null)
  }

  async play() {
    this.audio ??= this.buildAudio()
    this.audio.currentTime = 0
    this.setState("loading")

    try {
      await this.audio.play()
    } catch (_) {
      this.fail()
    }
  }

  buildAudio() {
    const audio = new Audio(this.srcValue)
    audio.addEventListener("playing", () => this.setState(null))
    audio.addEventListener("ended", () => this.setState(null))
    audio.addEventListener("error", () => this.fail())
    return audio
  }

  fail() {
    this.audio = null
    this.setState("error")
    if (this.hasStatusTarget) this.statusTarget.textContent = t("js.pronounce.failed")
  }

  setState(state) {
    if (state) {
      this.buttonTarget.dataset.state = state
    } else {
      delete this.buttonTarget.dataset.state
    }
    if (state !== "error" && this.hasStatusTarget) this.statusTarget.textContent = ""
  }
}
