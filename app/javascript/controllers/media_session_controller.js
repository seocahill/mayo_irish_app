import { Controller } from "@hotwired/stimulus"

// Puts a recording on the phone's lock screen and headphone buttons: its title
// and speakers, ten seconds back and forward, and the previous and next line
// of the transcript. Browsers without Media Session just keep the audio controls.
const SKIP = 10
// Pressing previous more than this far into a line starts that line again;
// sooner than that, it goes to the line before (as music apps do).
const RESTART_AFTER = 2
const EVENTS = ["loadedmetadata", "durationchange", "ratechange", "seeked", "play", "pause"]
const ACTIONS = ["play", "pause", "seekbackward", "seekforward", "seekto", "previoustrack", "nexttrack"]

export default class extends Controller {
  static targets = ["audio", "line"]
  static values = { title: String, artist: String, album: String, artwork: String }

  connect() {
    if (!("mediaSession" in navigator) || typeof MediaMetadata === "undefined") return

    this.session = navigator.mediaSession
    // Kept, so disconnect can still reach it once the page has gone.
    this.audio = this.audioTarget
    this.session.metadata = new MediaMetadata({
      title: this.titleValue, artist: this.artistValue, album: this.albumValue,
      artwork: this.artworkValue ? [ { src: this.artworkValue, sizes: "512x512", type: "image/png" } ] : []
    })
    const lines = this.hasLineTarget
    this.handle({
      play: () => this.audio.play().catch(() => {}),
      pause: () => this.audio.pause(),
      seekbackward: (details) => this.seekTo(this.audio.currentTime - (details.seekOffset || SKIP)),
      seekforward: (details) => this.seekTo(this.audio.currentTime + (details.seekOffset || SKIP)),
      seekto: (details) => this.seekTo(details.seekTime),
      previoustrack: lines ? () => this.previousLine() : null,
      nexttrack: lines ? () => this.nextLine() : null
    })

    this.sync = () => this.update()
    for (const event of EVENTS) {
      this.audio.addEventListener(event, this.sync)
    }
  }

  disconnect() {
    if (!this.session) return

    for (const event of EVENTS) {
      this.audio.removeEventListener(event, this.sync)
    }
    this.handle(Object.fromEntries(ACTIONS.map((action) => [ action, null ])))
    this.session.metadata = null
    this.session.playbackState = "none"
  }

  // A browser that doesn't know an action throws; the others still work.
  handle(handlers) {
    for (const [ action, handler ] of Object.entries(handlers)) {
      try { this.session.setActionHandler(action, handler) } catch { /* unsupported action */ }
    }
  }

  // Tells the transcript, so Repeat line lets go when a skip leaves that line.
  seekTo(time) {
    const duration = Number.isFinite(this.audio.duration) ? this.audio.duration : Infinity
    this.audio.currentTime = Math.min(Math.max(time, 0), duration)
    this.dispatch("skipped", { detail: { time: this.audio.currentTime } })
  }

  // Lines are buttons that play from their start (and keep Repeat on that line),
  // so stepping between them is the same as tapping one.
  previousLine() {
    const now = this.audio.currentTime
    const index = this.lineTargets.findLastIndex((line) => Number(line.dataset.start) <= now)
    if (index === -1) return this.seekTo(0)

    const restart = now - Number(this.lineTargets[index].dataset.start) > RESTART_AFTER
    this.lineTargets[restart ? index : Math.max(index - 1, 0)].click()
  }

  nextLine() {
    const now = this.audio.currentTime
    this.lineTargets.find((line) => Number(line.dataset.start) > now + 0.25)?.click()
  }

  update() {
    this.session.playbackState = this.audio.paused ? "paused" : "playing"
    const { duration, playbackRate, currentTime } = this.audio
    if (!Number.isFinite(duration) || duration <= 0) return

    try {
      this.session.setPositionState({ duration, playbackRate, position: Math.min(currentTime, duration) })
    } catch { /* position state not supported */ }
  }
}
