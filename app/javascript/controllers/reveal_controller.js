import { Controller } from "@hotwired/stimulus"

// Hides the answer on a "Say it" card until the learner taps Show.
export default class extends Controller {
  static targets = ["hidden", "button"]

  show() {
    this.hiddenTargets.forEach((el) => (el.hidden = false))
    this.buttonTarget.hidden = true
  }
}
