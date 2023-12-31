<template>
    <div class="updater panel">
        <template v-if="loading">
            <c-spinner />
        </template>

        <template v-else>
            <div class="admin-update-manager sm:p-8 p-2">
                <div v-if="!SiteSettings.enable_web_updater">
                    {{ js.admin.updater.web_updater_disabled }}
                </div>

                <div v-else class="">

                    <section id="web-updater-landing" class="text-center">

                        <div id="ready-for-update-banner"
                            class="flex flex-col mb-8 py-8 w-full rounded-md bg-[var(--c-primary-50)]">
                            <h2 class="text-2xl font-medium">
                                {{ $t('js.admin.updater.ready_title') }}
                            </h2>
                        </div>

                        <span class="bg-blue-100 rounded-full px-2 py-1 text-blue-700 text-sm font-medium">
                            Experimental
                        </span>


                        <p class="max-w-2xl text-center mx-auto mt-2">
                            {{ $t('js.admin.updater.ready_description') }}
                        </p>

                    </section>

                    <div class="updater-footer flex mt-8 justify-center space-x-4">

                        <c-button @click="runUpdate" :disabled="updating"
                            class="button dark px-4 py-2 mt-4 flex justify-center"
                            :class="[updating ? '!bg-gray-700' : '']">
                            {{ updating ? "Updating..." : "Update now" }}
                        </c-button>

                        <c-button @click="restartServer" :disabled="updating"
                            class="button dark px-4 py-2 mt-4 flex justify-center !bg-red-500"
                            :class="[updating ? '!bg-gray-700' : '']">
                            Restart server
                        </c-button>
                    </div>

                    <section id="update-failed" class="mx-2 bg-red-500 px-4 py-2" v-if="updateStatus === 'failed'">

                    </section>
                    <div class="w-full bg-gray-200 mt-4" v-if="updating">
                        <div class="bg-blue-600 text-xs font-medium text-blue-100 text-center p-1 leading-none transition-all"
                            :style="`width: ${updateProgress}%`"> {{ updateProgress }}%</div>
                    </div>

                    <details id="expandable-logs" v-if="outputMessage.length > 0">
                        <summary>{{ currentLine }}</summary>
                        <div v-if="outputMessage.length > 0" class="terminal-updating">
                            <template v-for="line in outputMessage">
                                {{ line }}
                            </template>


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
    let expandableLogs = getElementById("expandable-logs")
    MessageBus.unsubscribe('/admin/upgrade')
    currentLine.value = 'Failed to update CinelarTV. Please check the logs for more information.';
    expandableLogs.setAttribute("open", "true");
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
        if(data) {
            // If we receive a message, it means the update is running
            updating.value = true
        }
        if (data.type == "percent") {
            updateProgress.value = data.value
        }
        if (data.type == "log") {
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
</script>../../lib/ajax