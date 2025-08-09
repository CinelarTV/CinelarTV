<template>
  <input class="c-input" v-bind="$attrs" :value="modelValue" @input="updateValue($event.target.value)" />
</template>

<script setup>
import { defineProps, defineEmits } from 'vue'

const props = defineProps({
  modelValue: String,
  placeholder: {
    type: String,
    required: false
  }
})

const emit = defineEmits(['update:modelValue'])

const updateValue = (value) => {
  emit('update:modelValue', value)
}
</script>
