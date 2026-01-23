import { Controller } from "@hotwired/stimulus"

// Simple test controller to verify Stimulus is working
export default class extends Controller {
  connect() {
    console.log("Test controller connected successfully!")
    this.element.style.backgroundColor = "yellow"
    this.element.textContent = "Stimulus test controller connected!"
  }

  click() {
    console.log("Test controller clicked!")
    this.element.style.backgroundColor = this.element.style.backgroundColor === "yellow" ? "green" : "yellow"
  }
}
