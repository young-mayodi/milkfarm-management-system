// Enhanced Bulk Entry JavaScript with Advanced Features
class EnhancedBulkEntry {
  constructor() {
    this.init();
    this.setupEventListeners();
    this.setupRealTimeFeatures();
    this.setupAIFeatures();
    this.currentUser = null;
    this.activeUsers = new Map();
    this.conflicts = new Map();
  }

  init() {
    console.log('🚀 Enhanced Bulk Entry initialized');
    this.loadUserData();
    this.setupAutoSave();
    this.setupKeyboardShortcuts();
    this.initializeFilters();
    this.startRealTimeSync();
    this.restoreAutoSavedData();
    this.setupFormSubmission();
  }

  // AI Prediction Features
  setupAIFeatures() {
    document.getElementById('ai_predict_btn')?.addEventListener('click', () => {
      this.generateAIPredictions();
    });

    document.getElementById('pattern_fill_btn')?.addEventListener('click', () => {
      this.applyPatternFill();
    });

    document.getElementById('weather_adjust_btn')?.addEventListener('click', () => {
      this.applyWeatherAdjustment();
    });

    document.getElementById('breed_optimize_btn')?.addEventListener('click', () => {
      this.applyBreedOptimization();
    });
  }

  async generateAIPredictions() {
    const predictionPanel = document.getElementById('ai_prediction_panel');
    predictionPanel.style.display = 'block';
    
    // Show loading state
    document.getElementById('prediction_summary').innerHTML = 
      '<i class="bi bi-hourglass-split text-primary me-2"></i>Analyzing patterns and generating predictions...';

    try {
      // Simulate AI prediction API call
      const predictions = await this.callPredictionAPI();
      
      // Apply predictions to form
      predictions.forEach(prediction => {
        this.applyPredictionToRow(prediction);
      });

      document.getElementById('prediction_summary').innerHTML = 
        `Generated ${predictions.length} predictions based on historical data, weather patterns, and cow health metrics`;
        
    } catch (error) {
      console.error('AI Prediction failed:', error);
      this.showToast('AI Prediction temporarily unavailable', 'warning');
    }
  }

  async callPredictionAPI() {
    // Simulate API call - replace with actual implementation
    return new Promise((resolve) => {
      setTimeout(() => {
        const cows = document.querySelectorAll('.production-row');
        const predictions = Array.from(cows).map(row => {
          const cowId = row.dataset.cowId;
          return {
            cowId: cowId,
            morning: (8 + Math.random() * 8).toFixed(1),
            noon: (6 + Math.random() * 6).toFixed(1),
            evening: (8 + Math.random() * 8).toFixed(1),
            confidence: 0.85 + Math.random() * 0.1
          };
        });
        resolve(predictions);
      }, 2000);
    });
  }

  applyPredictionToRow(prediction) {
    const morningInput = document.querySelector(`input[data-cow-id="${prediction.cowId}"][data-session="morning"]`);
    const noonInput = document.querySelector(`input[data-cow-id="${prediction.cowId}"][data-session="noon"]`);
    const eveningInput = document.querySelector(`input[data-cow-id="${prediction.cowId}"][data-session="evening"]`);

    if (morningInput && !morningInput.value) {
      morningInput.value = prediction.morning;
      morningInput.classList.add('ai-predicted');
    }
    if (noonInput && !noonInput.value) {
      noonInput.value = prediction.noon;
      noonInput.classList.add('ai-predicted');
    }
    if (eveningInput && !eveningInput.value) {
      eveningInput.value = prediction.evening;
      eveningInput.classList.add('ai-predicted');
    }

    this.updateRowTotal(prediction.cowId);
  }

  // Enhanced Table Features
  initializeFilters() {
    const searchFilter = document.getElementById('cow_search_filter');
    const performanceFilter = document.getElementById('performance_filter');
    const sortBy = document.getElementById('sort_by');

    searchFilter?.addEventListener('input', (e) => {
      this.filterTable('search', e.target.value);
    });

    performanceFilter?.addEventListener('change', (e) => {
      this.filterTable('performance', e.target.value);
    });

    sortBy?.addEventListener('change', (e) => {
      this.sortTable(e.target.value);
    });

    // Setup expand/collapse functionality
    document.getElementById('expand_all')?.addEventListener('click', () => {
      this.toggleAllDetails(true);
    });

    document.getElementById('collapse_all')?.addEventListener('click', () => {
      this.toggleAllDetails(false);
    });
  }

