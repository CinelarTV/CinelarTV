<template>
    <TransitionRoot appear :show="isOpen" as="template">
        <Dialog as="div" @close="setIsOpen(false)" class="relative z-100">
            <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
                leave="duration-200 ease-in" leave-from="opacity-100" leave-to="opacity-0">
                <div class="fixed inset-0 bg-black/60 backdrop-blur-sm" />
            </TransitionChild>

            <div class="fixed inset-0 z-[102] flex items-center justify-center p-4">
                <TransitionChild as="template" enter="duration-300 ease-out"
                    enter-from="opacity-0 scale-95 translate-y-2" enter-to="opacity-100 scale-100 translate-y-0"
                    leave="duration-200 ease-in" leave-from="opacity-100 scale-100 translate-y-0"
                    leave-to="opacity-0 scale-95 translate-y-2">
                    <DialogPanel
                        class="w-full max-w-2xl overflow-hidden rounded-2xl bg-[var(--c-primary-100)] shadow-2xl ring-1 ring-[var(--c-primary-200)]">
                        <div
                            class="border-b border-[var(--c-primary-200)] bg-[var(--c-primary-color)] px-6 pb-6 pt-6 text-center">
                            <DialogTitle as="h2"
                                class="text-lg font-semibold tracking-tight text-[var(--c-body-text-color)]" v-emoji>
                                Seleccionar canal XMLTV
                            </DialogTitle>
                            <p class="mt-1 text-sm text-[var(--c-primary-900)]">Busca y elige el canal desde una fuente
                                XMLTV.</p>
                        </div>

                        <div class="px-6 py-5">
                            <div class="flex gap-3 mb-4">
                                <select v-model="selectedSourceId" class="flex-1">
                                    <option value="" disabled>Elegir fuente XMLTV</option>
                                    <option v-for="s in props.sources" :key="s.id" :value="s.id">{{ s.name }}</option>
                                </select>
                                <c-button type="button" @click="fetchChannels(true)" :loading="loading">Fetch</c-button>
                            </div>

                            <div class="flex items-center gap-3 mb-4">
                                <input v-model="q" @input="debouncedFetch" placeholder="Buscar por nombre o id"
                                    class="flex-1" />
                                <c-button type="button" @click="debouncedFetch">Buscar</c-button>
                            </div>

                            <div v-if="loading" class="py-6 text-center">
                                <c-spinner />
                            </div>

                            <ul v-else class="space-y-2 max-h-64 overflow-auto">
                                <li v-for="ch in channels" :key="ch.id" @click="selectChannel(ch)"
                                    class="p-2 rounded hover:bg-[var(--c-primary-200)] cursor-pointer flex items-center gap-3">
                                    <img v-if="ch.icon" :src="ch.icon" class="h-8 w-8 object-contain" />
                                    <div>
                                        <div class="font-medium">{{ ch.display_name || '(sin nombre)' }}</div>
                                        <div class="text-xs text-[var(--c-primary-900)]">{{ ch.id }}</div>
                                    </div>
                                </li>
                            </ul>

                            <div class="mt-4 flex items-center justify-between">
                                <div class="text-sm">Mostrando {{ channels.length }} / {{ total }} resultados</div>
                                <div class="flex items-center gap-2">
                                    <button type="button" class="btn" :disabled="page <= 1"
                                        @click="prevPage">Anterior</button>
                                    <button type="button" class="btn" :disabled="(page * perPage) >= total"
                                        @click="nextPage">Siguiente</button>
                                </div>
                            </div>

                            <div class="mt-6 flex justify-end gap-3">
                                <button type="button" class="btn" @click="setIsOpen(false)">Cancelar</button>
                            </div>
                        </div>
                    </DialogPanel>
                </TransitionChild>
            </div>
        </Dialog>
    </TransitionRoot>
</template>

<script setup lang="ts">
import { ref, watch, toRefs } from 'vue'
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import { ajax } from '../../lib/Ajax'

const props = withDefaults(defineProps<{ sources?: any[] }>(), { sources: () => [] })
const { sources } = toRefs(props)

const emit = defineEmits<{ selected: [string] }>()

const isOpen = ref(false)
const loading = ref(false)
const channels = ref<any[]>([])
const total = ref(0)
const page = ref(1)
const perPage = ref(20)
const q = ref('')
const selectedSourceId = ref('')

let fetchTimer: number | null = null
let fetchAbortController: AbortController | null = null

const resetState = () => {
    channels.value = []
    total.value = 0
    page.value = 1
    perPage.value = 20
    q.value = ''
    selectedSourceId.value = sources.value?.[0]?.id || ''
}

const setIsOpen = (v: boolean) => {
    isOpen.value = v
    if (!v) {
        if (fetchTimer) {
            window.clearTimeout(fetchTimer)
            fetchTimer = null
        }
        cancelPendingFetch()
        return
    }

    resetState()
    fetchChannels()
}

const openWith = ({ sourceId, initialXmltvId }: { sourceId?: string; initialXmltvId?: string } = {}) => {
    if (sourceId) selectedSourceId.value = sourceId
    if (initialXmltvId) q.value = initialXmltvId
    setIsOpen(true)
}

defineExpose({ setIsOpen, openWith })

const cancelPendingFetch = () => {
    if (fetchAbortController) {
        fetchAbortController.abort()
        fetchAbortController = null
    }
}

const debouncedFetch = () => {
    if (fetchTimer) window.clearTimeout(fetchTimer)
    fetchTimer = window.setTimeout(() => {
        page.value = 1
        fetchChannels()
    }, 250)
}

const fetchChannels = async (fetchRemote = false) => {
    if (!selectedSourceId.value) {
        channels.value = []
        total.value = 0
        return
    }

    cancelPendingFetch()
    fetchAbortController = new AbortController()

    loading.value = true
    try {
        const params: any = { page: page.value, per_page: perPage.value }
        if (q.value) params.q = q.value
        if (fetchRemote) params.fetch = true

        const resp = await ajax.get(`/admin/xmltv_sources/${selectedSourceId.value}/channels.json`, {
            params,
            signal: fetchAbortController.signal,
        })
        channels.value = resp.data.channels || []
        total.value = resp.data.total || 0
    } catch (err: any) {
        if (err?.name === 'CanceledError' || err?.name === 'AbortError') {
            return
        }

        console.error('Error fetching channels', err)
        channels.value = []
        total.value = 0
    } finally {
        loading.value = false
        fetchAbortController = null
    }
}

watch([selectedSourceId, page, perPage], () => {
    fetchChannels()
})

const selectChannel = (ch: any) => {
    emit('selected', ch.id)
    setIsOpen(false)
}

const prevPage = () => {
    if (page.value > 1) {
        page.value -= 1
    }
}

const nextPage = () => {
    if ((page.value * perPage.value) < total.value) {
        page.value += 1
    }
}
</script>
