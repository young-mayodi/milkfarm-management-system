import { Controller } from "@hotwired/stimulus"

// Connect this controller to the DOM
export default class extends Controller {
  static values = { 
    type: String,
    data: Object,
    options: Object 
  }
  
  connect() {
    console.log("Chart controller connected")
    console.log("Chart available:", typeof Chart !== 'undefined')
    this.initializeChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  initializeChart() {
    try {
      // Wait for Chart.js to be available
      if (typeof Chart === 'undefined') {
        console.error("Chart.js not loaded yet, retrying...")
        setTimeout(() => this.initializeChart(), 100)
        return
      }

      const ctx = this.element
      
      // Default options for all charts
      const defaultOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              usePointStyle: true,
              padding: 20,
              font: {
                size: 12
              }
            }
          },
          tooltip: {
            backgroundColor: 'rgba(0, 0, 0, 0.8)',
            titleColor: 'white',
            bodyColor: 'white',
            borderColor: 'rgba(255, 255, 255, 0.1)',
            borderWidth: 1,
            cornerRadius: 6,
            displayColors: true
          }
        },
        animation: {
          duration: 1000,
          easing: 'easeOutQuart'
        }
      }

      // Merge with custom options
      const options = { 
        ...defaultOptions, 
        ...this.optionsValue 
      }

      // Add specific options for line charts
      if (this.typeValue === 'line') {
        options.scales = {
          y: {
            beginAtZero: true,
            grid: {
              color: 'rgba(0, 0, 0, 0.1)'
            },
            ticks: {
              font: {
                size: 11
              }
            }
          },
          x: {
            grid: {
              color: 'rgba(0, 0, 0, 0.1)'
            },
            ticks: {
              font: {
                size: 11
              }
            }
          }
        }
      }

      console.log("Creating chart with data:", this.dataValue)
      console.log("Chart type:", this.typeValue)

      this.chart = new Chart(ctx, {
        type: this.typeValue,
        data: this.dataValue,
        options: options
      })

      console.log("Chart created successfully")
    } catch (error) {
      console.error("Error creating chart:", error)
      console.error("Chart data:", this.dataValue)
      console.error("Chart type:", this.typeValue)
      
      // Show error message in the chart container
      this.element.parentElement.innerHTML = `
        <div class="d-flex align-items-center justify-content-center h-100 text-muted">
          <div class="text-center">
            <i class="bi bi-exclamation-triangle fs-1 mb-3"></i>
            <p>Chart could not be loaded</p>
            <small>Check console for details</small>
          </div>
        </div>
      `
    }
  }
}