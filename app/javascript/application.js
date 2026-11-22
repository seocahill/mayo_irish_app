// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "playback_speed"

import "trix"
import "@rails/actiontext"
import "lexxy"

// Lets the app show an offline page and load its shell without a connection.
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker").catch(() => {})
}

// Keep Chrome's install prompt for the card on Today (it fires once per load).
window.addEventListener("beforeinstallprompt", (event) => {
  event.preventDefault()
  window.deferredInstallPrompt = event
  window.dispatchEvent(new Event("install-prompt-ready"))
})
