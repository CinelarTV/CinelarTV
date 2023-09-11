<template>
    <div class="chart-canvas-container">
      <canvas ref="chartCanvas"></canvas>
    </div>
  </template>
  
  <script>
  import { ref, watch } from 'vue';
  import { Chart } from 'chart.js';
  
  export default {
    props: {
      chartData: Object,
      chartOptions: Object,
      chartType: {
        type: String,
        default: 'bar',
        enum: ['bar', 'line'],
      }
    },
    setup(props) {
      const chartCanvas = ref(null);
      let chartInstance = null;
  
      // Observa cambios en los datos del gráfico
      watch(() => props.chartData, (newData) => {
        if (chartInstance) {
          chartInstance.data = newData;
          chartInstance.update();
        }
      });
  
      // Inicializa el gráfico cuando se monta el componente
      const initializeChart = () => {
        if (chartCanvas.value) {
          const ctx = chartCanvas.value.getContext('2d');
          chartInstance = new Chart(ctx, {
            type: props.chartType || 'bar',
            data: props.chartData,
            options: props.chartOptions,
          });
        }
      };
  
      return {
        chartCanvas,
        initializeChart,
      };
    },
    mounted() {
      this.initializeChart();
    },
  };
  </script>