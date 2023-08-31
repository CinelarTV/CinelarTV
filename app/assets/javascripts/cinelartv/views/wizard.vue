<template>
  <div id="wizard-main">
    <div class="c-installer-logo">
      <img src="/assets/default/cinelartv_default_logo.svg" alt="CinelarTV" />
    </div>
    <router-view :id="step" />
  </div>
</template>
  
<script setup>

import { useRoute } from 'vue-router'
const route = useRoute()

const step = route.params.step
document.body.classList.add('wizard')


</script>