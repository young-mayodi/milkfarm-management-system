import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-validation"
export default class extends Controller {
  static targets = ["submit"]

  connect() {
    this.element.addEventListener("submit", this.handleSubmit.bind(this))
    this.validateOnInput()
  }

  validateOnInput() {
    const inputs = this.element.querySelectorAll("input[required], select[required], textarea[required]")
    inputs.forEach(input => {
      input.addEventListener("blur", (e) => this.validateField(e.target))
      input.addEventListener("input", (e) => this.clearError(e.target))
    })
  }

  validateField(field) {
    if (!field.validity.valid) {
      this.showError(field, field.validationMessage)
      return false
    }
    return true
  }

  showError(field, message) {
    // Remove existing error
    this.clearError(field)

    // Add invalid class
    field.classList.add("is-invalid")

    // Create error message element
    const errorDiv = document.createElement("div")
    errorDiv.className = "invalid-feedback"
    errorDiv.textContent = message
    errorDiv.dataset.validationError = "true"

    // Insert after field
    field.parentNode.insertBefore(errorDiv, field.nextSibling)
  }

  clearError(field) {
    field.classList.remove("is-invalid")
    const error = field.parentNode.querySelector("[data-validation-error]")
    if (error) {
      error.remove()
    }
  }

  handleSubmit(event) {
    let isValid = true
    const requiredFields = this.element.querySelectorAll("input[required], select[required], textarea[required]")
    
    requiredFields.forEach(field => {
      if (!this.validateField(field)) {
        isValid = false
      }
    })

    if (!isValid) {
      event.preventDefault()
      event.stopPropagation()
      
      // Scroll to first error
      const firstError = this.element.querySelector(".is-invalid")
      if (firstError) {
        firstError.scrollIntoView({ behavior: "smooth", block: "center" })
        firstError.focus()
      }
      
      return false
    }

    // Show loading state
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
      const originalText = this.submitTarget.textContent
      this.submitTarget.innerHTML = `
        <span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
        Saving...
      `
      
      // Store original text to restore on error
      this.submitTarget.dataset.originalText = originalText
    }
  }
}
