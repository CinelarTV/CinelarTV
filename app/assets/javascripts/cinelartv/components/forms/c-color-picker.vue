<template>
    <div>
      <c-input ref="colorPickerInput" type="text" :value="selectedColor" @input="updateColor" data-coloris />
      <div ref="colorPicker"></div>
    </div>
  </template>
    
  <script setup>
  import { ref, onMounted, onBeforeUnmount, defineProps, defineEmits } from 'vue';
  import Coloris from '@melloware/coloris';
  
  const props = defineProps({
    selectedColor: String,
  });
  
  const emits = defineEmits(['update:selectedColor']);
  
  const colorPicker = ref(null);
  const selectedColor = ref(props.selectedColor || '#000000');
  const colorPickerInput = ref(null);
  
  // Inicializa el selector de color de Coloris al montar el componente
  onMounted(() => {
    colorPicker.value = new Coloris(colorPicker.value, {
      color: selectedColor.value,
      onChange: (color) => {
        selectedColor.value = color;
        emits('update:selectedColor', color); // Emitir el color seleccionado
        updateColor();
      },
    });
  });
  
  // Actualiza el color seleccionado cuando el usuario ingresa un valor manualmente
  const updateColor = () => {
    const newColor = colorPickerInput.value;
    emits('update:selectedColor', newColor); // Emitir el color seleccionado
  };
  
  // Limpia el selector de color antes de destruir el componente
  onBeforeUnmount(() => {
    colorPicker.value.destroy();
  });
  </script>
  