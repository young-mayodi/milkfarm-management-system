import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["refreshButton", "lastUpdated"]
  static values = { 
    autoRefresh: Boolean,
    interval: Number 
  }

  connect() {
    console.log('Dashboard controller connected')
    
    if (this.autoRefreshValue) {
      this.startAutoRefresh()
    }
    
    this.updateLastRefresh()
  }

  disconnect() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }

  refresh() {
    this.updateRefreshButton(true)
    
    // Simulate data refresh (in a real app, this would fetch new data)
    setTimeout(() => {
      this.updateRefreshButton(false)
      this.updateLastRefresh()
      
      // Trigger a page refresh for now (could be AJAX in future)
      window.location.reload()
    }, 1000)
  }

  toggleAutoRefresh() {
    this.autoRefreshValue = !this.autoRefreshValue
    
    if (this.autoRefreshValue) {
      this.startAutoRefresh()
    } else {
      this.stopAutoRefresh()
    }
  }

  startAutoRefresh() {
    const interval = (this.intervalValue || 30) * 1000 // Convert to milliseconds
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

  updateRefreshButton(loading) {
    if (this.hasRefreshButtonTarget) {
      const button = this.refreshButtonTarget
      if (loading) {
        button.disabled = true
        button.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Refreshing...'
      } else {
        button.disabled = false
        button.innerHTML = '<i class="bi bi-arrow-clockwise me-2"></i>Refresh Data'
      }
    }
  }

  updateLastRefresh() {
    if (this.hasLastUpdatedTarget) {
      const now = new Date()
      this.lastUpdatedTarget.textContent = `Last updated: ${now.toLocaleTimeString()}`
    }
  }
}