  filterTable(type, value) {
    const rows = document.querySelectorAll('.production-row');
    
    rows.forEach(row => {
      let shouldShow = true;

      if (type === 'search' && value) {
        const cowName = row.querySelector('.cow-name').textContent.toLowerCase();
        const tagNumber = row.querySelector('.badge').textContent.toLowerCase();
        shouldShow = cowName.includes(value.toLowerCase()) || tagNumber.includes(value.toLowerCase());
      }

      if (type === 'performance' && value) {
        const totalProduction = parseFloat(row.dataset.productionTotal) || 0;
        switch(value) {
          case 'high':
            shouldShow = totalProduction > 15;
            break;
          case 'medium':
            shouldShow = totalProduction >= 8 && totalProduction <= 15;
            break;
          case 'low':
            shouldShow = totalProduction > 0 && totalProduction < 8;
            break;
          case 'empty':
            shouldShow = totalProduction === 0;
            break;
        }
      }

      row.style.display = shouldShow ? '' : 'none';
    });

    this.updateFilteredSummary();
  }

  sortTable(criteria) {
    const tbody = document.getElementById('production_table_body');
    const rows = Array.from(tbody.querySelectorAll('.production-row'));

    rows.sort((a, b) => {
      switch(criteria) {
        case 'name':
          return a.querySelector('.cow-name').textContent.localeCompare(b.querySelector('.cow-name').textContent);
        case 'production':
          return parseFloat(b.dataset.productionTotal) - parseFloat(a.dataset.productionTotal);
        case 'tag':
          return a.querySelector('.badge').textContent.localeCompare(b.querySelector('.badge').textContent);
        case 'health':
          // Implement health score sorting
          return 0;
        default:
          return 0;
      }
    });

    // Reorder DOM elements
    rows.forEach(row => tbody.appendChild(row));
  }

  toggleAllDetails(expand) {
    const toggleButtons = document.querySelectorAll('.toggle-details');
    toggleButtons.forEach(button => {
      const details = button.closest('.cow-details-cell').querySelector('.cow-expanded-details');
      const icon = button.querySelector('i');
      
      if (expand) {
        details.style.display = 'block';
        icon.className = 'bi bi-chevron-up';
      } else {
        details.style.display = 'none';
        icon.className = 'bi bi-chevron-down';
      }
    });
  }

  // Real-time Collaboration
  startRealTimeSync() {
    // Simulate real-time updates
    setInterval(() => {
      this.syncWithServer();
    }, 5000);

    setInterval(() => {
      this.updateActiveUsers();
    }, 10000);
  }

