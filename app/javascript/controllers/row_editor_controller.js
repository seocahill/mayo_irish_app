import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tbody"]
  static values = { section: String }

  addRow() {
    const templateId = `row-template-${this.sectionValue}`
    const template = document.getElementById(templateId)
    if (!template) return

    const index = Date.now()
    const html = template.innerHTML.replaceAll("NEW_INDEX", index)

    const wrapper = document.createElement("tbody")
    wrapper.innerHTML = html
    const tr = wrapper.firstElementChild

    this.tbodyTarget.appendChild(tr)
    tr.querySelector("input,textarea")?.focus()
  }

  removeRow(event) {
    const row = event.target.closest("tr")
    const destroyFlag = row.querySelector(".destroy-flag")

    if (destroyFlag) {
      destroyFlag.value = "1"
      row.style.display = "none"
    } else {
      row.remove()
    }
  }
}
