<script setup>
import {computed} from "vue";
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
    default: "Select option",
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
  <Listbox
    :model-value="props.modelValue"
    :multiple="props.multiple"
    @update:modelValue="value => emit('update:modelValue', value)"
  >
    <div class="relative mt-1">
      <ListboxButton
        class="c-input select"
      >
        <span
          v-if="label"
          class="block truncate"
          >{{ label }}</span
        >
        <span
          v-else
          >{{ props.placeholder }}</span
        >
        <span
          class="flex absolute inset-y-0 right-0 items-center pr-2 pointer-events-none"
        >
          <ChevronDownIcon
            aria-hidden="true"
          />
        </span>
      </ListboxButton>
 
      <transition
        leave-active-class="transition duration-100 ease-in"
        leave-from-class="opacity-100"
        leave-to-class="opacity-0"
      >
        <ListboxOptions
          class="overflow-auto absolute z-10 py-1 mt-1 w-full max-h-60 text-base bg-[var(--c-primary-50)] ring-1 ring-black ring-opacity-5 shadow-lg focus:outline-none sm:text-sm"
        >
          <ListboxOption
            v-for="option in props.options"
            :key="option.label"
            v-slot="{active, selected}"
            :value="option.value"
            as="template"
          >
            <li
              :class="[
                'relative cursor-pointer hover:bg-[--c-primary-200] select-none py-2 pl-10 pr-4',
              ]"
            >
              <span
                :class="[
                  selected ? 'font-medium' : 'font-normal',
                  'block truncate',
                ]"
                >{{ option.label }}</span
              >
              <span
                v-if="selected"
                class="flex absolute inset-y-0 left-0 items-center pl-3"
              >
                <CheckIcon
                  aria-hidden="true"
                  class="w-5 h-5"
                />
              </span>
            </li>
          </ListboxOption>
        </ListboxOptions>
      </transition>
      <div class="text-xs text-red-400 mt-1" v-if="props.error">{{ props.error }}</div>
    </div>
  </Listbox>
</template>