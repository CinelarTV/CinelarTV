<template>
    <div v-if="loading">
        <c-spinner />
    </div>
    <div v-else class="panel">
        <div class="panel-header">
            <div class="panel-title">
                {{ content.title }} - Analytics
            </div>
        </div>
        <div class="panel-body">
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                <div class="bg-[var(--c-primary-600)] rounded-lg p-4">
                    <div class="text-sm text-[var(--c-primary-100)]">Total Views</div>
                    <div class="text-2xl font-bold">{{ analytics.total_views }}</div>
                </div>
                <div class="bg-[var(--c-primary-600)] rounded-lg p-4">
                    <div class="text-sm text-[var(--c-primary-100)]">Hours Watched</div>
                    <div class="text-2xl font-bold">{{ totalHoursWatched }}</div>
                </div>
                <div class="bg-[var(--c-primary-600)] rounded-lg p-4">
                    <div class="text-sm text-[var(--c-primary-100)]">Unique Profiles</div>
                    <div class="text-2xl font-bold">{{ analytics.unique_profiles }}</div>
                </div>
                <div class="bg-[var(--c-primary-600)] rounded-lg p-4">
                    <div class="text-sm text-[var(--c-primary-100)]">Completion Rate</div>
                    <div class="text-2xl font-bold">{{ analytics.completion_rate }}%</div>
                </div>
            </div>

            <div class="mb-6">
                <h3 class="text-lg font-semibold mb-2">Watch Time (Last 30 Days)</h3>
                <div class="h-64">
                    <admin-reports-chart 
                        v-if="dailyWatchTimeData.length > 0"
                        :chartData="dailyWatchTimeData" 
                        :chartOptions="chartOptions" 
                    />
                    <div v-else class="flex items-center justify-center h-full text-[var(--c-primary-200)]">
                        No watch time data available
                    </div>
                </div>
            </div>

            <div>
                <h3 class="text-lg font-semibold mb-2">Recent Sessions</h3>
                <div class="overflow-x-auto">
                    <table class="w-full text-sm">
                        <thead>
                            <tr class="border-b border-[var(--c-primary-500)]">
                                <th class="text-left p-2">Profile</th>
                                <th class="text-left p-2">Started</th>
                                <th class="text-left p-2">Duration</th>
                                <th class="text-left p-2">Watched</th>
                                <th class="text-left p-2">Progress</th>
                                <th class="text-left p-2">Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="session in recentSessions" :key="session.id" class="border-b border-[var(--c-primary-500)]">
                                <td class="p-2">{{ session.profile_name }}</td>
                                <td class="p-2">{{ formatDate(session.started_at) }}</td>
                                <td class="p-2">{{ formatDuration(session.total_duration) }}</td>
                                <td class="p-2">{{ formatDuration(session.duration_watched) }}</td>
                                <td class="p-2">
                                    <div class="w-full bg-[var(--c-primary-700)] rounded-full h-2">
                                        <div 
                                            class="bg-[var(--c-tertiary-400)] h-2 rounded-full" 
                                            :style="{ width: `${session.watch_percentage}%` }"
                                        ></div>
                                    </div>
                                </td>
                                <td class="p-2">
                                    <span 
                                        :class="session.completed ? 'text-green-400' : 'text-yellow-400'"
                                    >
                                        {{ session.completed ? 'Completed' : 'In Progress' }}
                                    </span>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { ajax } from '../../../lib/Ajax';
import adminReportsChart from '../../../components/admin/admin-reports-chart.vue';

const route = useRoute();
const contentId = route.params.id;
const loading = ref(true);
const content = ref({});
const analytics = ref({});
const dailyWatchTime = ref([]);
const recentSessions = ref([]);

const totalHoursWatched = computed(() => {
    return (analytics.value.total_seconds_watched / 3600).toFixed(1);
});

const dailyWatchTimeData = computed(() => {
    return {
        labels: dailyWatchTime.value.map(item => item.x),
        datasets: [{
            label: 'Hours Watched',
            data: dailyWatchTime.value.map(item => item.y),
            backgroundColor: 'rgba(59, 130, 246, 0.5)',
            borderColor: 'rgba(59, 130, 246, 1)',
            borderWidth: 1,
        }]
    };
});

const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    scales: {
        y: {
            beginAtZero: true,
            ticks: { precision: 1 }
        }
    }
};

const formatDate = (date) => {
    return new Date(date).toLocaleDateString();
};

const formatDuration = (seconds) => {
    if (!seconds) return '0:00';
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
};

const fetchAnalytics = async () => {
    try {
        const response = await ajax.get(`/admin/content-manager/${contentId}/analytics.json`);
        const data = response.data.data;
        content.value = data.content;
        analytics.value = data.analytics;
        dailyWatchTime.value = data.daily_watch_time;
        recentSessions.value = data.recent_sessions;
    } catch (error) {
        console.error('Error fetching analytics:', error);
    } finally {
        loading.value = false;
    }
};

onMounted(() => {
    fetchAnalytics();
});
</script>
