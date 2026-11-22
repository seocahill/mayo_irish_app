import { Controller } from "@hotwired/stimulus"

// Tells the service worker this lesson was opened, so it keeps a copy for
// when the connection drops. Needed because Turbo often shows a lesson from a
// prefetch, which the worker does not keep. Sends only the lesson's path.
export default class extends Controller {
  static values = { path: String }

  connect() {
    const worker = navigator.serviceWorker?.controller
    if (worker && navigator.onLine && this.pathValue) {
      worker.postMessage({ type: "lesson-opened", path: this.pathValue })
    }
  }
}
