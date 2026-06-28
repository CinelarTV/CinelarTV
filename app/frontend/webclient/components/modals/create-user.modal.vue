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
                        class="w-full max-w-lg overflow-hidden rounded-2xl bg-[var(--c-primary-600)] shadow-2xl ring-1 ring-[var(--c-primary-400)]">
                        <div class="border-b border-[var(--c-primary-200)] bg-[var(--c-primary-color)] px-8 pb-6 pt-6 text-center">
                            <DialogTitle as="h2" class="text-xl font-semibold tracking-tight text-[var(--c-body-text-color)]">
                                Crear usuario
                            </DialogTitle>
                        </div>

                        <div class="px-8 py-6">
                            <form id="create-user-form" @submit="submitCreateUser" novalidate>
                                <div class="space-y-4">
                                    <div>
                                        <label class="mb-1.5 block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)]">Email</label>
                                        <c-input type="email" v-model="form.email" id="create-user-email" placeholder="user@example.com" />
                                    </div>

                                    <div>
                                        <label class="mb-1.5 block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)]">Username</label>
                                        <c-input type="text" v-model="form.username" id="create-user-username" placeholder="username" />
                                    </div>

                                    <div>
                                        <label class="mb-1.5 block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)]">Contraseña</label>
                                        <c-input type="password" v-model="form.password" id="create-user-password" placeholder="********" />
                                    </div>
                                </div>

                                <div v-if="errors.length" class="text-red-500 mt-3 space-y-1">
                                    <p v-for="err in errors" :key="err">{{ err }}</p>
                                </div>

                                <div class="mt-6 flex items-center justify-end gap-3">
                                    <c-button type="" @click="setIsOpen(false)">Cancelar</c-button>
                                    <c-button icon="plus" :loading="loading" type="" native-type="submit"> 
                                        <template #default>Crear</template>
                                    </c-button>
                                </div>
                            </form>
                        </div>
                    </DialogPanel>
                </TransitionChild>
            </div>
        </Dialog>
    </TransitionRoot>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import { ajax } from '../../lib/Ajax'
import CInput from '../forms/c-input.vue'
import CButton from '../forms/c-button'

const isOpen = ref(false)
const loading = ref(false)
const form = ref({ email: '', username: '', password: '' })
const errors = ref<string[]>([])

const emit = defineEmits<{
    created: [user: any]
}>()

const reset = () => {
    form.value = { email: '', username: '', password: '' }
    errors.value = []
    loading.value = false
}

const setIsOpen = (v: boolean) => {
    isOpen.value = v
    if (!v) reset()
}

defineExpose({ setIsOpen })

const submitCreateUser = async (e: Event) => {
    e.preventDefault()
    if (loading.value) return

    loading.value = true
    errors.value = []

    try {
        const response = await ajax.post('/admin/users/create_user', { user: form.value })
        const created = response?.data?.data
        if (created?.id) {
            emit('created', created)
            setIsOpen(false)
        } else if (response?.data?.data) {
            const data = response.data.data
            errors.value = Array.isArray(data) ? data : Object.values(data).flat().map(String)
            loading.value = false
        } else {
            errors.value = ['No se pudo crear el usuario']
            loading.value = false
        }
    } catch (err: any) {
        const msg = err?.response?.data?.error || err?.response?.data?.message || 'Error al crear usuario'
        errors.value = [msg]
        loading.value = false
    }
}
</script>
