/**
 * grammar_editor_controller.js
 *
 * Block-based editor for structured grammar data.
 *
 * The hidden #grammar_data field holds a JSON array of sections.
 * This controller renders it as an accordion where each section contains
 * typed blocks: prose, examples (2-col Irish/English), table (N-col), subsection, note.
 *
 * On form submit the UI state is serialised back into the hidden field.
 */
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "container"]

  connect() {
    this._submitHandler = () => this.serialize()
    this.element.closest("form")?.addEventListener("submit", this._submitHandler)
    this.render()
  }

  disconnect() {
    this.element.closest("form")?.removeEventListener("submit", this._submitHandler)
  }

  // ── Top-level render ─────────────────────────────────────────────────────

  render() {
    let data = []
    try { data = JSON.parse(this.sourceTarget.value || "[]") } catch (_) {}
    this.containerTarget.innerHTML = data.map((s, i) => this.sectionHTML(s, i)).join("")
  }

  // ── Section HTML ─────────────────────────────────────────────────────────

  sectionHTML(section, idx) {
    const num    = this.esc(section.number || "")
    const title  = this.esc(section.title  || "")
    const blocks = (section.blocks || []).map((b, bi) => this.blockHTML(b, idx, bi)).join("")

    return `
<div class="ge-section" data-section-idx="${idx}">
  <div class="ge-section-header"
       data-action="click->grammar-editor#toggleSection">
    <span class="ge-section-badge">${num}</span>
    <input type="text" value="${title}"
           class="ge-section-title"
           placeholder="Teideal na rannóige"
           onclick="event.stopPropagation()">
    <button type="button" class="ge-icon-btn ge-danger ml-auto mr-2"
            data-action="click->grammar-editor#removeSection"
            title="Scrios rannóg" onclick="event.stopPropagation()">✕</button>
    <svg class="ge-chevron w-4 h-4 text-stone-400" fill="none"
         stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M19 9l-7 7-7-7"/>
    </svg>
  </div>
  <div class="ge-section-body">
    <div class="ge-blocks" data-section-idx="${idx}">
      ${blocks}
    </div>
    ${this.addBlockMenuHTML(idx)}
  </div>
</div>`
  }

  addBlockMenuHTML(sectionIdx) {
    const types = [
      ["subsection", "Fo-rannóg"],
      ["prose",      "Prós"],
      ["examples",   "Samplaí (2 cholún)"],
      ["table",      "Tábla"],
      ["note",       "Nóta"],
    ]
    const btns = types.map(([t, label]) =>
      `<button type="button" class="ge-add-block-btn"
               data-action="click->grammar-editor#addBlock"
               data-section-idx="${sectionIdx}"
               data-block-type="${t}">${label}</button>`
    ).join("")
    return `<div class="ge-add-block-row">${btns}</div>`
  }

  // ── Block HTML (dispatch by type) ────────────────────────────────────────

  blockHTML(block, sectionIdx, blockIdx) {
    const type = block.type || "prose"
    const inner = {
      subsection: () => this.subsectionBlockHTML(block),
      prose:      () => this.proseBlockHTML(block),
      examples:   () => this.examplesBlockHTML(block),
      table:      () => this.tableBlockHTML(block),
      note:       () => this.noteBlockHTML(block),
    }[type]?.() ?? this.proseBlockHTML(block)

    const label = {
      subsection: "Fo-rannóg", prose: "Prós", examples: "Samplaí",
      table: "Tábla", note: "Nóta",
    }[type] ?? type

    return `
<div class="ge-block" data-block-type="${type}" data-section-idx="${sectionIdx}" data-block-idx="${blockIdx}">
  <div class="ge-block-header">
    <span class="ge-block-label">${label}</span>
    <button type="button" class="ge-icon-btn ge-danger"
            data-action="click->grammar-editor#removeBlock">✕</button>
  </div>
  <div class="ge-block-body">
    ${inner}
  </div>
</div>`
  }

  subsectionBlockHTML(block) {
    return `
<div class="flex gap-2">
  <input type="text" value="${this.esc(block.label||'')}"
         class="ge-input w-20 font-mono" placeholder="(i)" data-field="label">
  <input type="text" value="${this.esc(block.title||'')}"
         class="ge-input flex-1" placeholder="Teideal fo-rannóige" data-field="title">
</div>`
  }

  proseBlockHTML(block) {
    return `<textarea class="ge-textarea" rows="3"
                      data-field="text" placeholder="Téacs próis…">${this.esc(block.text||'')}</textarea>`
  }

  noteBlockHTML(block) {
    return `<textarea class="ge-textarea ge-textarea-note" rows="2"
                      data-field="text" placeholder="Nóta nó fonóta…">${this.esc(block.text||'')}</textarea>`
  }

  examplesBlockHTML(block) {
    const rows = (block.rows || []).map(r => this.exampleRowHTML(r)).join("")
    return `
<table class="ge-edit-table w-full">
  <thead>
    <tr>
      <th class="ge-th">Gaeilge</th>
      <th class="ge-th">Béarla</th>
      <th class="ge-th w-8"></th>
    </tr>
  </thead>
  <tbody data-examples-body>
    ${rows}
  </tbody>
</table>
<button type="button" class="ge-add-row-btn"
        data-action="click->grammar-editor#addExampleRow">+ Sraith</button>`
  }

  exampleRowHTML(row) {
    const irish   = this.esc((row || [])[0] || "")
    const english = this.esc((row || [])[1] || "")
    return `
<tr data-example-row>
  <td><input type="text" value="${irish}"   class="ge-cell-input" data-col="0" placeholder="Gaeilge"></td>
  <td><input type="text" value="${english}" class="ge-cell-input" data-col="1" placeholder="English"></td>
  <td class="text-center">
    <button type="button" class="ge-icon-btn ge-danger"
            data-action="click->grammar-editor#removeRow">✕</button>
  </td>
</tr>`
  }

  tableBlockHTML(block) {
    const headers = block.headers || []
    const rows    = block.rows    || []

    const headerCells = headers.map(h =>
      `<th><input type="text" value="${this.esc(h)}" class="ge-th-input" data-header placeholder="Ceanntásc"></th>`
    ).join("")
    const addHeaderBtn = `<th><button type="button" class="ge-icon-btn"
                                       data-action="click->grammar-editor#addTableColumn">+</button></th>`

    const bodyRows = rows.map(r => this.tableRowHTML(r, headers.length)).join("")

    const note = this.esc(block.note || "")
    const noteField = `<div class="mt-2">
      <input type="text" value="${note}" class="ge-input w-full text-xs"
             data-field="note" placeholder="Nóta tábla (roghnach)">
    </div>`

    return `
<table class="ge-edit-table w-full">
  <thead>
    <tr data-header-row>
      ${headerCells}
      ${addHeaderBtn}
    </tr>
  </thead>
  <tbody data-table-body>
    ${bodyRows}
  </tbody>
</table>
<button type="button" class="ge-add-row-btn"
        data-action="click->grammar-editor#addTableRow">+ Sraith</button>
${noteField}`
  }

  tableRowHTML(row, colCount) {
    const count = Math.max(colCount, (row || []).length, 1)
    const cells = Array.from({ length: count }, (_, i) =>
      `<td><input type="text" value="${this.esc((row||[])[i]||'')}" class="ge-cell-input" data-col="${i}"></td>`
    ).join("")
    return `
<tr data-table-row>
  ${cells}
  <td class="text-center">
    <button type="button" class="ge-icon-btn ge-danger"
            data-action="click->grammar-editor#removeRow">✕</button>
  </td>
</tr>`
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  toggleSection(event) {
    if (event.target.matches("input, button")) return
    event.currentTarget.closest(".ge-section").classList.toggle("collapsed")
  }

  addSection() {
    const sections = this.containerTarget.querySelectorAll(".ge-section")
    const nums = Array.from(sections).map(s => {
      const badge = s.querySelector(".ge-section-badge")
      return parseInt(badge?.textContent) || 0
    })
    const nextNum = (Math.max(...nums, 0) + 1).toString()
    const div = document.createElement("div")
    div.innerHTML = this.sectionHTML({ number: nextNum, title: "", blocks: [] }, Date.now()).trim()
    this.containerTarget.appendChild(div.firstElementChild)
    div.firstElementChild?.querySelector(".ge-section-title")?.focus()
  }

  removeSection(event) {
    if (!confirm("Scrios an rannóg seo?")) return
    event.target.closest(".ge-section")?.remove()
  }

  addBlock(event) {
    const btn         = event.currentTarget
    const type        = btn.dataset.blockType
    const sectionIdx  = btn.dataset.sectionIdx
    const blocksEl    = this.containerTarget.querySelector(`.ge-blocks[data-section-idx="${sectionIdx}"]`)
    if (!blocksEl) return

    const blockIdx = blocksEl.querySelectorAll(".ge-block").length
    const block = this.defaultBlock(type)
    const div = document.createElement("div")
    div.innerHTML = this.blockHTML(block, sectionIdx, blockIdx).trim()
    blocksEl.appendChild(div.firstElementChild)
  }

  defaultBlock(type) {
    const defaults = {
      subsection: { type: "subsection", label: "", title: "" },
      prose:      { type: "prose",      text: "" },
      examples:   { type: "examples",   rows: [["", ""]] },
      table:      { type: "table",      headers: ["", ""], rows: [["", ""]], note: "" },
      note:       { type: "note",       text: "" },
    }
    return defaults[type] ?? { type: "prose", text: "" }
  }

  removeBlock(event) {
    event.target.closest(".ge-block")?.remove()
  }

  addExampleRow(event) {
    const tbody = event.currentTarget.closest(".ge-block-body").querySelector("[data-examples-body]")
    const div = document.createElement("tbody")
    div.innerHTML = this.exampleRowHTML(["", ""])
    tbody.appendChild(div.firstElementChild)
    tbody.lastElementChild?.querySelector("input")?.focus()
  }

  addTableRow(event) {
    const block   = event.currentTarget.closest(".ge-block")
    const tbody   = block.querySelector("[data-table-body]")
    const colCount = block.querySelectorAll("[data-header-row] [data-header]").length
    const div = document.createElement("tbody")
    div.innerHTML = this.tableRowHTML([], colCount)
    tbody.appendChild(div.firstElementChild)
    tbody.lastElementChild?.querySelector("input")?.focus()
  }

  addTableColumn(event) {
    const block = event.currentTarget.closest(".ge-block")
    // Add header cell (before the + button)
    const headerRow = block.querySelector("[data-header-row]")
    const addBtn    = headerRow.lastElementChild
    const newTh = document.createElement("th")
    newTh.innerHTML = `<input type="text" value="" class="ge-th-input" data-header placeholder="Ceanntásc">`
    headerRow.insertBefore(newTh, addBtn)
    // Add cell to each body row
    block.querySelectorAll("[data-table-row]").forEach(tr => {
      const removeBtn = tr.lastElementChild
      const newTd = document.createElement("td")
      const colIdx = tr.querySelectorAll("[data-col]").length
      newTd.innerHTML = `<input type="text" value="" class="ge-cell-input" data-col="${colIdx}">`
      tr.insertBefore(newTd, removeBtn)
    })
  }

  removeRow(event) {
    event.target.closest("tr")?.remove()
  }

  // ── Serialise UI → JSON ──────────────────────────────────────────────────

  serialize() {
    const data = Array.from(this.containerTarget.querySelectorAll(".ge-section"))
      .map(sectionEl => {
        const badge  = sectionEl.querySelector(".ge-section-badge")
        const title  = sectionEl.querySelector(".ge-section-title")
        const blocks = Array.from(sectionEl.querySelectorAll(".ge-block"))
          .map(blockEl => this.serializeBlock(blockEl))
          .filter(Boolean)
        return {
          number: badge?.textContent?.trim() || "",
          title:  title?.value?.trim() || "",
          blocks
        }
      })
    this.sourceTarget.value = JSON.stringify(data)
  }

  serializeBlock(blockEl) {
    const type = blockEl.dataset.blockType
    switch (type) {
      case "subsection":
        return {
          type,
          label: blockEl.querySelector("[data-field='label']")?.value?.trim() || "",
          title: blockEl.querySelector("[data-field='title']")?.value?.trim() || "",
        }
      case "prose":
      case "note":
        return {
          type,
          text: blockEl.querySelector("[data-field='text']")?.value?.trim() || "",
        }
      case "examples": {
        const rows = Array.from(blockEl.querySelectorAll("[data-example-row]")).map(tr => [
          tr.querySelector("[data-col='0']")?.value || "",
          tr.querySelector("[data-col='1']")?.value || "",
        ])
        return { type, rows }
      }
      case "table": {
        const headers = Array.from(blockEl.querySelectorAll("[data-header]"))
          .map(i => i.value?.trim() || "")
        const rows = Array.from(blockEl.querySelectorAll("[data-table-row]")).map(tr =>
          Array.from(tr.querySelectorAll("[data-col]")).map(i => i.value?.trim() || "")
        )
        const note = blockEl.querySelector("[data-field='note']")?.value?.trim() || ""
        return { type, headers, rows, note: note || undefined }
      }
      default:
        return null
    }
  }

  // ── Utility ──────────────────────────────────────────────────────────────

  esc(str) {
    return String(str ?? "")
      .replace(/&/g, "&amp;").replace(/</g, "&lt;")
      .replace(/>/g, "&gt;").replace(/"/g, "&quot;")
  }
}
