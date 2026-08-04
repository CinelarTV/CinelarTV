<template>
  <TransitionRoot appear :show="modelValue" as="template">
    <Dialog as="div" class="relative z-[100]" @close="handleClose">
      <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
        leave="duration-200 ease-in" leave-from="opacity-100" leave-to="opacity-0">
        <div class="fixed inset-0 bg-black/60 backdrop-blur-sm" />
      </TransitionChild>

      <div class="fixed inset-0 z-[102] flex items-center justify-center p-4">
        <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0 scale-95 translate-y-2"
          enter-to="opacity-100 scale-100 translate-y-0" leave="duration-200 ease-in"
          leave-from="opacity-100 scale-100 translate-y-0" leave-to="opacity-0 scale-95 translate-y-2">
          <DialogPanel :class="[
            'c-modal-panel',
            'w-full overflow-hidden rounded-2xl bg-[var(--c-primary-600)] shadow-2xl ',
            sizeClass
          ]" @click.stop>

            <div v-if="$slots.header || title"
              class="c-modal-header shrink-0 border-b border-[var(--c-primary-500)] bg-[var(--c-primary-color)] px-8 pb-6 pt-8">
              <slot name="header">
                <DialogTitle as="h3" class="text-xl font-semibold tracking-tight text-[var(--c-body-text-color)]">
                  {{ title }}
                </DialogTitle>
                <p v-if="subtitle" class="mt-1 text-sm text-[var(--c-primary-100)]">
                  {{ subtitle }}
                </p>
              </slot>
            </div>

            <div class="c-modal-body overflow-y-auto px-8 py-6">
              <slot />
            </div>

            <div v-if="$slots.footer" class="c-modal-footer shrink-0 bg-[var(--c-primary-color)] px-8 py-5">
              <slot name="footer" />
            </div>
          </DialogPanel>
        </TransitionChild>
      </div>
    </Dialog>
  </TransitionRoot>
</template>

<script setup>
import { computed } from 'vue'
import {
  Dialog,
  DialogPanel,
  DialogTitle,
  TransitionChild,
  TransitionRoot,
} from '@headlessui/vue'

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  title: { type: String, default: '' },
  subtitle: { type: String, default: '' },
  size: { type: String, default: 'md' },
  persistent: { type: Boolean, default: false },
})

const emit = defineEmits(['update:modelValue'])

const sizeClass = computed(() => {
  const sizes = {
    sm: 'max-w-sm',
    md: 'max-w-lg',
    lg: 'max-w-2xl',
    xl: 'max-w-4xl',
  }
  return sizes[props.size] || sizes.md
})

const handleClose = () => {
  if (!props.persistent) {
    emit('update:modelValue', false)
  }
}
</script>

<style>
.c-modal-panel {
  display: flex;
  flex-direction: column;
  max-height: 90vh;
}



.c-modal-body {
  flex: 1;
  min-height: 0;
}
</style>
