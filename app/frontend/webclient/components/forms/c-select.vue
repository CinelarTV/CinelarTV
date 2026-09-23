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
    <div class="c-select">
      <ListboxButton class="c-select__trigger">
        <span v-if="label" class="c-select__label">{{ label }}</span>
        <span v-else class="c-select__placeholder">{{ props.placeholder }}</span>
        <span class="c-select__chevron">
          <ChevronDownIcon class="c-select__chevron-icon" aria-hidden="true" />
        </span>
      </ListboxButton>

      <transition
        leave-active-class="c-select__transition-leave"
        leave-from-class="c-select__transition-leave-from"
        leave-to-class="c-select__transition-leave-to"
      >
        <ListboxOptions class="c-select__dropdown">
          <ListboxOption
            v-for="option in props.options"
            :key="option.label"
            v-slot="{ active, selected }"
            :value="option.value"
            as="template"
          >
            <li
              :class="[
                'c-select__option',
                active && 'c-select__option--active',
              ]"
            >
              <div class="c-select__option-content">
                <span :class="[
                  'c-select__option-text',
                  selected && 'c-select__option-text--selected',
                ]">{{ option.label }}</span>
                <CheckIcon
                  v-if="selected"
                  class="c-select__option-check"
                  aria-hidden="true"
                />
              </div>
            </li>
          </ListboxOption>
        </ListboxOptions>
      </transition>

      <div v-if="props.error" class="c-select__error">
        {{ props.error }}
      </div>
    </div>
  </Listbox>
</template>
