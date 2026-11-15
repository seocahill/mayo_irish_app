import { Controller } from "@hotwired/stimulus"

// Offers "Add to Home screen" on Today after the learner's third distinct day
// of use. Stays hidden once dismissed or installed. All state is in this
// browser's localStorage; nothing is sent to the server.
const DAYS_KEY = "install-days"
const DISMISSED_KEY = "install-dismissed"
const DAYS_NEEDED = 3

export default class extends Controller {
  static targets = ["android", "ios"]

  connect() {
    this.deferredPrompt = null
    this.onPrompt = (event) => {
      event.preventDefault()
      this.deferredPrompt = event
      this.reveal()
    }
    this.onInstalled = () => this.dismiss()
    window.addEventListener("beforeinstallprompt", this.onPrompt)
    window.addEventListener("appinstalled", this.onInstalled)

    if (this.installed || this.read(DISMISSED_KEY)) return
    this.recordDay()
    if (this.isIos) this.reveal()
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this.onPrompt)
    window.removeEventListener("appinstalled", this.onInstalled)
  }

  async install() {
    if (!this.deferredPrompt) return
    this.deferredPrompt.prompt()
    await this.deferredPrompt.userChoice
    this.deferredPrompt = null
    this.dismiss()
  }

  dismiss() {
    this.write(DISMISSED_KEY, "1")
    this.element.hidden = true
  }

  reveal() {
    if (this.read(DISMISSED_KEY) || this.installed || this.days.length < DAYS_NEEDED) return
    this.element.hidden = false
    if (this.isIos) {
      this.iosTarget.hidden = false
    } else if (this.deferredPrompt) {
      this.androidTarget.hidden = false
    } else {
      this.element.hidden = true
    }
  }

  recordDay() {
    const today = new Date().toISOString().slice(0, 10)
    const days = this.days
    if (!days.includes(today)) this.write(DAYS_KEY, JSON.stringify([...days, today].slice(-30)))
  }

  get days() {
    try {
      return JSON.parse(this.read(DAYS_KEY) || "[]")
    } catch {
      return []
    }
  }

  get installed() {
    return window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true
  }

  get isIos() {
    return /iphone|ipad|ipod/i.test(navigator.userAgent) && !window.MSStream
  }

  read(key) {
    try { return localStorage.getItem(key) } catch { return null }
  }

  write(key, value) {
    try { localStorage.setItem(key, value) } catch { /* private mode: card just won't remember */ }
  }
}
