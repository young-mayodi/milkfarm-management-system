import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["results"]
  
  connect() {
    this.originalContent = document.getElementById('cow-search-results').innerHTML
    this.timeout = null
  }

  search(event) {
    const query = event.target.value.toLowerCase().trim()
    
    // Clear any existing timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    
    if (query === '') {
      // Show original content when search is empty
      document.getElementById('cow-search-results').innerHTML = this.originalContent
      return
    }

    // Add loading state
    document.getElementById('cow-search-results').innerHTML = `
      <div class="text-center py-3">
        <div class="spinner-border spinner-border-sm text-primary" role="status">
          <span class="visually-hidden">Loading...</span>
        </div>
        <p class="text-muted mt-2 small">Searching cows...</p>
      </div>
    `

    // Debounce the search to avoid too many requests
    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      const response = await fetch(`/cows/search?q=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (!response.ok) {
        throw new Error('Search failed')
      }
      
      const data = await response.json()
      this.displayResults(data.cows, query)
    } catch (error) {
      console.error('Search error:', error)
      this.displayError()
    }
  }

  displayResults(cows, query) {
    const resultsContainer = document.getElementById('cow-search-results')
    
    if (cows.length === 0) {
      resultsContainer.innerHTML = `
        <div class="text-center py-3">
          <i class="bi bi-search text-muted" style="font-size: 2rem;"></i>
          <p class="text-muted mt-2 small">No cows found matching "${query}"</p>
          <a href="/cows" class="btn btn-outline-primary btn-sm">View All Cows</a>
        </div>
      `
      return
    }

    const cowsHtml = cows.map(cow => `
      <a href="${cow.url}" class="text-decoration-none" data-turbo="false">
        <div class="cow-item d-flex justify-content-between align-items-center mb-2 p-2 rounded cow-search-item">
          <div>
            <div class="fw-semibold text-dark">${cow.name}</div>
            <small class="text-muted">Tag: ${cow.tag_number}</small>
          </div>
          <div class="text-end">
            <span class="badge bg-info">
              ${cow.avg_production}L avg
            </span>
          </div>
        </div>
      </a>
    `).join('')

    resultsContainer.innerHTML = cowsHtml
  }

  displayError() {
    document.getElementById('cow-search-results').innerHTML = `
      <div class="text-center py-3">
        <i class="bi bi-exclamation-triangle text-warning" style="font-size: 2rem;"></i>
        <p class="text-muted mt-2 small">Search error occurred</p>
        <button class="btn btn-outline-secondary btn-sm" onclick="location.reload()">Try Again</button>
      </div>
    `
  }
}
