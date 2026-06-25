<template>
    <div class="updater panel">
        <template v-if="loading">
            <div class="flex justify-center items-center py-24">
                <c-spinner />
            </div>
        </template>

        <template v-else>
            <div class="sm:p-8 p-4">

                <div v-if="!SiteSettings.enable_web_updater" class="text-center py-12 text-white/50">
                    {{ js.admin.updater.web_updater_disabled }}
                </div>

                <div v-else class="max-w-2xl mx-auto">

                    <!-- Banner -->
                    <div id="ready-for-update-banner"
                        class="relative overflow-hidden rounded-xl mb-8 px-8 py-10 bg-[var(--c-primary-50)] flex flex-col items-center text-center gap-3">
                        <span
                            class="text-xs font-semibold uppercase tracking-widest text-[var(--c-primary-300)] bg-[var(--c-primary-100)] px-3 py-1 rounded-full">
                            Experimental
                        </span>
                        <h2 class="text-2xl font-semibold text-white">
                            {{ $t('js.admin.updater.ready_title') }}
                        </h2>
                        <p class="text-white/60 text-sm max-w-md leading-relaxed">
                            {{ $t('js.admin.updater.ready_description') }}
                        </p>
                    </div>

                    <!-- Acciones -->
                    <div class="flex items-center justify-center gap-3 mb-6">
                        <c-button @click="runUpdate" :disabled="updating" class="!px-6 !py-2.5 !text-sm !font-semibold"
                            :class="updating ? '!bg-white/10 !text-white/40 cursor-not-allowed' : ''">
                            <span v-if="updating" class="flex items-center gap-2">
                                <svg class="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none">
                                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor"
                                        stroke-width="3" />
                                    <path class="opacity-75" fill="currentColor"
                                        d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
                                </svg>
                                Actualizando...
                            </span>
                            <span v-else>Actualizar ahora</span>
                        </c-button>

                        <c-button @click="restartServer" :disabled="updating"
                            class="!px-6 !py-2.5 !text-sm !font-semibold !bg-red-500/10 !text-red-400 !border-red-500/20 hover:!bg-red-500/20"
                            :class="updating ? 'opacity-40 cursor-not-allowed' : ''">
                            Reiniciar servidor
                        </c-button>
                    </div>

                    <!-- Barra de progreso -->
                    <div v-if="updating" class="mb-4">
                        <div class="flex justify-between text-xs text-white/40 mb-1.5">
                            <span>Progreso</span>
                            <span>{{ updateProgress }}%</span>
                        </div>
                        <div class="w-full h-1.5 bg-white/10 rounded-full overflow-hidden">
                            <div class="h-full bg-[var(--c-primary-300)] rounded-full transition-all duration-300"
                                :style="`width: ${updateProgress}%`" />
                        </div>
                    </div>

                    <!-- Error -->
                    <div v-if="updateStatus === 'failed'"
                        class="flex items-start gap-3 bg-red-500/10 border border-red-500/20 rounded-xl px-4 py-3 mb-4">
                        <AlertTriangle class="w-4 h-4 text-red-400 mt-0.5 flex-shrink-0" />
                        <div>
                            <p class="text-sm font-semibold text-red-400">Falló la actualización</p>
                            <p class="text-xs text-red-400/70 mt-0.5">Revisá los logs para más información.</p>
                        </div>
                    </div>

                    <!-- Logs -->
                    <details v-if="outputMessage.length > 0" id="expandable-logs" class="group">
                        <summary
                            class="flex items-center justify-between cursor-pointer select-none px-4 py-3 rounded-xl bg-white/5 border border-white/8 text-sm text-white/60 hover:text-white/90 hover:bg-white/8 transition-colors list-none">
                            <span class="truncate max-w-sm font-mono text-xs">{{ currentLine }}</span>
                            <svg class="w-4 h-4 flex-shrink-0 ml-2 transition-transform group-open:rotate-180"
                                viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polyline points="6 9 12 15 18 9" />
                            </svg>
                        </summary>
                        <div class="terminal-updating mt-2 rounded-xl">
                            <template v-for="line in outputMessage">{{ line }}</template>
                        </div>
                    </details>

                </div>
            </div>
        </template>
    </div>
</template>

<script setup>
import { onMounted, ref, onUnmounted } from 'vue';
import { AlertTriangle } from 'lucide-vue-next';
import { useHead } from 'unhead';
import { toast } from 'vue3-toastify';
import { ajax } from '../../lib/Ajax';


var updating = ref(false)
var loading = ref(true)
var updateResponse = ref(null)
var outputMessage = ref([])
var currentLine = ref('')
var updateProgress = ref(0)
var updateStatus = ref(null)

useHead({
    title: 'Update Manager'
})

// Try to prevent the user from leaving the page while updating, maybe show an alert
window.onbeforeunload = function () {
    if (updating.value) {
        return "CinelarTV is updating, we recommend you to wait until the update is finished."
    }
}



const handleFailed = () => {
    let expandableLogs = document.getElementById("expandable-logs")
    MessageBus.unsubscribe('/admin/upgrade')
    currentLine.value = 'Failed to update CinelarTV. Please check the logs for more information.';
    if (expandableLogs) expandableLogs.setAttribute("open", "true");
}

onMounted(() => {
    ajax.get('/admin/updates.json')
        .then(response => {
            loading.value = false
            updateResponse.value = response.data
        }).catch(error => {
            loading.value = false
            console.log(error)
        })

    MessageBus.subscribe("/admin/upgrade", (data) => {
        if (data.type == "percent") {
            updating.value = true
            updateProgress.value = data.value
        }
        if (data.type == "log") {
            updating.value = true
            outputMessage.value.push(data.value)
            currentLine.value = data.value
        }
        if (data.type == "status") {
            updateStatus.value = data.value
            console.log(data.value)
            if (data.value == "failed") {
                handleFailed()
            }
            if (data.value == "complete") {
                updating.value = false
                toast.success("Update complete")
            }
            if (data.value == "restarted") {
                updating.value = false
                updateProgress.value = 0
                toast.info("Servidor reiniciado, reconectando...")
            }
        }
    });
})

const runUpdate = () => {
    updating.value = true
    outputMessage.value = []
    ajax.post('/admin/upgrade.json')
        .then(response => {
            if (response.data.error_type === "no_updates_available") {
                updating.value = false
                toast.info("No updates available")
            }
        })
}


const restartServer = () => {
    ajax.post('/admin/restart.json')
        .then(response => {
            console.log(response)
        })
}

onUnmounted(() => {
    MessageBus.unsubscribe('/admin/upgrade')
})
</script>