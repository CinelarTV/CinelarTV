<script setup>
import { computed } from "vue";
import {
  Listbox,
  ListboxButton,
  ListboxOption,
  ListboxOptions,
} from "@headlessui/vue";
import { ChevronDownIcon, CheckIcon } from "lucide-vue-next";

const props = defineProps({
  options: Array,
  modelValue: [String, Number, Array],
  placeholder: {
    type: String,
    default: "Seleccionar...",
  },
  multiple: Boolean,
  error: String
});

const emit = defineEmits(["update:modelValue"]);

const label = computed(() => {
  return props.options
    .filter(option => {
      if (Array.isArray(props.modelValue)) {
        return props.modelValue.includes(option.value);
      }
      return props.modelValue === option.value;
    })
    .map(option => option.label)
    .join(", ");
});
</script>

<template>
  <Listbox :model-value="props.modelValue" :multiple="props.multiple"
    @update:modelValue="value => emit('update:modelValue', value)">
    <div class="relative">
      <ListboxButton
        class="relative w-full flex items-center justify-between px-3 py-2.5 text-sm text-left rounded-lg bg-white/5 ring-1 ring-white/10 hover:ring-white/20 focus:outline-none focus:ring-[var(--c-primary-color)] focus:ring-offset-0 transition-colors"
      >
        <span v-if="label" class="block truncate text-white">{{ label }}</span>
        <span v-else class="block truncate text-white/40">{{ props.placeholder }}</span>
        <span class="pointer-events-none flex items-center pr-1">
          <ChevronDownIcon class="h-4 w-4 text-white/40" aria-hidden="true" />
        </span>
      </ListboxButton>

      <transition
        leave-active-class="transition duration-100 ease-in"
        leave-from-class="opacity-100"
        leave-to-class="opacity-0"
      >
        <ListboxOptions
          class="absolute z-20 mt-1 w-full max-h-60 overflow-auto rounded-lg bg-[#1a1a1a] ring-1 ring-white/10 shadow-xl focus:outline-none py-1"
        >
          <ListboxOption
            v-for="option in props.options"
            :key="option.label"
            v-slot="{ active, selected }"
            :value="option.value"
            as="template"
          >
            <li
              :class="[
                'relative cursor-pointer select-none px-3 py-2 text-sm transition-colors',
                active ? 'bg-white/10 text-white' : 'text-white/80',
              ]"
            >
              <div class="flex items-center justify-between">
                <span :class="[
                  'block truncate',
                  selected ? 'font-medium' : 'font-normal',
                ]">{{ option.label }}</span>
                <CheckIcon
                  v-if="selected"
                  class="h-4 w-4 text-[var(--c-primary-color)]"
                  aria-hidden="true"
                />
              </div>
            </li>
          </ListboxOption>
        </ListboxOptions>
      </transition>

      <div v-if="props.error" class="text-xs text-red-400 mt-1.5">
        {{ props.error }}
      </div>
    </div>
  </Listbox>
</template>
