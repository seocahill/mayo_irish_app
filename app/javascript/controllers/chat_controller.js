import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  submitOnEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }

  submit(event) {
    const input = this.inputTarget
    if (!input.value.trim()) {
      event.preventDefault()
    }
  }
}
