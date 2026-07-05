<template>
    <TransitionRoot appear :show="isOpen" as="template">
        <Dialog as="div" class="relative z-50" @close="setIsOpen(false)">
            <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
                leave="duration-200 ease-in" leave-from="opacity-100" leave-to="opacity-0">
                <div class="fixed inset-0 bg-black/60 backdrop-blur-sm" />
            </TransitionChild>

            <div class="fixed inset-0 flex items-center justify-center p-4">
                <TransitionChild as="template" enter="duration-300 ease-out"
                    enter-from="opacity-0 scale-95 translate-y-2" enter-to="opacity-100 scale-100 translate-y-0"
                    leave="duration-200 ease-in" leave-from="opacity-100 scale-100 translate-y-0"
                    leave-to="opacity-0 scale-95 translate-y-2">
                    <DialogPanel
                        class="w-full max-w-md rounded-2xl overflow-hidden shadow-2xl ring-1 ring-[var(--c-primary-400)] bg-[var(--c-primary-600)]"
                        @click.stop>

                        <!-- Header -->
                        <div
                            class="bg-[var(--c-primary-color)] px-8 pt-8 pb-6 text-center border-b border-[var(--c-primary-200)]">
                            <DialogTitle as="h2"
                                class="text-xl font-semibold tracking-tight text-[var(--c-body-text-color)]">
                                Edit Season
                            </DialogTitle>
                        </div>

                        <!-- Form body -->
                        <div class="px-8 py-6">
                            <form @submit="(e) => { e.preventDefault() }" novalidate>
                                <div class="space-y-4">
                                    <CFormRow label="Season Title" for="season-title" :error="errors.title">
                                        <CInput v-model="seasonData.title" id="season-title"
                                            placeholder="Season 1" />
                                    </CFormRow>

                                    <CFormRow label="Description" for="season-description" :error="errors.description">
                                        <CTextarea v-model="seasonData.description" id="season-description"
                                            placeholder="Optional description..." :rows="2" />
                                    </CFormRow>
                                </div>

                                <!-- Error -->
                                <p v-if="generalError" class="mt-4 text-xs font-medium text-center text-rose-400">
                                    {{ generalError }}
                                </p>

                                <!-- Actions -->
                                <div class="mt-6 flex items-center justify-end gap-3">
                                    <button type="button" @click="setIsOpen(false)"
                                        class="inline-flex items-center gap-2 rounded-xl border border-[var(--c-primary-300)] bg-[var(--c-primary-200)] px-4 py-2.5 text-sm font-medium text-[var(--c-body-text-color)] transition-all hover:bg-[var(--c-primary-300)]">
                                        Cancel
                                    </button>
                                    <button type="button" @click="submitUpdateSeason"
                                        :disabled="!canSubmit || loading"
                                        class="inline-flex items-center gap-2 rounded-xl bg-[var(--c-tertiary-color)] px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-all hover:bg-[var(--c-tertiary-100)] disabled:cursor-not-allowed disabled:opacity-40">
                                        <Loader2 v-if="loading" :size="15" class="animate-spin" />
                                        <CheckIcon v-else :size="15" />
                                        Save Changes
                                    </button>
                                </div>
                            </form>
                        </div>

                    </DialogPanel>
                </TransitionChild>
            </div>
        </Dialog>
    </TransitionRoot>
</template>

<script setup>
import { ref, computed } from 'vue'
import {
    Dialog,
    DialogPanel,
    DialogTitle,
    TransitionChild,
    TransitionRoot,
} from '@headlessui/vue'
import {
    CheckIcon,
    Loader2,
} from 'lucide-vue-next'
import CInput from '../forms/c-input.vue'
import CTextarea from '../forms/c-textarea.vue'
import CFormRow from '../forms/CFormRow.tsx'
import { ajax } from '../../lib/Ajax'

const emit = defineEmits(['season-updated'])

const props = defineProps({
    contentId: String,
})

const isOpen = ref(false)
const loading = ref(false)
const generalError = ref('')
const errors = ref({})
const seasonData = ref({
    id: '',
    title: '',
    description: '',
})

const canSubmit = computed(() => {
    return seasonData.value.title.trim().length >= 1 && !loading.value
})

const setIsOpen = (value, season = null) => {
    if (season) {
        seasonData.value.id = season.id
        seasonData.value.title = season.title || ''
        seasonData.value.description = season.description || ''
    }
    isOpen.value = value
}

defineExpose({
    setIsOpen,
})

const submitUpdateSeason = () => {
    if (!canSubmit.value) return

    loading.value = true
    generalError.value = ''

    ajax.put(`/admin/content-manager/${props.contentId}/seasons/${seasonData.value.id}`, {
        season: {
            title: seasonData.value.title,
            description: seasonData.value.description,
        }
    })
        .then(response => {
            emit('season-updated', response)
            setIsOpen(false)
        })
        .catch(error => {
            if (error.response?.data?.errors) {
                errors.value = error.response.data.errors
            } else {
                generalError.value = 'Failed to update season. Please try again.'
            }
        })
        .finally(() => {
            loading.value = false
        })
}
</script>
