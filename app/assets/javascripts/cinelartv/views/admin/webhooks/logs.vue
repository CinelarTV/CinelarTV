<template>
    <div class="flex flex-col h-full">
        <!-- Table with event_name and payload -->
        <table>
            <thead>
                <tr>
                    <th>Event Name</th>
                    <th>Payload</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="(log, index) in logs" :key="index">
                    <td>{{ log.event_name }}</td>
                    <td>{{ log.payload }}</td>
                </tr>
            </tbody>
        </table>
    </div>

</template>
  
<script setup>
import { ref, computed, onMounted, inject } from 'vue'
import { ajax } from '../../../lib/axios-setup';

onMounted(() => {
    fetchLogs();
});

const logs = ref(null)

const fetchLogs = async () => {
    const response = await ajax.get('/admin/webhooks/logs.json');
    logs.value = response.data;
}

</script>