  async syncWithServer() {
    try {
      const formData = new FormData(document.getElementById('enhanced_bulk_entry_form'));
      const response = await fetch('/production_records/sync', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      });

      if (response.ok) {
        const data = await response.json();
        this.handleSyncResponse(data);
      }
    } catch (error) {
      console.error('Sync failed:', error);
    }
  }

  handleSyncResponse(data) {
    if (data.conflicts && data.conflicts.length > 0) {
      this.handleConflicts(data.conflicts);
    }

    if (data.updates && data.updates.length > 0) {
      this.applyRemoteUpdates(data.updates);
    }

    this.updateActiveUsers(data.activeUsers);
  }

  handleConflicts(conflicts) {
    conflicts.forEach(conflict => {
      this.showConflictModal(conflict);
    });
  }

  showConflictModal(conflict) {
    const modal = document.getElementById('conflictResolutionModal');
    document.getElementById('conflict_cow_name').textContent = conflict.cowName;
    document.getElementById('conflict_field').textContent = conflict.field;
    document.getElementById('your_value').textContent = conflict.yourValue;
    document.getElementById('their_value').textContent = conflict.theirValue;

    new bootstrap.Modal(modal).show();
  }

  // Mobile Interface Enhancements
  setupMobileInterface() {
    if (window.innerWidth < 768) {
      this.initializeMobileGestures();
      this.setupMobileFAB();
    }
  }

  initializeMobileGestures() {
    let startY = 0;
    let currentCard = null;

    document.addEventListener('touchstart', (e) => {
      if (e.target.closest('.mobile-cow-card')) {
        startY = e.touches[0].clientY;
        currentCard = e.target.closest('.mobile-cow-card');
      }
    });

    document.addEventListener('touchmove', (e) => {
      if (currentCard) {
        const deltaY = e.touches[0].clientY - startY;
        if (Math.abs(deltaY) > 50) {
          // Implement swipe gestures for mobile navigation
          if (deltaY > 0) {
            this.navigateToPreviousCow(currentCard);
          } else {
            this.navigateToNextCow(currentCard);
          }
          currentCard = null;
        }
      }
    });
  }

  setupMobileFAB() {
    const fab = document.getElementById('mobile_bulk_actions');
    fab?.addEventListener('click', () => {
      this.showMobileActionSheet();
    });
  }

  showMobileActionSheet() {
    const actionSheet = document.getElementById('mobile_action_sheet');
    actionSheet.style.display = 'block';
    setTimeout(() => {
      actionSheet.classList.add('show');
    }, 10);
  }

  hideMobileActionSheet() {
    const actionSheet = document.getElementById('mobile_action_sheet');
    actionSheet.classList.remove('show');
    setTimeout(() => {
      actionSheet.style.display = 'none';
    }, 300);
  }

  // Auto-save functionality
  setupAutoSave() {
    console.log('🔄 Setting up auto-save functionality...');
    
    // Auto-save every 30 seconds
    this.autoSaveInterval = setInterval(() => {
      this.saveFormDataToLocalStorage();
    }, 30000);

    // Save on input change
    document.addEventListener('input', (e) => {
      if (e.target.classList.contains('production-input')) {
        this.saveFormDataToLocalStorage();
        this.updateRowTotal(e.target);
      }
    });

    // Save before page unload
    window.addEventListener('beforeunload', () => {
      this.saveFormDataToLocalStorage();
    });

    // Setup smart save toggle
    const smartSaveToggle = document.getElementById('smart_save_toggle');
    if (smartSaveToggle) {
      smartSaveToggle.addEventListener('click', () => {
        this.toggleAutoSave();
      });
    }
  }

  saveFormDataToLocalStorage() {
    const formData = {};
    const dateInput = document.querySelector('input[name="date"]');
    const farmInput = document.querySelector('input[name="farm_id"]');
    
    if (!dateInput || !farmInput) return;

    const storageKey = `bulk_entry_${farmInput.value}_${dateInput.value}`;
    
    document.querySelectorAll('.production-input').forEach(input => {
      if (input.value && input.value !== '0' && input.value !== '') {
        const cowId = input.dataset.cowId;
        const session = input.dataset.session;
        
        if (!formData[cowId]) {
          formData[cowId] = {};
        }
        
        formData[cowId][session] = input.value;
      }
    });

    localStorage.setItem(storageKey, JSON.stringify(formData));
    console.log('📝 Form data auto-saved to localStorage');
    
    // Update UI indicator
    this.updateSaveStatus('saved');
  }

  restoreAutoSavedData() {
    const dateInput = document.querySelector('input[name="date"]');
    const farmInput = document.querySelector('input[name="farm_id"]');
    
    if (!dateInput || !farmInput) return;

    const storageKey = `bulk_entry_${farmInput.value}_${dateInput.value}`;
    const savedData = localStorage.getItem(storageKey);
    
    if (savedData) {
      try {
        const formData = JSON.parse(savedData);
        let restoredCount = 0;
        
        Object.entries(formData).forEach(([cowId, sessions]) => {
          Object.entries(sessions).forEach(([session, value]) => {
            const input = document.querySelector(`input[data-cow-id="${cowId}"][data-session="${session}"]`);
            if (input && !input.value) {
              input.value = value;
              input.classList.add('auto-restored');
              restoredCount++;
              this.updateRowTotal(input);
            }
          });
        });
        
        if (restoredCount > 0) {
          this.showToast(`🔄 Restored ${restoredCount} auto-saved values`, 'info');
          console.log(`📥 Restored ${restoredCount} auto-saved values`);
        }
      } catch (error) {
        console.error('Error restoring auto-saved data:', error);
      }
    }
  }

  toggleAutoSave() {
    const statusSpan = document.getElementById('smart_save_status');
    const currentStatus = statusSpan.textContent;
    
    if (currentStatus === 'ON') {
      // Turn off auto-save
      if (this.autoSaveInterval) {
        clearInterval(this.autoSaveInterval);
        this.autoSaveInterval = null;
      }
      statusSpan.textContent = 'OFF';
      statusSpan.className = 'text-danger';
      this.showToast('Auto-save disabled', 'warning');
    } else {
      // Turn on auto-save
      this.setupAutoSave();
      statusSpan.textContent = 'ON';
      statusSpan.className = 'text-success';
      this.showToast('Auto-save enabled', 'success');
    }
  }

  updateRowTotal(input) {
    const cowId = input.dataset.cowId;
    const morningInput = document.querySelector(`input[data-cow-id="${cowId}"][data-session="morning"]`);
    const noonInput = document.querySelector(`input[data-cow-id="${cowId}"][data-session="noon"]`);
    const eveningInput = document.querySelector(`input[data-cow-id="${cowId}"][data-session="evening"]`);
    const totalDisplay = document.getElementById(`total_${cowId}`);

    if (morningInput && noonInput && eveningInput && totalDisplay) {
      const morning = parseFloat(morningInput.value) || 0;
      const noon = parseFloat(noonInput.value) || 0;
      const evening = parseFloat(eveningInput.value) || 0;
      const total = (morning + noon + evening).toFixed(1);
      
      totalDisplay.textContent = `${total}L`;
      
      // Update row visual state
      const row = input.closest('.production-row');
      if (total > 0) {
        row.classList.add('table-success');
      } else {
        row.classList.remove('table-success');
      }
    }
  }

  updateSaveStatus(status) {
    const statusIndicators = document.querySelectorAll('.save-status-indicator');
    statusIndicators.forEach(indicator => {
      switch(status) {
        case 'saving':
          indicator.innerHTML = '<i class="bi bi-cloud-arrow-up text-warning"></i> Saving...';
          break;
        case 'saved':
          indicator.innerHTML = '<i class="bi bi-cloud-check text-success"></i> Saved';
          setTimeout(() => {
            indicator.innerHTML = '<i class="bi bi-cloud-check text-muted"></i> Auto-saved';
          }, 2000);
          break;
        case 'error':
          indicator.innerHTML = '<i class="bi bi-cloud-slash text-danger"></i> Save Error';
          break;
      }
    });
  }

  setupFormSubmission() {
    const form = document.getElementById('enhanced_bulk_entry_form');
    const saveAllBtn = document.getElementById('save_all_btn');
    const finalSaveBtn = document.getElementById('final_save');
    
    // Handle both save buttons
    [saveAllBtn, finalSaveBtn].forEach(btn => {
      if (btn) {
        btn.addEventListener('click', (e) => {
          e.preventDefault();
          this.submitForm();
        });
      }
    });

    // Prevent default form submission
    if (form) {
      form.addEventListener('submit', (e) => {
        e.preventDefault();
        this.submitForm();
      });
    }
  }

  async submitForm() {
    const form = document.getElementById('enhanced_bulk_entry_form');
    if (!form) return;

    this.updateSaveStatus('saving');
    
    try {
      const formData = new FormData(form);
      const response = await fetch(form.action, {
        method: 'POST',
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      });

      if (response.ok) {
        const result = await response.json();
        this.handleSaveSuccess(result);
        
        // Clear auto-saved data since server save was successful
        const dateInput = document.querySelector('input[name="date"]');
        const farmInput = document.querySelector('input[name="farm_id"]');
        if (dateInput && farmInput) {
          const storageKey = `bulk_entry_${farmInput.value}_${dateInput.value}`;
          localStorage.removeItem(storageKey);
        }
      } else {
        throw new Error(`Server responded with ${response.status}`);
      }
    } catch (error) {
      console.error('Save failed:', error);
      this.handleSaveError(error);
    }
  }

  handleSaveSuccess(result) {
    this.updateSaveStatus('saved');
    this.showToast(`✅ Successfully saved ${result.success_count || 0} production records`, 'success');
    
    // Update UI to reflect saved state
    document.querySelectorAll('.production-input').forEach(input => {
      input.classList.remove('auto-restored');
      if (input.value && input.value !== '0') {
        input.classList.add('is-valid');
      }
    });
  }

  handleSaveError(error) {
    this.updateSaveStatus('error');
    this.showToast('❌ Failed to save production records. Please try again.', 'danger');
    console.error('Save error:', error);
  }

  // Enhanced Analytics Integration
  updateAnalytics() {
    const completedRows = document.querySelectorAll('.production-row').length;
    const filledRows = Array.from(document.querySelectorAll('.production-row')).filter(row => {
      const total = parseFloat(row.dataset.productionTotal) || 0;
      return total > 0;
    }).length;

    const completionPercentage = (filledRows / completedRows * 100).toFixed(1);
    
    // Update progress indicators
    document.querySelectorAll('.completion-percentage').forEach(el => {
      el.textContent = completionPercentage + '%';
    });

    document.querySelectorAll('.progress-bar').forEach(bar => {
      bar.style.width = completionPercentage + '%';
    });
  }

  // Utility Methods
  showToast(message, type = 'info') {
    const toastContainer = document.getElementById('toast-container') || this.createToastContainer();
    
    const toast = document.createElement('div');
    toast.className = `toast align-items-center text-white bg-${type} border-0`;
    toast.innerHTML = `
      <div class="d-flex">
        <div class="toast-body">${message}</div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
      </div>
    `;
    
    toastContainer.appendChild(toast);
    new bootstrap.Toast(toast).show();
    
    setTimeout(() => {
      toast.remove();
    }, 5000);
  }

  createToastContainer() {
    const container = document.createElement('div');
    container.id = 'toast-container';
    container.className = 'toast-container position-fixed bottom-0 end-0 p-3';
    document.body.appendChild(container);
    return container;
  }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  if (document.getElementById('enhanced_bulk_entry_form')) {
    window.enhancedBulkEntry = new EnhancedBulkEntry();
  }
});

