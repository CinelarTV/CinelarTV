<template>
    <div class="flex flex-col h-full">
        <!-- Table with event_name and formatted payload -->
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
                    <!-- Use a <pre> tag to display formatted JSON -->
                    <td>
                        <pre>{{ formatPayload(log.payload) }}</pre>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</template>
  
<script setup>
import { ref, computed, onMounted, inject } from 'vue'
import { ajax } from '../../../lib/Ajax'

onMounted(() => {
    fetchLogs()
})

const logs = ref(null)

const fetchLogs = async () => {
    const response = await ajax.get('/admin/webhooks/logs.json')
    logs.value = response.data.data
}

// Función para formatear la cadena JSON de payload
const formatPayload = (payload) => {
    try {
        const parsedPayload = JSON.parse(payload)
        // Use JSON.stringify con espacios de sangría para formatear
        return JSON.stringify(parsedPayload, null, 2)
    } catch (error) {
        return 'Invalid JSON'
    }
}
</script>
  ../../../lib/ajax