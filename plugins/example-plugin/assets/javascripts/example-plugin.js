// Example Plugin JavaScript
(function() {
  'use strict';

  // Initialize plugin functionality
  function initializeExamplePlugin() {
    console.log('[ExamplePlugin] Initializing...');
    
    // Add any client-side functionality here
    setupPluginWidgets();
    setupEventListeners();
  }

  function setupPluginWidgets() {
    // Find and initialize plugin widgets
    const widgets = document.querySelectorAll('.example-plugin-widget');
    widgets.forEach(widget => {
      console.log('[ExamplePlugin] Found widget:', widget);
      // Add widget-specific functionality here
    });
  }

  function setupEventListeners() {
    // Listen for custom events
    document.addEventListener('example-plugin:refresh', function(e) {
      console.log('[ExamplePlugin] Refresh event received:', e.detail);
      refreshPluginData();
    });
  }

  function refreshPluginData() {
    // Refresh plugin data via API
    fetch('/api/example-plugin/stats')
      .then(response => response.json())
      .then(data => {
        updateWidgetStats(data);
      })
      .catch(error => {
        console.error('[ExamplePlugin] Error refreshing data:', error);
      });
  }

  function updateWidgetStats(data) {
    // Update widget statistics
    Object.keys(data).forEach(key => {
      const element = document.querySelector(`[data-stat="${key}"]`);
      if (element) {
        element.textContent = data[key];
      }
    });
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeExamplePlugin);
  } else {
    initializeExamplePlugin();
  }

  // Expose global API for other scripts
  window.ExamplePlugin = {
    refresh: refreshPluginData,
    initialize: initializeExamplePlugin
  };
})();
