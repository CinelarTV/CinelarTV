<template>
    <div class="c-image-upload">
      <input type="file" accept="image/*" @change="handleFileChange" />
      <div v-if="hasImage">
        <img v-if="isTmdbUrl" class="h-16" :src="getTmdbImageUrl()" alt="Preview" />
        <img v-else-if="isImageUrl" class="h-16" :src="modelValue" alt="Preview" />
        <img v-else class="h-16" :src="previewImage" alt="Preview" />
      </div>
    </div>
  </template>
  
  <script setup>
  import { ref, computed, watch, defineEmits, defineModel } from 'vue'
  
  const modelValue = ref('')
  const previewImage = ref(null)
  const emit = defineEmits(['update:modelValue'])
  const model = defineModel('modelValue')
  
  const isTmdbUrl = computed(() => modelValue.value.startsWith('tmdb://'))
  const isImageUrl = computed(() => isImageUrlFormat(modelValue.value))
  
  const hasImage = computed(() => modelValue.value || previewImage.value)
  
  const handleFileChange = (event) => {
    const file = event.target.files[0]
    if (file) {
      const reader = new FileReader()
      reader.onload = () => {
        previewImage.value = reader.result
        modelValue.value = ''
        emit('update:modelValue', '')
      }
      reader.readAsDataURL(file)
    } else {
      previewImage.value = null
      modelValue.value = ''
      emit('update:modelValue', '')
    }
  }
  
  const getTmdbImageUrl = () => {
    if (isTmdbUrl.value) {
      const tmdbId = extractTmdbId(modelValue.value)
      return `https://image.tmdb.org/t/p/w780${tmdbId}`
    }
    return ''
  }
  
  const isImageUrlFormat = (value) => {
    // Add your logic here to determine if the value is a valid image URL
    // For example, you can check if it starts with "http://" or "https://"
    return value.startsWith('http://') || value.startsWith('https://')
  }
  
  watch(
    () => model.value,
    (value) => {
      if (value) {
        previewImage.value = null
      }
    }
  )
  
  const extractTmdbId = (tmdbUrl) => {
    return tmdbUrl.replace('tmdb://', '')
  }
  </script>
  
  <style>
  .c-image-upload {
    display: inline-block;
  }
  </style>
  