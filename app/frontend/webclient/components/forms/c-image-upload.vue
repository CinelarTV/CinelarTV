<template>
  <div class="c-image-upload">
    <!-- Upload area -->
    <div
      v-if="!previewImage"
      class="upload-area"
      :class="{ 'drag-over': isDragOver }"
      @click="triggerFileInput"
      @dragover.prevent="handleDragOver"
      @dragleave.prevent="handleDragLeave"
      @drop.prevent="handleDrop"
    >
      <input
        ref="fileInput"
        type="file"
        class="hidden-input"
        accept="image/*"
        @change="handleFileChange"
      />
      
      <div class="upload-content">
        <div class="upload-icon">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M12 15V3m0 0l-4 4m4-4l4 4M2 17l.621 2.485A2 2 0 004.561 21h14.878a2 2 0 001.94-1.515L22 17"/>
          </svg>
        </div>
        <div class="upload-text">
          <p class="upload-title">Arrastra una imagen aquí</p>
          <p class="upload-subtitle">o haz clic para seleccionar</p>
        </div>
        <div class="upload-hint">
          <p>Formatos: JPG, PNG, GIF, WebP</p>
          <p>Tamaño máximo: 10MB</p>
        </div>
      </div>
    </div>

    <!-- Preview area -->
    <div v-else class="preview-area">
      <div class="preview-image">
        <img :src="previewImage" alt="Preview" />
      </div>
      <div class="preview-actions">
        <button
          type="button"
          class="c-button c-button--danger"
          @click="removeImage"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M3 6h18m-2 0v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2"/>
          </svg>
          Eliminar
        </button>
        <button
          type="button"
          class="c-button"
          @click="triggerFileInput"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4m4-5l5 5 5-5m-5 5V3"/>
          </svg>
          Cambiar
        </button>
      </div>
    </div>

    <!-- Loading overlay -->
    <div v-if="isUploading" class="upload-overlay">
      <div class="loading-spinner">
        <div class="spinner"></div>
        <p>Subiendo imagen...</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue';

const props = defineProps({
  modelValue: [String, File]
});

const emit = defineEmits(['update:modelValue']);

const fileInput = ref(null);
const isDragOver = ref(false);
const isUploading = ref(false);

const isTmdbUrl = computed(() => {
  return typeof props.modelValue === 'string' && props.modelValue?.startsWith('tmdb://');
});

const displaySrc = computed(() => {
  if (!props.modelValue) return null;
  if (props.modelValue instanceof File) return null;
  if (isTmdbUrl.value) {
    const path = props.modelValue.replace('tmdb://', '/');
    return `https://image.tmdb.org/t/p/w500${path}`;
  }
  return props.modelValue;
});

const previewImage = computed(() => {
  if (props.modelValue instanceof File) {
    return URL.createObjectURL(props.modelValue);
  }
  return displaySrc.value;
});

const triggerFileInput = () => {
  fileInput.value?.click();
};

const handleFileChange = (event) => {
  const file = event.target.files[0];
  if (file) {
    processFile(file);
  }
};

const handleDragOver = () => {
  isDragOver.value = true;
};

const handleDragLeave = () => {
  isDragOver.value = false;
};

const handleDrop = (event: DragEvent) => {
  isDragOver.value = false;
  const files = event.dataTransfer?.files;
  if (files && files.length > 0) {
    const file = files[0];
    if (file.type.startsWith('image/')) {
      processFile(file);
    }
  }
};

const processFile = (file) => {
  // Check file size (10MB limit)
  if (file.size > 10 * 1024 * 1024) {
    console.error('El archivo es demasiado grande. Máximo 10MB.');
    return;
  }

  isUploading.value = true;
  
  emit('update:modelValue', file);
  isUploading.value = false;
};

const removeImage = () => {
  emit('update:modelValue', '');
  if (fileInput.value) {
    fileInput.value.value = '';
  }
};
</script>

