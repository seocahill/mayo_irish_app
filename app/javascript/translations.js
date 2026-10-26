// Looks up the strings the server renders into the page (the `js` keys in
// config/locales), so scripts never hold user-facing text of their own.
let cache = null

function translations() {
  if (cache) return cache
  try {
    cache = JSON.parse(document.getElementById("js-translations")?.textContent || "{}")
  } catch (_) {
    cache = {}
  }
  return cache
}

export function t(key) {
  return key.split(".").reduce((node, part) => node?.[part], translations()) ?? key
}
