<template>
    <svg class="icon" :class="attrs.class" :width="size" :height="size" v-bind="attrsWithoutClass">
        <use :xlink:href="`#${icon}`" />
    </svg>
</template>

<script setup>
import { useAttrs, computed } from 'vue';

defineOptions({
    inheritAttrs: false,
});

const props = defineProps({
    icon: String,
    size: {
        type: [Number, String],
        default: 18,
    },
});

const attrs = useAttrs();

const attrsWithoutClass = computed(() => {
    const { class: _class, ...rest } = attrs;
    return rest;
});
</script>