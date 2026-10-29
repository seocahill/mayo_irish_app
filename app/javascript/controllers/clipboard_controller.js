import { Controller } from "@hotwired/stimulus"

// Copies a field's text, so an admin can paste an invitation link to someone.
export default class extends Controller {
  static targets = ["source", "button"]
  static values = { copied: String }

  async copy() {
    this.sourceTarget.select()
    await navigator.clipboard.writeText(this.sourceTarget.value)
    this.buttonTarget.textContent = this.copiedValue
  }
}
