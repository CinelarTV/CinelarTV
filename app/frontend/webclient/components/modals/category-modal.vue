<template>
    <TransitionRoot appear :show="isOpen" as="template">
        <Dialog as="div" class="relative z-50" @close="handleClose">
            <!-- Backdrop -->
            <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
                leave="duration-200 ease-in" leave-from="opacity-100" leave-to="opacity-0">
                <div class="fixed inset-0 bg-black/60 backdrop-blur-sm" />
            </TransitionChild>

            <!-- Modal container -->
            <div class="fixed inset-0 flex items-center justify-center p-4">
                <TransitionChild as="template" enter="duration-300 ease-out"
                    enter-from="opacity-0 scale-95 translate-y-2" enter-to="opacity-100 scale-100 translate-y-0"
                    leave="duration-200 ease-in" leave-from="opacity-100 scale-100 translate-y-0"
                    leave-to="opacity-0 scale-95 translate-y-2">
                    <DialogPanel
                        class="w-full max-w-lg rounded-2xl overflow-hidden shadow-2xl ring-1 ring-[var(--c-primary-400)] bg-[var(--c-primary-600)]"
                        @click.stop>

                        <!-- Header -->
                        <div class="bg-[var(--c-primary-color)] px-8 pt-8 pb-6 border-b border-[var(--c-primary-200)]">
                            <DialogTitle as="h2"
                                class="text-xl font-semibold tracking-tight text-[var(--c-body-text-color)]">
                                {{ isEditMode ? 'Edit Category' : 'Add Category' }}
                            </DialogTitle>
                        </div>

                        <!-- Form body -->
                        <div class="px-8 py-6">
                            <form @submit.prevent="submit">
                                <div class="space-y-4">
                                    <div>
                                        <label for="category-name"
                                            class="block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)] mb-1.5">
                                            Category Name
                                        </label>
                                        <CInput v-model="categoryData.name" id="category-name"
                                            placeholder="e.g., Action, Comedy, Drama" required />
                                        <p v-if="errors.name" class="mt-1 text-xs text-rose-400">
                                            {{ errors.name }}
                                        </p>
                                    </div>

                                    <div>
                                        <label for="category-description"
                                            class="block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)] mb-1.5">
                                            Description
                                        </label>
                                        <CTextarea v-model="categoryData.description" id="category-description"
                                            placeholder="Enter a description for this category..." :rows="3" required />
                                        <p v-if="errors.description" class="mt-1 text-xs text-rose-400">
                                            {{ errors.description }}
                                        </p>
                                    </div>

                                    <div>
                                        <label for="category-tmdb-id"
                                            class="block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)] mb-1.5">
                                            TMDB ID (optional)
                                        </label>
                                        <CInput v-model="categoryData.tmdb_id" id="category-tmdb-id"
                                            type="number" placeholder="e.g., 28 for Action" />
                                        <p class="mt-1 text-xs text-[var(--c-primary-900)]">
                                            Maps this category to a TMDB genre ID for automatic assignment
                                        </p>
                                        <p v-if="errors.tmdb_id" class="mt-1 text-xs text-rose-400">
                                            {{ errors.tmdb_id }}
                                        </p>
                                    </div>
                                </div>

                                <!-- Navigation buttons -->
                                <div class="mt-6 flex items-center justify-end gap-3">
                                    <button type="button" @click="handleClose"
                                        class="inline-flex items-center gap-2 rounded-xl border border-[var(--c-primary-300)] bg-[var(--c-primary-200)] px-4 py-2.5 text-sm font-medium text-[var(--c-body-text-color)] transition-all hover:bg-[var(--c-primary-300)]">
                                        Cancel
                                    </button>

                                    <button type="submit" :disabled="loading"
                                        class="inline-flex items-center gap-2 rounded-xl bg-[var(--c-tertiary-color)] px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-all hover:bg-[var(--c-tertiary-100)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--c-tertiary-color)] disabled:cursor-not-allowed disabled:opacity-40">
                                        <Loader2 v-if="loading" :size="15" class="animate-spin" />
                                        <CheckIcon v-else :size="15" />
                                        {{ isEditMode ? 'Update Category' : 'Create Category' }}
                                    </button>
                                </div>

                                <!-- General error message -->
                                <p v-if="generalError" class="mt-4 text-xs font-medium text-center text-rose-400">
                                    {{ generalError }}
                                </p>
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
import { ajax } from '../../lib/Ajax'

const emit = defineEmits(['category-saved'])

const isOpen = ref(false)
const loading = ref(false)
const generalError = ref('')
const errors = ref({})
const isEditMode = ref(false)
const categoryId = ref(null)
const categoryData = ref({
    name: '',
    description: '',
    tmdb_id: null
})

// Methods
const handleClose = () => {
    setIsOpen(false)
}

const setIsOpen = (value, category = null) => {
    clearData()
    isOpen.value = value
    
    if (category) {
        isEditMode.value = true
        categoryId.value = category.id
        categoryData.value = {
            name: category.name || '',
            description: category.description || '',
            tmdb_id: category.tmdb_id || null
        }
    } else {
        isEditMode.value = false
        categoryId.value = null
    }
}

const clearData = () => {
    categoryData.value = {
        name: '',
        description: '',
        tmdb_id: null
    }
    errors.value = {}
    generalError.value = ''
}

const submit = async () => {
    loading.value = true
    errors.value = {}
    generalError.value = ''

    const data = {
        category: {
            name: categoryData.value.name,
            description: categoryData.value.description,
            tmdb_id: categoryData.value.tmdb_id
        }
    }

    try {
        let response
        if (isEditMode.value) {
            response = await ajax.put(`/admin/categories/${categoryId.value}.json`, data)
        } else {
            response = await ajax.post('/admin/categories.json', data)
        }
        
        loading.value = false
        setIsOpen(false)
        emit('category-saved', response.data)
    } catch (error) {
        loading.value = false
        if (error.response?.data?.errors) {
            errors.value = error.response.data.errors
        } else {
            generalError.value = isEditMode.value 
                ? 'Failed to update category. Please try again.'
                : 'Failed to create category. Please try again.'
        }
    }
}

defineExpose({
    setIsOpen
})
</script>
