<template>
    <span>
        <svg class="icon" :width="size" :height="size">
            <use :xlink:href="`#${icon}`" />
        </svg>
    </span>
</template>
  
<script setup>
const props = defineProps({
    icon: String,
    size: {
        type: [Number, String],
        default: 18,
    },
});
</script>
  