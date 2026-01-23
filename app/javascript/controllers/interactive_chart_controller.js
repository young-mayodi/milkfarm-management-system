import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chart"]
  static values = { 
    refreshUrl: String,
    autoRefresh: Boolean,
    refreshInterval: Number 
  }

  connect() {
    console.log('Interactive chart controller connected')
    
    if (this.autoRefreshValue) {
      this.startAutoRefresh()
    }
  }

  disconnect() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }

  refresh() {
    if (!this.refreshUrlValue) return
    
    fetch(this.refreshUrlValue)
      .then(response => response.json())
      .then(data => {
        this.updateCharts(data)
      })
      .catch(error => {
        console.error('Chart refresh failed:', error)
      })
  }

  startAutoRefresh() {
    const interval = this.refreshIntervalValue || 30000 // 30 seconds default
    this.refreshTimer = setInterval(() => {
      this.refresh()
    }, interval)
  }

  stopAutoRefresh() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
      this.refreshTimer = null
    }
  }

  updateCharts(data) {
    // Update existing charts with new data
    this.chartTargets.forEach(chartElement => {
      const chartController = this.application.getControllerForElementAndIdentifier(
        chartElement, 
        'chart'
      )
      
      if (chartController && chartController.chart) {
        // Update chart data
        chartController.chart.data = data.chartData
        chartController.chart.update('active')
      }
    })
  }
}
