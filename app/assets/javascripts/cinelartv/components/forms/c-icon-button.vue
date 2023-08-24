<template>
    <button class="c-button btn-icon" :class="{
        'c-button--danger': type === 'danger',
        'c-button--loading': loading,
    }" :disabled="loading" v-bind="$attrs" @click="onClick">
        <span v-if="loading">
            <LoaderIcon :size="18" class="icon loading-request" />
        </span>
        <component :is="icon" v-if="!loading" class="icon" :size="18" />
    </button>
</template>
  
<script setup>
import { LoaderIcon } from 'lucide-vue-next';
import { defineProps, defineEmits } from 'vue';

const props = defineProps({
    onClick: Function,
    type: String, // 'danger' or null
    loading: Boolean, // true or false,
    icon: null,
});

const emit = defineEmits(['click']);
const onClick = (e) => {
    if (!props.loading) {
        emit('click', e);
    }
};
</script>