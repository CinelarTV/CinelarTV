<!-- components/PluginOutlet.vue -->
<template>
    <div>
      <component
        v-for="(plugin, index) in getPluginsByName(name)"
        :key="index"
        :is="plugin"
      />
    </div>
  </template>
  
  <script setup>
  import { ref, defineProps, computed } from 'vue';
  import { plugins } from '../lib/componentManager';
  
  const { name } = defineProps(['name']);
  
  const getPluginsByName = computed(() => {
    return plugins.value[name] || [];
  });
  </script>
  