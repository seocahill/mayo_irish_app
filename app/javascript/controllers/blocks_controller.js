import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["list"]
  static values = { reorderUrl: String }

  connect() {
    this.sortable = Sortable.create(this.listTarget, {
      handle: "[data-blocks-handle]",
      animation: 150,
      ghostClass: "opacity-40",
      onEnd: () => this.#save()
    })
  }

  disconnect() {
    this.sortable?.destroy()
  }

  #save() {
    const ids = [...this.listTarget.children].map(el => el.id.replace("lesson_block_", ""))

    fetch(this.reorderUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
      },
      body: JSON.stringify({ order: ids })
    })
  }
}
