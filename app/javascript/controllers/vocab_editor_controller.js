import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tbody"]

  addRow() {
    const template = document.getElementById("vocab-row-template")
    const index = Date.now()
    const html = template.innerHTML.replaceAll("NEW_INDEX", index)

    const row = document.createElement("tbody")
    row.innerHTML = html
    const tr = row.firstElementChild

    this.tbodyTarget.appendChild(tr)
    // Focus the first input in the new row
    tr.querySelector("input")?.focus()
  }

  removeRow(event) {
    const row = event.target.closest("tr")
    const destroyFlag = row.querySelector(".destroy-flag")

    if (destroyFlag) {
      // Existing record: mark for destruction
      destroyFlag.value = "1"
      row.style.display = "none"
    } else {
      // New record: just remove the DOM node
      row.remove()
    }
  }
}
