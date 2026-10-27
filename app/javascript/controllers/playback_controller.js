import { Controller } from "@hotwired/stimulus"

// Plays a clip at three-quarter speed, and back again, for working out fast speech.
export default class extends Controller {
  static targets = ["audio", "toggle"]

  toggleSlow() {
    const slow = this.audioTarget.playbackRate === 1
    this.audioTarget.playbackRate = slow ? 0.75 : 1
    this.toggleTarget.setAttribute("aria-pressed", slow)
  }
}
