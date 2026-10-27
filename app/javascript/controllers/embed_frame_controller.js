import { Controller } from "@hotwired/stimulus"

// Fits an embedded Abairt page to its content: the page posts its height.
export default class extends Controller {
  static values = { origin: String }

  connect() {
    this.resize = this.resize.bind(this)
    window.addEventListener("message", this.resize)
  }

  disconnect() {
    window.removeEventListener("message", this.resize)
  }

  resize({ origin, source, data }) {
    if (origin !== this.originValue || source !== this.element.contentWindow) return
    if (data?.abairt !== "height") return

    this.element.style.height = `${Math.ceil(data.height)}px`
  }
}
