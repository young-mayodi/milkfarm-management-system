// Enhanced Animal Management Table JavaScript
class CowsTableManager {
  constructor() {
    this.selectedCows = new Set();
    this.init();
  }
  
  init() {
    this.setupEventListeners();
    this.setupKeyboardShortcuts();
    this.setupBulkActions();
    this.initializeDataTable();
  }
  
  setupEventListeners() {
    // Checkbox selection
    document.addEventListener('change', (e) => {
      if (e.target.classList.contains('cow-checkbox')) {
        this.handleCowSelection(e.target);
      }
    });
    
    // Select all checkbox
    const selectAllCheckbox = document.getElementById('selectAllCheckbox');
    if (selectAllCheckbox) {
      selectAllCheckbox.addEventListener('change', (e) => {
        this.toggleSelectAll(e.target.checked);
      });
    }
    
    // Row click to select
    document.addEventListener('click', (e) => {
      const cowRow = e.target.closest('.cow-row');
      if (cowRow && !e.target.closest('.btn, .dropdown, a')) {
        const checkbox = cowRow.querySelector('.cow-checkbox');
        if (checkbox) {
          checkbox.checked = !checkbox.checked;
          this.handleCowSelection(checkbox);
        }
      }
    });
  }
  
  setupKeyboardShortcuts() {
    document.addEventListener('keydown', (e) => {
      // Ctrl+A to select all
      if (e.ctrlKey && e.key === 'a') {
        e.preventDefault();
        this.selectAll();
      }
      
      // Escape to clear selection
      if (e.key === 'Escape') {
        this.clearSelection();
      }
      
      // Delete key for bulk delete
      if (e.key === 'Delete' && this.selectedCows.size > 0) {
        e.preventDefault();
        this.bulkAction('delete');
      }
    });
  }
  
  handleCowSelection(checkbox) {
    const cowId = parseInt(checkbox.value);
    const row = checkbox.closest('.cow-row');
    
    if (checkbox.checked) {
      this.selectedCows.add(cowId);
      row.classList.add('selected');
    } else {
      this.selectedCows.delete(cowId);
      row.classList.remove('selected');
    }
    
    this.updateSelectionUI();
  }
  
  updateSelectionUI() {
    const selectedCount = this.selectedCows.size;
    const selectAllCheckbox = document.getElementById('selectAllCheckbox');
    const totalRows = document.querySelectorAll('.cow-checkbox').length;
    
    // Update select all checkbox state
    if (selectAllCheckbox) {
      if (selectedCount === 0) {
        selectAllCheckbox.indeterminate = false;
        selectAllCheckbox.checked = false;
      } else if (selectedCount === totalRows) {
        selectAllCheckbox.indeterminate = false;
        selectAllCheckbox.checked = true;
      } else {
        selectAllCheckbox.indeterminate = true;
      }
    }
    
    // Update bulk action buttons
    const bulkActions = document.querySelectorAll('[data-bulk-action]');
    bulkActions.forEach(btn => {
      btn.disabled = selectedCount === 0;
    });
    
    // Show selection count
    this.updateSelectionCount(selectedCount);
  }
  
  updateSelectionCount(count) {
    let countElement = document.getElementById('selection-count');
    if (!countElement) {
      countElement = document.createElement('div');
      countElement.id = 'selection-count';
      countElement.className = 'alert alert-info alert-dismissible fade show position-fixed';
      countElement.style.cssText = 'bottom: 20px; right: 20px; z-index: 1050; min-width: 250px;';
      document.body.appendChild(countElement);
    }
    
    if (count > 0) {
      countElement.innerHTML = `
        <i class="bi bi-check2-square me-2"></i>
        <strong>${count}</strong> animal${count > 1 ? 's' : ''} selected
        <button type="button" class="btn-close" onclick="cowsTable.clearSelection()"></button>
      `;
      countElement.classList.add('show');
    } else {
      countElement.classList.remove('show');
    }
  }
  
  toggleSelectAll(checked) {
    const checkboxes = document.querySelectorAll('.cow-checkbox');
    checkboxes.forEach(checkbox => {
      checkbox.checked = checked;
      this.handleCowSelection(checkbox);
    });
  }
  
  selectAll() {
    this.toggleSelectAll(true);
  }
  
  clearSelection() {
    this.toggleSelectAll(false);
  }
  
  setupBulkActions() {
    // Bulk action buttons
    document.addEventListener('click', (e) => {
      if (e.target.hasAttribute('data-bulk-action')) {
        const action = e.target.getAttribute('data-bulk-action');
        this.bulkAction(action);
      }
    });
  }
  
