<template>
    <textarea class="c-input" :value="modelValue" :rows="textareaRows" @input="updateValue"></textarea>
</template>

<script setup>
import { defineProps, defineEmits } from 'vue'
import { ref } from 'vue'

const props = defineProps({
    modelValue: String
})

const emit = defineEmits(['update:modelValue'])

const value = ref(props.modelValue)
const textareaRows = ref(1)

const updateValue = (e) => {
    value.value = e.target.value
    updateTextareaRows(e.target)
    emit('update:modelValue', value.value) // Emit the updated value
}

const updateTextareaRows = (textarea) => {
    const numberOfLines = textarea.value?.split('\n').length
    textareaRows.value = Math.min(10, numberOfLines) // Limit to a maximum of 10 rows
}

updateTextareaRows(value.value) // Set initial rows based on the initial value
</script>
