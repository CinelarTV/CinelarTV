<template>
  <div class="c-color-input">
    <div class="c-color-input__swatch" :style="{ background: modelValue }" />
    <c-input type="text" data-coloris :modelValue="modelValue" @update:modelValue="updateColor"
      @change="updateFromEvent" />
  </div>
</template>

<script setup>
const props = defineProps({
  modelValue: {
    type: String,
    default: '#000000'
  }
});

const emit = defineEmits(['update:modelValue']);

const updateColor = (value) => emit('update:modelValue', value);
const updateFromEvent = (event) => emit('update:modelValue', event.target.value);
</script>