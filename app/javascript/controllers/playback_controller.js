import { Controller } from "@hotwired/stimulus"

// Plays a clip at three-quarter speed, and back again, and can repeat it, for working out fast speech.
export default class extends Controller {
  static targets = ["audio", "toggle", "loop"]

  toggleSlow() {
    const slow = this.audioTarget.playbackRate === 1
    this.audioTarget.playbackRate = slow ? 0.75 : 1
    this.toggleTarget.setAttribute("aria-pressed", slow)
  }

  toggleLoop() {
    this.audioTarget.loop = !this.audioTarget.loop
    this.loopTarget.setAttribute("aria-pressed", this.audioTarget.loop)
  }
}