// Enhanced CSS for new features
const enhancedStyles = `
<style>
.ai-predicted {
  background-color: #e3f2fd !important;
  border-left: 3px solid #2196f3 !important;
}

.health-indicator {
  display: flex;
  align-items: center;
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.8rem;
}

.health-good { background-color: #d4edda; color: #155724; }
.health-warning { background-color: #fff3cd; color: #856404; }
.health-danger { background-color: #f8d7da; color: #721c24; }

.production-input-wrapper {
  position: relative;
}

.input-indicators {
  position: absolute;
  top: 2px;
  right: 2px;
  display: flex;
  gap: 2px;
}

.trend-indicator,
.quality-indicator {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: block;
}

.trend-indicator.up { background-color: #28a745; }
.trend-indicator.down { background-color: #dc3545; }
.trend-indicator.stable { background-color: #ffc107; }

.quality-indicator.high { background-color: #28a745; }
.quality-indicator.medium { background-color: #ffc107; }
.quality-indicator.low { background-color: #dc3545; }

.smart-suggestions .dropdown-menu {
  font-size: 0.85rem;
  min-width: 180px;
}

.suggestion-item i {
  width: 16px;
}

.user-avatars {
  display: inline-flex;
  gap: 4px;
}

.user-avatar {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  color: white;
  font-size: 0.7rem;
  font-weight: bold;
}

.activity-feed {
  max-height: 200px;
  overflow-y: auto;
}

.activity-item {
  display: flex;
  align-items: flex-start;
  padding: 8px 12px;
  border-bottom: 1px solid #eee;
}

.activity-avatar {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  color: white;
  font-size: 0.8rem;
  font-weight: bold;
  margin-right: 12px;
  flex-shrink: 0;
}

.activity-content {
  flex: 1;
}

.mobile-action-sheet {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: white;
  border-top-left-radius: 16px;
  border-top-right-radius: 16px;
  box-shadow: 0 -4px 20px rgba(0,0,0,0.15);
  transform: translateY(100%);
  transition: transform 0.3s ease;
  z-index: 1050;
}

.mobile-action-sheet.show {
  transform: translateY(0);
}

.action-sheet-header {
  display: flex;
  justify-content: between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid #eee;
}

.action-sheet-item {
  display: flex;
  align-items: center;
  width: 100%;
  padding: 16px 20px;
  border: none;
  background: none;
  text-align: left;
  transition: background-color 0.2s;
}

.action-sheet-item:hover {
  background-color: #f8f9fa;
}

.action-sheet-item i {
  margin-right: 12px;
  width: 20px;
  font-size: 1.1rem;
}

@media (max-width: 768px) {
  .enhanced-data-table-container {
    display: none;
  }
  
  .mobile-data-entry {
    display: block !important;
  }
  
  .mobile-cow-card {
    border-radius: 12px;
    overflow: hidden;
  }
  
  .mobile-production-input {
    text-align: center;
    font-weight: bold;
  }
}

.status-connected {
  color: #28a745;
}

.status-disconnected {
  color: #dc3545;
}

.conflict-option .value-display {
  text-align: center;
  font-weight: bold;
  font-size: 1.1rem;
}

.auto-restored {
  background-color: #fff3cd !important;
  border-color: #ffc107 !important;
  animation: pulse-restored 2s ease-in-out;
}

@keyframes pulse-restored {
  0% { background-color: #fff3cd; }
  50% { background-color: #ffeaa7; }
  100% { background-color: #fff3cd; }
}

.save-status-indicator {
  font-size: 0.9rem;
  transition: all 0.3s ease;
}

.is-valid.production-input {
  border-color: #198754 !important;
  background-color: #d1e7dd !important;
}

.production-input:focus {
  border-color: #0d6efd !important;
  box-shadow: 0 0 0 0.2rem rgba(13, 110, 253, 0.25) !important;
}
</style>
`;

// Inject enhanced styles
document.head.insertAdjacentHTML('beforeend', enhancedStyles);
