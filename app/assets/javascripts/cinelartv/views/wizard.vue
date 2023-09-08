<template>
  <div id="wizard-main">
    <div class="c-installer-logo">
      <img src="/assets/default/cinelartv_default_logo.svg" alt="CinelarTV" />
    </div>
    <router-view v-if="currentStep" :id="step" :wizard-data="wizard" :current-step="currentStep"
      @update:step="updateCurrentStep"></router-view>
  </div>
</template>
  
<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router'
import { useHead } from 'unhead'
import { ajax } from '../lib/axios-setup';
const route = useRoute()
const router = useRouter()

const step = route.params.step
document.body.classList.add('wizard')

const updateCurrentStep = (step) => {
  currentStep.value = step
  router.push(`/wizard/steps/${step.id}`)
}

useHead({
  title: 'Wizard',
  meta: [
    { name: 'description', content: 'CinelarTV Wizard' },
    { name: 'robots', content: 'noindex' },
  ],
})

const fetchWizard = async () => {
  try {
    const response = await ajax.get(`/wizard.json`)
    wizard.value = response.data.wizard
    let stepToFind = wizard.value.steps.find(s => s.id === step || 0) || wizard.value.steps[0]
    currentStep.value = stepToFind


    // Redirect to first step if no step is provided
    if (!step) {
      router.push(`/wizard/steps/${wizard.value.steps[0].id}`)
    }
  } catch (error) {

  }
}

const wizard = ref(null)
const currentStep = ref(null)

onMounted(() => {
  fetchWizard()
})


</script>