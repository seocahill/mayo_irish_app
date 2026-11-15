import { Controller } from "@hotwired/stimulus"

// Offers "Add to Home screen" on Today after the learner's third distinct day
// of use. Stays hidden once dismissed or installed. All state is in this
// browser's localStorage; nothing is sent to the server.
//
// The browser fires beforeinstallprompt once per page load, usually before this
// controller connects, so application.js stores it on window.deferredInstallPrompt
// and announces it with an "install-prompt-ready" event.
const DAYS_KEY = "install-days"
const DISMISSED_KEY = "install-dismissed"
const DAYS_NEEDED = 3

export default class extends Controller {
  static targets = ["android", "ios"]

  connect() {
    this.onReady = () => this.evaluate()
    this.onInstalled = () => this.dismiss()
    window.addEventListener("install-prompt-ready", this.onReady)
    window.addEventListener("appinstalled", this.onInstalled)

    if (!this.finished) this.recordDay()
    this.evaluate()
  }

  disconnect() {
    window.removeEventListener("install-prompt-ready", this.onReady)
    window.removeEventListener("appinstalled", this.onInstalled)
  }

  async install() {
    const prompt = window.deferredInstallPrompt
    if (!prompt) return
    window.deferredInstallPrompt = null
    try {
      prompt.prompt()
      await prompt.userChoice
    } catch { /* the browser declined to show it */ }
    this.dismiss()
  }

  dismiss() {
    this.write(DISMISSED_KEY, "1")
    this.evaluate()
    document.querySelector("main, h1")?.focus?.()
  }

  // One place decides what shows, so a card restored from Turbo's cache is
  // always put right.
  evaluate() {
    const ready = !this.finished && this.days.length >= DAYS_NEEDED
    const android = ready && !this.isIosSafari && !!window.deferredInstallPrompt
    const ios = ready && this.isIosSafari
    this.androidTarget.hidden = !android
    this.iosTarget.hidden = !ios
    this.element.hidden = !(android || ios)
  }

  recordDay() {
    const now = new Date()
    const today = [ now.getFullYear(), now.getMonth() + 1, now.getDate() ].join("-")
    const days = this.days
    if (!days.includes(today)) this.write(DAYS_KEY, JSON.stringify([ ...days, today ].slice(-30)))
  }

  get finished() {
    return this.installed || this.read(DISMISSED_KEY) === "1"
  }

  get days() {
    try {
      const days = JSON.parse(this.read(DAYS_KEY) || "[]")
      return Array.isArray(days) ? days : []
    } catch {
      return []
    }
  }

  get installed() {
    return window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true
  }

  // Only Safari can "Add to Home Screen" on iOS; Chrome, Firefox and in-app
  // browsers can't, so they get no card.
  get isIosSafari() {
    const ua = navigator.userAgent
    const ios = /iphone|ipad|ipod/i.test(ua) ||
      (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
    return ios && /safari/i.test(ua) && !/crios|fxios|edgios|gsa|instagram|fban|fbav/i.test(ua)
  }

  read(key) {
    try { return localStorage.getItem(key) } catch { return null }
  }

  write(key, value) {
    try { localStorage.setItem(key, value) } catch { /* private mode: card just won't remember */ }
  }
}
