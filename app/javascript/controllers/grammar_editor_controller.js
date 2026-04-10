import { Controller } from "@hotwired/stimulus"

// Accordion section editor for grammar content.
//
// The grammar field stores text in the format:
//   1. SECTION TITLE
//   body text...
//   (i) subsection
//   more body...
//
//   2. NEXT SECTION
//   ...
//
// This controller splits the text into numbered sections and presents each as
// a collapsible panel. A "raw edit" toggle falls back to the plain textarea.
// On form submit the sections are joined back into the flat text format.

export default class extends Controller {
  static targets = ["source", "editor", "rawWrapper"]

  connect() {
    this._submitHandler = () => this.collectSections()
    this.element.closest("form")?.addEventListener("submit", this._submitHandler)
    if (this.sourceTarget.value.trim()) {
      this.buildEditor()
    }
  }

  disconnect() {
    this.element.closest("form")?.removeEventListener("submit", this._submitHandler)
  }

  // ── Build / Destroy editor ─────────────────────────────────

  buildEditor() {
    const sections = this.parseSections(this.sourceTarget.value)
    this.editorTarget.innerHTML = sections.map((s, i) => this.sectionHTML(s, i)).join("")
    this.rawWrapperTarget.classList.add("hidden")
    this.editorTarget.classList.remove("hidden")
  }

  // ── Section parsing ────────────────────────────────────────

  parseSections(text) {
    const SECTION_RE = /^(\d+)\.\s+(.+)$/
    const sections = []
    let current = null

    for (const line of text.split("\n")) {
      const m = line.match(SECTION_RE)
      if (m) {
        if (current) sections.push(current)
        current = { number: m[1], title: m[2], lines: [] }
      } else if (current) {
        current.lines.push(line)
      }
      // Lines before the first section are discarded (they shouldn't exist)
    }
    if (current) sections.push(current)

    return sections.map(s => ({
      number: s.number,
      title:  s.title,
      body:   s.lines.join("\n").replace(/^\n+|\n+$/g, "")
    }))
  }

  // ── HTML generation ────────────────────────────────────────

  sectionHTML(section, index) {
    const num   = this.esc(section.number)
    const title = this.esc(section.title)
    const body  = this.esc(section.body)

    return `
<div class="grammar-editor-section" data-section-index="${index}">
  <div class="grammar-editor-header"
       data-action="click->grammar-editor#toggleSection">
    <span class="grammar-editor-badge">${num}</span>
    <input type="text" value="${title}"
           class="flex-1 bg-transparent border-0 focus:outline-none font-semibold text-stone-700 text-sm min-w-0"
           data-section-title
           placeholder="Teideal na míre"
           onclick="event.stopPropagation()">
    <svg class="grammar-editor-chevron w-4 h-4" fill="none"
         stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
            d="M19 9l-7 7-7-7"/>
    </svg>
  </div>
  <div class="grammar-editor-body">
    <textarea class="editor-textarea text-xs font-mono leading-relaxed" rows="6"
              data-section-body
              placeholder="Ábhar gramadaí na míre…">${body}</textarea>
    <button type="button"
            class="text-xs text-red-400 hover:text-red-600 transition-colors"
            data-action="click->grammar-editor#removeSection">
      Scrios an mhír seo
    </button>
  </div>
</div>`.trim()
  }

  // ── Actions ────────────────────────────────────────────────

  toggleSection(event) {
    // Don't collapse when the user clicks into the title input
    if (event.target.tagName === "INPUT") return
    event.currentTarget.closest(".grammar-editor-section")
         .classList.toggle("collapsed")
  }

  addSection() {
    const badges  = this.editorTarget.querySelectorAll(".grammar-editor-badge")
    const nums    = Array.from(badges).map(b => parseInt(b.textContent) || 0)
    const nextNum = (Math.max(...nums, 0) + 1).toString()

    const div = document.createElement("div")
    div.innerHTML = this.sectionHTML({ number: nextNum, title: "", body: "" }, Date.now())
    const section = div.firstElementChild
    this.editorTarget.appendChild(section)
    section.querySelector("[data-section-title]")?.focus()
  }

  removeSection(event) {
    if (!confirm("Scrios an mhír gramadaí seo?")) return
    event.target.closest(".grammar-editor-section").remove()
  }

  // Toggle between accordion view and raw textarea
  toggleRaw() {
    const isRaw = !this.rawWrapperTarget.classList.contains("hidden")
    if (isRaw) {
      // Switch back to accordion
      this.buildEditor()
    } else {
      // Sync accordion → textarea, then show textarea
      this.collectSections()
      this.rawWrapperTarget.classList.remove("hidden")
      this.editorTarget.classList.add("hidden")
    }
  }

  // ── Form submit ────────────────────────────────────────────

  // Called on form submit (before the request goes out).
  // Merges all section panels back into the flat grammar text.
  collectSections() {
    // If raw mode is active the textarea already has the right value
    if (!this.rawWrapperTarget.classList.contains("hidden")) return

    const lines = []
    this.editorTarget.querySelectorAll(".grammar-editor-section").forEach(section => {
      const num   = section.querySelector(".grammar-editor-badge")?.textContent?.trim()
      const title = section.querySelector("[data-section-title]")?.value?.trim()
      const body  = section.querySelector("[data-section-body]")?.value?.trim()

      if (num && title) lines.push(`${num}. ${title}`)
      if (body)         lines.push(body)
      lines.push("")   // blank line between sections
    })

    this.sourceTarget.value = lines.join("\n").replace(/\n{3,}/g, "\n\n").trim()
  }

  // ── Helpers ────────────────────────────────────────────────

  esc(str) {
    if (!str) return ""
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