  async bulkAction(action) {
    if (this.selectedCows.size === 0) {
      this.showToast('No animals selected', 'warning');
      return;
    }
    
    const selectedIds = Array.from(this.selectedCows);
    const count = selectedIds.length;
    
    let confirmation = false;
    let endpoint = '';
    let method = 'POST';
    let successMessage = '';
    
    switch (action) {
      case 'activate':
        confirmation = confirm(`Activate ${count} selected animal${count > 1 ? 's' : ''}?`);
        endpoint = '/cows/bulk_update';
        successMessage = `${count} animal${count > 1 ? 's' : ''} activated successfully`;
        break;
        
      case 'deactivate':
        confirmation = confirm(`Deactivate ${count} selected animal${count > 1 ? 's' : ''}?`);
        endpoint = '/cows/bulk_update';
        successMessage = `${count} animal${count > 1 ? 's' : ''} deactivated successfully`;
        break;
        
      case 'delete':
        confirmation = confirm(`Are you sure you want to delete ${count} selected animal${count > 1 ? 's' : ''}?\n\nThis action cannot be undone.`);
        endpoint = '/cows/bulk_delete';
        method = 'DELETE';
        successMessage = `${count} animal${count > 1 ? 's' : ''} deleted successfully`;
        break;
        
      default:
        return;
    }
    
    if (!confirmation) return;
    
    try {
      this.showLoading(true);
      
      const response = await fetch(endpoint, {
        method: method,
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          action: action,
          cow_ids: selectedIds
        })
      });
      
      if (response.ok) {
        this.showToast(successMessage, 'success');
        this.reloadTable();
        this.clearSelection();
      } else {
        const error = await response.text();
        this.showToast(`Error: ${error}`, 'danger');
      }
    } catch (error) {
      this.showToast('Network error occurred', 'danger');
      console.error('Bulk action error:', error);
    } finally {
      this.showLoading(false);
    }
  }
  
  reloadTable() {
    // Reload the current page to refresh the table
    window.location.reload();
  }
  
  showLoading(show) {
    const table = document.getElementById('cowsTable');
    if (show) {
      table.classList.add('table-loading');
    } else {
      table.classList.remove('table-loading');
    }
  }
  
  showToast(message, type = 'info') {
    // Create toast notification
    const toastContainer = this.getOrCreateToastContainer();
    const toastId = 'toast-' + Date.now();
    
    const toast = document.createElement('div');
    toast.id = toastId;
    toast.className = `toast align-items-center text-white bg-${type} border-0`;
    toast.innerHTML = `
      <div class="d-flex">
        <div class="toast-body">
          <i class="bi bi-${this.getToastIcon(type)} me-2"></i>
          ${message}
        </div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
      </div>
    `;
    
    toastContainer.appendChild(toast);
    
    // Initialize and show toast
    const bsToast = new bootstrap.Toast(toast);
    bsToast.show();
    
    // Auto-remove after hiding
    toast.addEventListener('hidden.bs.toast', () => {
      toast.remove();
    });
  }
  
  getToastIcon(type) {
    const icons = {
      success: 'check-circle-fill',
      danger: 'exclamation-triangle-fill',
      warning: 'exclamation-circle-fill',
      info: 'info-circle-fill'
    };
    return icons[type] || icons.info;
  }
  
  getOrCreateToastContainer() {
    let container = document.getElementById('toast-container');
    if (!container) {
      container = document.createElement('div');
      container.id = 'toast-container';
      container.className = 'toast-container position-fixed bottom-0 end-0 p-3';
      container.style.zIndex = '1055';
      document.body.appendChild(container);
    }
    return container;
  }
  
  initializeDataTable() {
    // Add any additional table initialization here
    this.setupTableSearch();
    this.setupInfiniteScroll();
  }
  
  setupTableSearch() {
    const searchInput = document.querySelector('input[name="search"]');
    if (searchInput) {
      let searchTimeout;
      searchInput.addEventListener('input', (e) => {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(() => {
          // Auto-submit search after 500ms delay
          if (e.target.value.length >= 3 || e.target.value.length === 0) {
            e.target.form.submit();
          }
        }, 500);
      });
    }
  }
  
  setupInfiniteScroll() {
    // Placeholder for infinite scroll implementation
    // This would require additional backend support
  }
}

// Global functions for onclick handlers
function selectAll() {
  if (window.cowsTable) {
    window.cowsTable.selectAll();
  }
}

function clearSelection() {
  if (window.cowsTable) {
    window.cowsTable.clearSelection();
  }
}

function bulkAction(action) {
  if (window.cowsTable) {
    window.cowsTable.bulkAction(action);
  }
}

function addHealthRecord(cowId) {
  // Placeholder for health record functionality
  console.log('Add health record for cow:', cowId);
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  if (document.getElementById('cowsTable')) {
    window.cowsTable = new CowsTableManager();
  }
});
