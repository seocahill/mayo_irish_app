import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "handle"]

  // Drag-to-reorder can be wired up here later (e.g. with SortableJS).
  // For now, blocks are reordered by destroying and recreating in the desired position.
}
