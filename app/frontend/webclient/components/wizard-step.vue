<template>
  <div class="wizard-container__step">
    <div v-if="currentStep">
      <div class="wizard-container__step-counter">
        <div class="wizard-container__step-counter-top">
          <span class="wizard-container__step-text">
            {{ i18n.t('js.wizard.step') }}
          </span>
          <span class="wizard-container__step-count">
            {{ currentStepIndex + 1 }} / {{ props.wizardData.steps.length }}
          </span>
        </div>
        <div class="wizard-container__progress" role="progressbar" aria-valuemin="1"
          :aria-valuemax="props.wizardData.steps.length" :aria-valuenow="currentStepIndex + 1">
          <div class="wizard-container__progress-bar"
            :style="{ width: `${((currentStepIndex + 1) / props.wizardData.steps.length) * 100}%` }"></div>
        </div>
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
            <div class="wizard-container__fields" v-if="step.fields?.length">
              <div v-for="field in step.fields" :key="field.id" class="wizard-container__field">
                <label class="wizard-container__field-label">{{
                  i18n.t(`js.wizard.${currentStep.id}.fields.${field.id}.title`) }}</label>
                <template v-if="field.type === 'checkbox'">
                  <div class="wizard-field-control">
                    <Switch v-model="field.value" :class="[
                      'wizard-switch',
                      field.value ? 'wizard-switch--on' : 'wizard-switch--off',
                    ]">
                      <span aria-hidden="true" :class="[
                        'wizard-switch-thumb',
                        field.value ? 'wizard-switch-thumb--on' : '',
                      ]" />
                    </Switch>
                  </div>
                </template>
                <component v-else :is="getFieldComponent(field)" v-model="field.value" v-bind="getFieldProps(field)" />
              </div>
            </div>
            <div v-else class="wizard-container__step-empty">
              {{ i18n.t(`js.wizard.${currentStep.id}.description`) }}
            </div>
          </div>
        </div>

        <div class="wizard-container__step-footer">
          <div class="wizard-container__buttons">
            <c-button v-if="currentStepIndex > 0" @click="goToPreviousStep" class="wizard-btn wizard-btn--secondary">
              Back
            </c-button>

            <c-button v-if="currentStep.id !== 'ready'" @click="goToNextStep" class="wizard-btn wizard-btn--primary">
              Continue
            </c-button>

            <c-button v-if="currentStep.id === 'ready'" @click="exitFromWizard" class="wizard-btn wizard-btn--primary">
              Exit
            </c-button>
          </div>
        </div>
      </div>
    </div>
    <div v-else class="wizard-container__loading">
      <p>Loading wizard...</p>
    </div>
  </div>
</template>

<script setup>
import {
  ref,
  computed,
  defineProps,
  inject,
} from 'vue';
import { Switch } from '@headlessui/vue';
import CInput from './forms/c-input.vue';
import CSelect from './forms/c-select.vue';
import { useRouter } from 'vue-router';
import twemoji from 'twemoji';
import { toast } from 'vue3-toastify';
import { ajax } from '../lib/Ajax';


const emit = defineEmits(['update:step']);


const props = defineProps(['step', 'wizardData', 'currentStep']);

const router = useRouter();
const i18n = inject('I18n');

const currentStepIndex = ref(props.currentStep.index);
const currentStep = ref(props.currentStep);

const localeOptions = computed(() => {
  const translations = i18n?.translations || {};
  const localeCodes = Object.keys(translations).filter((code) => {
    // Keep only language-like keys to avoid runtime errors with i18n internals.
    return /^[a-z]{2,3}(?:-[a-z0-9]{2,8})*$/i.test(code);
  });

  if (!localeCodes.length) {
    return [
      { label: 'Espanol (es)', value: 'es' },
      { label: 'English (en)', value: 'en' },
    ];
  }

  const displayNames = typeof Intl !== 'undefined' && Intl.DisplayNames
    ? new Intl.DisplayNames([i18n?.locale || 'en'], { type: 'language' })
    : null;

  return localeCodes.map((code) => {
    let languageName = code.toUpperCase();
    if (displayNames) {
      try {
        languageName = displayNames.of(code) || languageName;
      } catch {
        languageName = code.toUpperCase();
      }
    }
    const normalizedName = languageName.charAt(0).toUpperCase() + languageName.slice(1);
    return {
      label: `${normalizedName} (${code})`,
      value: code,
    };
  });
});

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
    case 'select':
      return CSelect;
    case 'checkbox':
      return Switch;
    case 'image':
      return 'ImageFieldComponent';
    default:
      return CInput;
  }
};

const getFieldProps = (field) => {
  if (field.type === 'checkbox') {
    return {
      class: [
        'wizard-switch',
        field.value ? 'wizard-switch--on' : 'wizard-switch--off',
      ]
    };
  }

  if (field.type !== 'select') {
    return {};
  }

  if (field.id === 'default_locale') {
    return {
      options: localeOptions.value,
      placeholder: 'Select language',
    };
  }

  return {
    options: field.options || [],
    placeholder: 'Select option',
  };
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

const goToPreviousStep = () => {
  if (currentStepIndex.value > 0) {
    currentStepIndex.value--;
    emit('update:step', props.wizardData.steps[currentStepIndex.value]);
    currentStep.value = props.wizardData.steps[currentStepIndex.value];
  }
};



</script>
