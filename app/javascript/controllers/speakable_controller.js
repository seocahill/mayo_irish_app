import { Controller } from "@hotwired/stimulus"
import { t } from "translations"

// Lets the learner hear any Irish on a lesson page in the synthetic voice. The
// Irish the server marked in the lesson's rich text (data-speak, see
// SpeakableIrish) gets a speaker button, and selecting any text shows a "Hear
// it" button below it. Both are pronounce controllers pointed at the speech
// endpoint.
const MAX_CHARACTERS = 400

export default class extends Controller {
  static targets = ["content", "inline", "selection"]
  static values = { src: String }

  connect() {
    this.onSelectionChange = () => this.selectionChanged()
    document.addEventListener("selectionchange", this.onSelectionChange)
  }

  disconnect() {
    document.removeEventListener("selectionchange", this.onSelectionChange)
    clearTimeout(this.hideTimer)
  }

  contentTargetConnected(element) {
    element.querySelectorAll("[data-speak]").forEach((irish) => {
      // Turbo restores the page with the buttons already in it.
      if (irish.dataset.speakable) return
      irish.dataset.speakable = "true"

      const button = this.inlineTarget.content.firstElementChild.cloneNode(true)
      button.dataset.pronounceSrcValue = this.urlFor(irish.dataset.speak)
      button.querySelector("button").setAttribute("aria-label", `${t("js.speakable.hear")}: ${irish.dataset.speak}`)
      irish.matches("td") ? irish.append(" ", button) : irish.after(" ", button)
    })
  }

  // Desktop browsers clear the selection on mousedown, before the click.
  keepSelection(event) {
    event.preventDefault()
  }

  selectionChanged() {
    clearTimeout(this.hideTimer)
    const selection = document.getSelection()
    const text = selection.isCollapsed ? "" : speakableText(selection.toString())

    if (text && this.element.contains(selection.anchorNode) && this.element.contains(selection.focusNode)) {
      this.showSelectionButton(text, selection.getRangeAt(0).getBoundingClientRect())
    } else {
      // A tap on the button can clear the selection before the tap lands, so wait a moment.
      this.hideTimer = setTimeout(() => (this.selectionTarget.hidden = true), 300)
    }
  }

  // Below the selection, clear of the phone's selection handles.
  showSelectionButton(text, rect) {
    const box = this.element.getBoundingClientRect()
    const button = this.selectionTarget
    button.dataset.pronounceSrcValue = this.urlFor(text)
    button.hidden = false
    button.style.top = `${rect.bottom - box.top + 28}px`
    button.style.left = `${Math.max(0, Math.min(rect.left - box.left, box.width - button.offsetWidth))}px`
  }

  urlFor(text) {
    const url = new URL(this.srcValue, window.location.href)
    url.searchParams.set("text", text)
    return `${url.pathname}${url.search}`
  }
}

// The selected text to read: without phonetics or the course's section
// references, such as "(§589)", and only if there's something to read and not
// too much of it.
function speakableText(text) {
  const cleaned = text
    .replace(/\/[^/]*\//g, " ")
    .replace(/\([^)]*§[^)]*\)/g, " ")
    .replace(/§\s*[\d.]+/g, " ")
    .replace(/\s+/g, " ")
    .trim()
  return /\p{L}/u.test(cleaned) && cleaned.length <= MAX_CHARACTERS ? cleaned : null
}
