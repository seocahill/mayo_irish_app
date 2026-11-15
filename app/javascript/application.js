// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "trix"
import "@rails/actiontext"
import "lexxy"

// Lets the app show an offline page and load its shell without a connection.
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker").catch(() => {})
}
