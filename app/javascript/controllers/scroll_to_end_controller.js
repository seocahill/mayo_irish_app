import { Controller } from "@hotwired/stimulus"

// Shows the newest messages when the chat loads, including after a Turbo
// visit, where DOMContentLoaded doesn't fire again.
export default class extends Controller {
  connect() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
