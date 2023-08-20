<template>
    <input class="c-input" v-bind="$attrs" @input="updateValue" />
  </template>
  <script setup>
    import { ref, watch } from 'vue'
    const props = defineProps(['modelValue'])
    const emit = defineEmits(['update:modelValue'])
    const value = ref(props.modelValue)
    watch(value, (newValue) => {
      emit('update:modelValue', newValue)
    })
    const updateValue = (e) => {
      value.value = e.target.value
    }
  </script>