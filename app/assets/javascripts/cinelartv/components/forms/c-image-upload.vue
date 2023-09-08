<template>
  <div class="c-image-upload relative">
    <div id="uppy-container"></div>
  </div>
</template>

<script setup>
import { ref, defineEmits, defineModel, watch, onMounted } from 'vue';
import Uppy from '@uppy/core';
import Dashboard from '@uppy/dashboard';
import '@uppy/core/dist/style.min.css';
import '@uppy/dashboard/dist/style.min.css';

const emit = defineEmits(['update:modelValue']);

const previewImage = ref(null);
const modelValue = defineModel(() => previewImage.value, (value) => previewImage.value = value);

const handleFileChange = (event) => {
  const file = event.target.files[0];
  if (file) {
    const reader = new FileReader();
    reader.onload = () => {
      previewImage.value = reader.result;
      modelValue.value = '';
      emit('update:modelValue', file);
    };
    reader.readAsDataURL(file);
  } else {
    previewImage.value = null;
    modelValue.value = '';
    emit('update:modelValue', '');
  }
};


onMounted(() => {
  const uppy = new Uppy({
    autoProceed: true,
    restrictions: {
      allowedFileTypes: ['image/*'],
    },
    allowMultipleUploads: false,
  })
    .use(Dashboard, {
      target: '#uppy-container',
      inline: true,
      height: 300,
      width: '100%',
    });

  uppy.on('complete', (result) => {
    if (result.successful.length > 0) {
      // La carga fue exitosa
      const uploadedFile = result.successful[0];      

      emit('update:modelValue', uploadedFile.data);
    } else {
      console.error('Error durante la carga de la imagen.');
    }
  });
});
</script>

<style scoped>
.c-image-upload {
  display: inline-block;
  /* Personaliza los estilos según tus necesidades */
}
</style>
