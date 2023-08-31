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
          <div class="upgrade-header">
            <router-link to="/admin/updates">Update instance</router-link>
          </div>
        </div>
      </section>
    </div>

  </div>
</template>
  
<script setup>
import { ref, computed, onMounted } from 'vue'
import { UploadCloud } from 'lucide-vue-next'
import axios from 'axios'
import { useHead } from 'unhead'

useHead({
  title: 'Dashboard',
  meta: [
    {
      name: 'description',
      content: 'Dashboard'
    }
  ]
})

const dashboardData = ref(null)

const commitUrl = computed(() => {
  return `https://github.com/CinelarTV/CinelarTV-AIO/commits/${dashboardData.value.version_check.installed_sha}`
})

const formattedSha = computed(() => {
  return dashboardData.value.version_check.installed_sha.substr(0, 10)
})

const fetchDashboard = async () => {
  try {
    const response = await axios.get('/admin/dashboard.json')
    dashboardData.value = response.data
  } catch (error) {
    console.log(error)
    this.error = true
  }
}

onMounted(() => {
  fetchDashboard()
})
</script>