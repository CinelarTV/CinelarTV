<template>
    <div class="wizard-container__step">
        <div v-if="wizard">
            <div class="wizard-container__step-counter">
                <span class="wizard-container__step-text">
                    {{ i18n.t('js.wizard.step') }}
                </span>
                <span class="wizard-container__step-count">
                    {{ currentStepIndex + 1 }} / {{ wizard.steps.length }}
                </span>
            </div>

            <div class="wizard-container">
                <div class="wizard-container__step-contents">
                    <h1 v-emoji>
                        {{ currentStep }}
                    </h1>
                    <h1>
                        {{ i18n.t(`js.wizard.${currentStep.id}.title`) }}
                    </h1>

                    <div v-for="step in wizard.steps" :key="step.id" :class="{ hidden: currentStep.id !== step.id }">
                        <h2>{{ step.id }}</h2>
                        <div v-for="field in step.fields" :key="field.id">
                            <label>{{ field.id }}</label>
                            <component :is="getFieldComponent(field)" v-model="field.value" />
                        </div>
                    </div>
                </div>

                <div class="wizard-container__step-footer">
                    <div class="wizard-container__buttons">
                        <button @click="goToNextStep" class="bg-blue-500 text-white px-4 py-2 rounded">Next</button>

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
import axios from 'axios';
import { ref, onMounted, watch, computed, inject, getCurrentInstance } from 'vue';
import CInput from './forms/c-input.vue';
import { useRoute, useRouter } from 'vue-router';

const SiteSettings = inject('SiteSettings');
const currentUser = inject('currentUser');
const i18n = inject('I18n');

const route = useRoute();
const router = useRouter();
const { $http } = getCurrentInstance().appContext.config.globalProperties;

const id = ref(route.params.step);
const wizard = ref(null);
const currentStepIndex = ref(0);

const fetchData = async () => {
    const response = await axios.get(`/wizard/steps/${id.value}.json`);
    wizard.value = response.data.wizard;
};

const currentStep = ref(null);


const goToNextStep = () => {
    // Guardar los cambios antes de avanzar
    saveChanges(currentStep.value.fields);

    if (currentStepIndex.value < wizard.value.steps.length - 1) {
        currentStepIndex.value++;
    }
};

const getFieldComponent = (field) => {
    // Devuelve el nombre del componente basado en el tipo de campo
    switch (field.type) {
        case 'text':
            return CInput;
        case 'image':
            return 'ImageFieldComponent';
        // Agregar más casos según los tipos de campos que tengas
        default:
            return 'DefaultFieldComponent';
    }
};

const saveChanges = async (fields) => {
    // Guardar los cambios en el servidor
    await $http.put(`/wizard/steps/${id.value}.json`, { fields });
    console.log('Guardando cambios', { fields });
};

onMounted(async () => {
    await fetchData();
});


watch([() => wizard.value, currentStepIndex], () => {
    console.log('Wizard:', wizard.value);
    console.log('Current Step Index:', currentStepIndex.value);
    if (wizard.value) {
        const updatedStep = wizard.value.steps[currentStepIndex.value];
        currentStep.value = Object.assign({}, updatedStep); // Create a new object to trigger reactivity
        console.log('Updated currentStep:', currentStep.value);
        // Set the route param to the current step id
        router.push({ params: { step: currentStep.value.id } });
        // Update current step
    } else {
        currentStep.value = null;
        console.log('Updated currentStep to null');
    }
});

</script>
  