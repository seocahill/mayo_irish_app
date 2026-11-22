import { Controller } from "@hotwired/stimulus"

// Shows a quiet bar while the device has no connection, so a learner knows
// they are looking at a lesson saved on this device and why recordings and
// practice don't work. Hides again when the connection comes back.
export default class extends Controller {
  connect() {
    this.update = () => { this.element.hidden = navigator.onLine }
    window.addEventListener("online", this.update)
    window.addEventListener("offline", this.update)
    this.update()
  }

  disconnect() {
    window.removeEventListener("online", this.update)
    window.removeEventListener("offline", this.update)
  }
}
