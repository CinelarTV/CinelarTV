<!-- app/frontend/webclient/components/admin/JsonSchemaEditorModal.vue
     Mirrors Discourse's JsonSchemaEditorModal pattern:
     - Uses @json-editor/json-editor with theme "barebones"
     - Editor mounts when the holder div enters the DOM (onMounted)
     - Editor destroys when the holder div leaves the DOM (onBeforeUnmount)
     - Validates on save, shows errors inline
     - Icon library maps to CIcon names (SVG sprite)
-->
<template>
  <CModal
    :model-value="modelValue"
    @update:model-value="$emit('update:modelValue', $event)"
    :title="settingName"
    size="xl"
    persistent
  >
    <!-- Error flash -->
    <div
      v-if="flash"
      class="mb-4 flex items-start gap-2 rounded-lg bg-red-500/10 border border-red-500/20 px-4 py-3 text-red-400 text-sm"
    >
      <CIcon icon="alertCircle" :size="16" class="mt-0.5 shrink-0" />
      <pre class="whitespace-pre-wrap font-sans m-0">{{ flash }}</pre>
    </div>

    <!-- The editor mounts here. Wrapping in a keyed component ensures
         onMounted/onBeforeUnmount fire correctly when the modal opens/closes. -->
    <JsonEditorHolder
      v-if="modelValue"
      :schema="schema"
      :initial-value="value"
      @ready="onEditorReady"
      @destroy="onEditorDestroy"
    />

    <template #footer>
      <div class="flex items-center justify-end gap-3">
        <CButton variant="ghost" @click="close">Cancelar</CButton>
        <CButton variant="primary" icon="check" @click="saveChanges">Guardar</CButton>
      </div>
    </template>
  </CModal>
</template>

<script setup>
import { ref, computed } from 'vue';
import CModal from '@/components/CModal.vue';
import CButton from '@/components/forms/c-button';
import CIcon from '@/components/c-icon.vue';
import JsonEditorHolder from './JsonEditorHolder.vue';

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  settingKey: { type: String, required: true },
  schema:     { type: Object, required: true },
  value:      { type: String, default: '' },
});

const emit = defineEmits(['update:modelValue', 'save']);

const editorRef = ref(null);   // the JSONEditor instance, passed up from holder
const flash     = ref('');

const settingName = computed(() =>
  props.settingKey.replace(/_/g, ' ')
);

const onEditorReady  = (editor) => { editorRef.value = editor; };
const onEditorDestroy = ()       => { editorRef.value = null;   };

const close = () => {
  flash.value = '';
  emit('update:modelValue', false);
};

const saveChanges = () => {
  flash.value = '';
  if (!editorRef.value) return;

  const errors = editorRef.value.validate();
  if (errors.length) {
    flash.value = errors.map((e) => `• ${e.message}`).join('\n');
    return;
  }

  emit('save', JSON.stringify(editorRef.value.getValue()));
  close();
};
</script>
