<template>
  <div class="wizard-container__step">
    <div v-if="currentStep">
      <div class="wizard-container__step-counter">
        <span class="wizard-container__step-text">
          {{ i18n.t('js.wizard.step') }}
        </span>
        <span class="wizard-container__step-count">
          {{ currentStepIndex + 1 }} / {{ props.wizardData.steps.length }}
        </span>
      </div>

      <div class="wizard-container">
        <div class="wizard-container__step-contents">

          <div class="wizard-container__step-header">
            <div class="wizard-container__step-header--emoji">
              <h1 v-html="emojiParse(currentStep.emoji)"></h1>
            </div>
            <h1 class="wizard-container__step-title" v-emoji v-html="i18n.t(`js.wizard.${currentStep.id}.title`)"></h1>
            <p class="wizard-container__step-description" v-emoji
              v-html="i18n.t(`js.wizard.${currentStep.id}.description`)"></p>
          </div>

          <div v-for="step in props.wizardData.steps" :key="step.id" :class="{ hidden: currentStep.id !== step.id }">
            <div v-for="field in step.fields" :key="field.id">
              <label>{{ field.id }}</label>
              <component :is="getFieldComponent(field)" v-model="field.value" />
            </div>
          </div>
        </div>

        <div class="wizard-container__step-footer">
          <div class="wizard-container__buttons">
            <c-button @click="goToNextStep" class="bg-blue-500 text-white px-4 py-2 rounded">
              Next
            </c-button>


            <c-button v-if="currentStep.id === 'ready'" @click="exitFromWizard"
              class="bg-blue-500 text-white px-4 py-2 rounded">
              Exit
            </c-button>
          </div>
        </div>
      </div>
    </div>
    <div v-else>
      <p>Loading...</p>
    </div>
  </div>
</template>
  
<script setup>
import {
  ref,
  onMounted,
  watch,
  getCurrentInstance,
  defineProps,
  inject,
} from 'vue';
import CInput from './forms/c-input.vue';
import { useRouter } from 'vue-router';
import twemoji from 'twemoji';
import { toast } from 'vue3-toastify';
import { ajax } from '../lib/axios-setup';


const emit = defineEmits(['update:step']);


const props = defineProps(['step', 'wizardData', 'currentStep']);

const router = useRouter();
const i18n = inject('I18n');

const currentStepIndex = ref(props.currentStep.index);
const currentStep = ref(props.currentStep);

const emojiParse = (emoji) => {
  if (!emoji) return '';
  return twemoji.parse(emoji, {
    folder: 'svg',
    ext: '.svg',
  });
};

const getFieldComponent = (field) => {
  switch (field.type) {
    case 'text':
      return CInput;
    case 'image':
      return 'ImageFieldComponent';
    default:
      return 'DefaultFieldComponent';
  }
};

const exitFromWizard = async () => {
  await saveChanges(props.currentStep.fields); // Send a request to check wizard_completed as true
  location.href = '/'; // We need to do a full reload to avoid problems with the Vue Router and new SiteSettings
};

const saveChanges = async (fields) => {
  try {
    const data = new FormData();

    fields.forEach((field) => {
      data.append(`fields[${field.id}]`, field.value);
    });

    if (props.currentStep.id === 'introduction' || props.currentStep.id === 'ready') {
      data.append('fields[step]', 'ok'); // Introduction don't have a field, so we need to add a field to save the step successfully
    }

    const response = await ajax.put(`/wizard/steps/${props.currentStep.id}.json`, data);

    if (response.status === 422) {
      throw new Error(response.data);
    }

    console.log('Guardando cambios', { fields });
  } catch (error) {
    let message = 'Error al guardar los cambios';
    console.log(error.errors);
    if (error.errors) {
      message = error.errors.map((e) => e.description).join(', ');
    }
    throw new Error(message); // Lanza una excepción para manejarla en goToNextStep
  }
};

const goToNextStep = async () => {
  try {
    await saveChanges(props.currentStep.fields);

    if (currentStepIndex.value < props.wizardData.steps.length - 1) {
      currentStepIndex.value++;
    }
    // Emit event to parent component, to next step
    emit('update:step', props.wizardData.steps[currentStepIndex.value]);
    currentStep.value = props.wizardData.steps[currentStepIndex.value];
  } catch (error) {
    toast.error(error.message); // Muestra el mensaje de error específico
  }
};



</script>
  