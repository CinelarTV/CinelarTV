<template>
  <div class="panel">
    <c-spinner v-if="!dashboardData" />
    <div v-else id="admin-dashboard" class="pt-2">
      <section id="updates-available" class="inline-flex px-4 py-2 w-full bg-emerald-500 text-white mb-8"
        v-if="dashboardData.version_check.updates_available">
        <UploadCloud />
        <span class="text-base px-4">
          Hay actualizaciones disponibles
        </span>
      </section>
      <section id="problems" class="flex flex-col py-2 w-full mb-8" v-if="dashboardData.problems.length > 0">
        <template v-for="problem in dashboardData.problems">
          <div class="flex my-2 text-white p-4 items-center" :class="getClassByType(problem.type)">
            <div class="flex-shrink-0">
              <c-icon :icon="problem.icon" :size="24" />
            </div>
            <span class="text-base px-4" v-html="problem.content">
            </span>
          </div>
        </template>
      </section>
      <h2 class="text-2xl font-medium mx-auto text-center">
        Dashboard
      </h2>
      <section class="version-checks pt-6">
        <div class="section-title">
          <h2>Version</h2>
        </div>
        <div class="dashboard-stats version-check normal">
          <div class="version-number">
            <h4>Installed</h4>
            <h3>{{ dashboardData.version_check.installed_version }}</h3>
            <div class="sha-link">
              (<a :href="commitUrl" rel="noopener noreferrer" target="_blank">{{ formattedSha }}</a>)
            </div>
          </div>
          <div class="version-status">
            <template v-if="!dashboardData.version_check.updates_available">
              <div class="face">
                <span class="up-to-date">
                  <SmileIcon :size="48" />
                </span>
              </div>
              <div class="version-notes">You're up to date!</div>
            </template>
            <template v-else>
              <div class="face">
                <span class="updates-available">
                  <SmileIcon :size="48" />
                </span>
              </div>
              <div class="version-notes">
                <p>Updates available</p>
              </div>
              <span class="text-gray-500">{{ dashboardData.version_check.versions_diff }} commits behind</span>
            </template>
          </div>
          <div class="upgrade-header" v-if="SiteSettings.enable_web_updater">
            <router-link to="/admin/updates">
              <c-button icon="arrow-right">Upgrade</c-button>
            </router-link>
          </div>
        </div>
      </section>


      <div class="section-title">
        <h2>Statistics</h2>
      </div>

      <div class="flex w-full justify-center" v-if="!statisticsData">
        <c-spinner />
      </div>
      <div class="dashboard-stats" v-else>

        <div class="charts">
          <div class="admin-stats-consolidated">
            <div class="header">
              <h2>
                Signups last 30 days
              </h2>
            </div>
            <admin-reports-chart v-if="statisticsData" :chartData="createChartData(statisticsData.statistics[0])"
              :chartOptions="chartOptions" />

          </div>

          <template v-for="statistic in statisticsData.statistics.slice(1)">
            <div class="admin-stats">
              <div class="header">
                <h2>
                  {{ i18n.t(`js.admin.dashboard.statistics.${statistic.type}`) }}
                </h2>
              </div>
              <admin-reports-chart v-if="statisticsData" :chartData="createChartData(statistic)"
                :chartOptions="chartOptions" />
            </div>
          </template>
      
          



        </div>

      </div>

    </div>

  </div>
</template>
  
<script setup>
import { ref, computed, onMounted, inject } from 'vue'
import { UploadCloud } from 'lucide-vue-next'
import { useHead } from 'unhead'
import { ajax } from '../../lib/axios-setup';
import { Chart, registerables } from "chart.js";
import adminReportsChart from '../../components/admin/admin-reports-chart.vue'
Chart.register(...registerables);

const SiteSettings = inject('SiteSettings')
const i18n = inject('I18n');


useHead({
  title: 'Dashboard',
  meta: [
    {
      name: 'description',
      content: 'Dashboard'
    }
  ]
})

const colorFromVar = (variable) => {
  // Get the value of the css variable (:root)
  // If it's a hex color, return as rgba, otherwise return the variable

  const value = getComputedStyle(document.documentElement).getPropertyValue(variable).trim()

  if (value.startsWith('#')) {
    const hex = value.replace('#', '')
    const r = parseInt(hex.substring(0, 2), 16)
    const g = parseInt(hex.substring(2, 4), 16)
    const b = parseInt(hex.substring(4, 6), 16)

    return `rgba(${r}, ${g}, ${b}, 1)`
  } else {
    return value
  }
}


const dashboardData = ref(null)
const statisticsData = ref(null)

const commitUrl = computed(() => {
  return `https://github.com/CinelarTV/CinelarTV-AIO/commits/${dashboardData.value.version_check.installed_sha}`
})

const formattedSha = computed(() => {
  return dashboardData.value.version_check.installed_sha.substr(0, 10)
})

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  layout: {
    padding: {
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
    },
  },
  // tooltip event if the bar is not hovered
  hover: {
    mode: 'nearest',
    intersect: false,
  },
  scales: {
    y: {
      // don't use decimals in the y-axis
      ticks: {
        precision: 0,
        sampleSize: 100,
        maxRotation: 25,
        minRotation: 25
      }

    },
    x:
    {
      display: true,
      gridLines: { display: false },
      ticks: {
        sampleSize: 5,
        maxRotation: 50,
        minRotation: 50,
      },
    },

  }
}

const getClassByType = (type) => {
  switch (type) {
    case 'critical':
      return 'bg-red-500'
    case 'warning':
      return 'bg-yellow-500'
    case 'info':
      return 'bg-blue-500'
    default:
      return 'bg-gray-500'
  }
}

const createChartData = (chart) => {
  const labels = chart.data.map(item => item.x);
  const data = chart.data.map(item => item.y);

  return {
    labels,
    datasets: [
      {
        label: chart.title,
        data,
        backgroundColor: [
          colorFromVar('--c-tertiary-400')
        ],
        borderColor: [
          colorFromVar('--c-tertiary-300')
        ],
        borderWidth: 1,
        borderDash: [5, 5],
      },
    ],
  };
};


const fetchDashboard = async () => {
  try {
    const response = await ajax.get('/admin/dashboard.json')
    dashboardData.value = response.data
    fetchStatistics()
  } catch (error) {
    console.log(error)
    this.error = true
  }
}

const fetchStatistics = async () => {
  try {
    const response = await ajax.get('/admin/dashboard/statistics.json')
    statisticsData.value = response.data
  } catch (error) {
    console.log(error)
  }
}

onMounted(() => {
  fetchDashboard()
})
</script>