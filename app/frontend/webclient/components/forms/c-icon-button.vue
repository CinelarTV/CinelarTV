<template>
    <button
        class="c-button btn-icon"
        :class="[
            variantClass,
            loading && 'c-button--loading',
        ]"
        :disabled="loading"
        v-bind="$attrs"
        @click="onClick"
    >
        <span v-if="loading" class="c-button__spinner-overlay" aria-hidden="true">
            <CIcon icon="loader" :size="18" class="icon animate-spin" />
        </span>
        <CIcon v-else-if="icon" :icon="icon" :size="18" class="icon" />
    </button>
</template>

<script setup>
import { computed } from 'vue';
import CIcon from '../c-icon.vue';

const props = defineProps({
    icon: { type: String, default: '' },
    variant: { type: String, default: null },
    type: { type: String, default: null },
    loading: { type: Boolean, default: false },
});

const emit = defineEmits(['click']);

const variantClass = computed(() => {
    const v = props.variant || (props.type === 'danger' ? 'danger' : null);
    return v ? `c-button--${v}` : null;
});

const onClick = (e) => {
    if (!props.loading) {
        emit('click', e);
    }
};
</script>
