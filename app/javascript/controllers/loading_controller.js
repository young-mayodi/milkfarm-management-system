import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="loading"
export default class extends Controller {
  static targets = ["spinner", "content"]
  static values = {
    delay: { type: Number, default: 200 }
  }

  connect() {
    // Show loading spinner for long-running operations
    document.addEventListener("turbo:submit-start", this.showLoading.bind(this))
    document.addEventListener("turbo:submit-end", this.hideLoading.bind(this))
    
    // Also handle regular turbo frame requests
    document.addEventListener("turbo:before-fetch-request", this.showLoading.bind(this))
    document.addEventListener("turbo:before-fetch-response", this.hideLoading.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:submit-start", this.showLoading.bind(this))
    document.removeEventListener("turbo:submit-end", this.hideLoading.bind(this))
    document.removeEventListener("turbo:before-fetch-request", this.showLoading.bind(this))
    document.removeEventListener("turbo:before-fetch-response", this.hideLoading.bind(this))
  }

  showLoading(event) {
    // Only show with delay to avoid flash for fast requests
    this.timeout = setTimeout(() => {
      if (this.hasSpinnerTarget) {
        this.spinnerTarget.classList.remove("d-none")
      }
      if (this.hasContentTarget) {
        this.contentTarget.style.opacity = "0.5"
      }
    }, this.delayValue)
  }

  hideLoading(event) {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add("d-none")
    }
    if (this.hasContentTarget) {
      this.contentTarget.style.opacity = "1"
    }
  }

  // Manual trigger methods
  show() {
    this.showLoading()
  }

  hide() {
    this.hideLoading()
  }
}
