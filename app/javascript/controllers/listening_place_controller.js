import { Controller } from "@hotwired/stimulus"

// Remembers where the learner stopped in a whole recording, on this device
// only (localStorage), and offers to carry on from there next time. Nothing is
// sent to the server. On the sign-in page (forget value set) it forgets every
// saved place instead, the same rule the offline lessons follow.
const PREFIX = "listening-place:"
// Too near the start or the end to be worth offering.
const MARGIN = 15
const SAVE_EVERY = 5
const KEEP_DAYS = 60

export default class extends Controller {
  static targets = ["audio", "carryOn"]
  static values = { key: String, offer: Boolean, label: String, forget: Boolean }

  connect() {
    if (this.forgetValue) return this.forget()
    if (!this.hasAudioTarget || !this.keyValue) return

    // Start from nothing: a page restored from Turbo's cache may still show an old offer.
    this.savedAt = null
    this.hideOffer()
    const place = this.offerValue ? this.read() : null
    if (place) this.offer(place)

    this.flush = () => this.save()
    window.addEventListener("pagehide", this.flush)
  }

  disconnect() {
    if (!this.flush) return
    window.removeEventListener("pagehide", this.flush)
    this.save()
    this.flush = null
  }

  // Forget every saved place on this device, so the next person to sign in here never sees them.
  forget() {
    try {
      Object.keys(localStorage).filter((key) => key.startsWith(PREFIX)).forEach((key) => localStorage.removeItem(key))
    } catch { /* storage blocked: nothing was saved either */ }
  }

  carryOn() {
    const place = this.place
    if (!place) return
    this.hideOffer()

    const audio = this.audioTarget
    const go = () => {
      audio.currentTime = place
      // Lets the transcript drop Repeat line, as a lock-screen skip does.
      this.dispatch("skipped", { detail: { time: place } })
      audio.play().catch(() => {})
    }
    // Seeking before the audio knows its length is unreliable (iOS loads nothing until asked).
    if (audio.readyState >= 1) return go()
    audio.addEventListener("loadedmetadata", go, { once: true })
    audio.load()
  }

  // While playing, every few seconds. Seeks while paused (such as opening the
  // recording at a clip's phrase) don't count, so they never lose the place.
  track() {
    if (this.audioTarget.paused) return
    const now = this.audioTarget.currentTime
    if (this.place && now >= this.place - SAVE_EVERY) this.hideOffer()
    if (this.savedAt !== null && Math.abs(now - this.savedAt) < SAVE_EVERY) return
    this.save()
  }

  // Near the start nothing is saved and nothing is lost: hearing the opening
  // again leaves an earlier place alone. Near the end the place is let go.
  save() {
    if (!this.hasAudioTarget || !this.audioTarget.played.length) return
    const now = this.audioTarget.currentTime
    const duration = this.audioTarget.duration
    if (Number.isFinite(duration) && now > duration - MARGIN) return this.clear()
    if (now < MARGIN) return

    this.savedAt = now
    this.write({ t: Math.floor(now), at: Date.now() })
  }

  clear() {
    this.savedAt = null
    try { localStorage.removeItem(this.storageKey) } catch { /* nothing to clear */ }
  }

  offer(seconds) {
    this.place = seconds
    if (!this.hasCarryOnTarget) return
    this.carryOnTarget.textContent = this.labelValue.replace("__TIME__", this.format(seconds))
    this.carryOnTarget.hidden = false
  }

  hideOffer() {
    this.place = null
    if (this.hasCarryOnTarget) this.carryOnTarget.hidden = true
  }

  read() {
    try {
      const place = JSON.parse(localStorage.getItem(this.storageKey))
      if (!place || !Number.isFinite(place.t) || !Number.isFinite(place.at) || place.t < MARGIN) return null
      if (Date.now() - place.at > KEEP_DAYS * 86400000) return this.clear()
      return place.t
    } catch {
      return null
    }
  }

  write(place) {
    try { localStorage.setItem(this.storageKey, JSON.stringify(place)) } catch { /* private mode: just won't remember */ }
  }

  format(seconds) {
    const s = Math.floor(seconds)
    const h = Math.floor(s / 3600)
    const m = Math.floor((s % 3600) / 60)
    const rest = String(s % 60).padStart(2, "0")
    return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${rest}` : `${m}:${rest}`
  }

  get storageKey() { return PREFIX + this.keyValue }
}
