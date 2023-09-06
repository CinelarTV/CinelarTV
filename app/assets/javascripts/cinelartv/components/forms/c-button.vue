<template>
    <button class="c-button" :class="{
        'c-button--danger': type === 'danger',
        'c-button--loading': loading,
    }" :disabled="loading" v-bind="$attrs" @click="onClick">
        <span v-if="loading">
            <LoaderIcon :size="18" class="icon loading-request" />
        </span>

        <svg class="icon svg-icon" size="18" v-if="icon && !loading">
            <use :xlink:href="`#${icon}`" />
        </svg>
        <slot />
    </button>
</template>
  
<script setup>
import { LoaderIcon } from 'lucide-vue-next';
import { defineProps, defineEmits } from 'vue'

const props = defineProps({
    onClick: Function,
    type: String, // 'danger' or null
    loading: Boolean, // true or false,
    icon: {
        type: String,
        default: ''
    }
})

const emit = defineEmits(['click'])
const onClick = (e) => {
    if (!props.loading) {
        emit('click', e)
    }
}
</script>