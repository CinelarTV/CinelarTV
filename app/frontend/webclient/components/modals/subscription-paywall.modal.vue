<template>
  <TransitionRoot appear :show="isOpen" as="template">
    <Dialog as="div" @close="setIsOpen(false)" class="modal overflow-hidden">
      <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
        leave="duration-200 ease-in" leave-from="opacity-100" leave-to="opacity-0">
        <div class="fixed inset-0 bg-black bg-opacity-80 backdrop-blur-sm z-[101]" />
      </TransitionChild>

      <div class="fixed inset-0 overflow-y-auto z-[102]">
        <div class="flex min-h-full items-center justify-center p-4 text-center">
          <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0 scale-95"
            enter-to="opacity-100 scale-100" leave="duration-200 ease-in" leave-from="opacity-100 scale-100"
            leave-to="opacity-0 scale-95">
            <DialogPanel
              class="dialog subscription-paywall w-full max-w-md transform overflow-hidden p-0 text-left align-middle shadow-2xl transition-all bg-[#1a1a1a] rounded-2xl border border-yellow-500/30">

              <div class="relative">
                <div
                  class="h-32 bg-gradient-to-r from-yellow-600 via-yellow-400 to-yellow-600 flex items-center justify-center relative overflow-hidden">
                  <div
                    class="absolute inset-0 opacity-20 bg-[url('https://www.transparenttextures.com/patterns/carbon-fibre.png')]">
                  </div>
                  <CIcon icon="star" class="w-16 h-16 text-white/50 absolute -right-4 -bottom-4 rotate-12" />
                  <img :src="SiteSettings.site_logo" class="h-12 relative z-10 brightness-0 invert" />
                </div>

                <div class="p-8 pb-10 text-center">
                  <DialogTitle as="h3" class="text-2xl font-bold text-white mb-2 tracking-tight">
                    Contenido Premium
                  </DialogTitle>

                  <div class="mb-6">
                    <div
                      class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-yellow-500/10 border border-yellow-500/20 text-yellow-500 text-xs font-bold uppercase tracking-widest mb-4">
                      <CIcon icon="lock" class="w-3 h-3" />
                      Exclusivo para Suscriptores
                    </div>

                    <p class="text-gray-400 text-sm leading-relaxed" v-emoji>
                      Este contenido solo está disponible para usuarios con una suscripción activa.
                      ¡Suscríbete ahora para disfrutar de este y muchos otros títulos exclusivos! 🍿
                    </p>
                  </div>

                  <div class="flex flex-col gap-3">
                    <RouterLink to="/billing">
                      <button
                        class="w-full py-4 px-6 bg-yellow-500 hover:bg-yellow-400 text-black font-bold rounded-xl transition-all duration-200 shadow-lg shadow-yellow-500/20 flex items-center justify-center gap-2 group">
                        Ver planes de suscripción
                        <CIcon icon="arrow-right" class="w-4 h-4 transition-transform group-hover:translate-x-1" />
                      </button>
                    </RouterLink>

                    <button @click="setIsOpen(false)"
                      class="text-gray-500 hover:text-white text-sm font-medium py-2 transition-colors">
                      Quizás más tarde
                    </button>
                  </div>
                </div>
              </div>

            </DialogPanel>
          </TransitionChild>
        </div>
      </div>
    </Dialog>
  </TransitionRoot>
</template>

<script setup>
import { ref, defineProps, defineEmits, defineExpose, inject } from 'vue'
import {
  TransitionRoot,
  TransitionChild,
  Dialog,
  DialogPanel,
  DialogTitle,
} from '@headlessui/vue'
import CIcon from '../c-icon.vue'

const SiteSettings = inject('SiteSettings')
const isOpen = ref(false)

function setIsOpen(value) {
  isOpen.value = value
}

defineExpose({
  setIsOpen
})
</script>

<style scoped>
.subscription-paywall {
  background: radial-gradient(circle at top right, rgba(234, 179, 8, 0.05) 0%, transparent 40%),
    #141414;
}
</style>
