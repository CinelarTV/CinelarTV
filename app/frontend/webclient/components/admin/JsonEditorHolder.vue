<!-- app/frontend/webclient/components/admin/JsonEditorHolder.vue
     Thin mount point for @json-editor/json-editor.
     Equivalent to Ember's {{didInsert}} / {{willDestroy}} pattern.
     The parent (JsonSchemaEditorModal) receives the editor instance via @ready.
-->
<template>
  <div ref="holderRef" class="json-editor-holder" />
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue';

const props = defineProps({
  schema:       { type: Object, required: true },
  initialValue: { type: String, default: '' },
});

const emit = defineEmits(['ready', 'destroy']);

const holderRef = ref(null);
let editor      = null;

// ── Icon library that uses the project's existing SVG sprite ──────────────
class CinelarIconLib {
  constructor() {
    this.mapping = {
      delete:    'trash2',
      add:       'plus',
      moveup:    'arrowUp',
      movedown:  'arrowDown',
      moveleft:  'chevronLeft',
      moveright: 'chevronRight',
      copy:      'copy',
      collapse:  'chevronDown',
      expand:    'chevronUp',
    };
  }

  getIcon(key) {
    const name = this.mapping[key];
    if (!name) return null;

    // Create an SVG <use> element pointing to the sprite — same as c-icon.vue
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('width', '14');
    svg.setAttribute('height', '14');
    svg.setAttribute('aria-hidden', 'true');
    svg.classList.add('icon');

    const use = document.createElementNS('http://www.w3.org/2000/svg', 'use');
    use.setAttribute('href', `#${name}`);
    svg.appendChild(use);
    return svg;
  }
}

const parseInitialValue = () => {
  const raw = props.initialValue?.trim();
  if (!raw || raw === '""' || raw === 'null') return null;
  try { return JSON.parse(raw); } catch { return null; }
};

onMounted(async () => {
  const { JSONEditor } = await import('@json-editor/json-editor');

  // Mirror Discourse's configuration exactly
  JSONEditor.defaults.options.theme   = 'barebones';
  JSONEditor.defaults.iconlibs        = { cinelarIcons: CinelarIconLib };
  JSONEditor.defaults.options.iconlib = 'cinelarIcons';

  // Don't sanitize string values (theme settings can contain HTML)
  JSONEditor.AbstractEditor.prototype.purify = (value) => value;

  editor = new JSONEditor(holderRef.value, {
    schema:                       props.schema,
    disable_array_delete_all_rows: true,
    disable_array_delete_last_row: true,
    disable_array_reorder:         false,
    disable_array_copy:            false,
    enable_array_copy:             true,
    disable_edit_json:             true,
    disable_properties:            true,
    disable_collapse:              false,
    show_errors:                   'never',
    startval:                      parseInitialValue(),
  });

  emit('ready', editor);
});

onBeforeUnmount(() => {
  editor?.destroy();
  editor = null;
  emit('destroy');
});
</script>

<style>
/*
  Style the native HTML elements that @json-editor/json-editor (barebones theme)
  generates so they match the project's c-input / c-select / c-button tokens
  exactly. This is the same approach Discourse uses.
*/

/* ── Text / number / url inputs → .c-input ─────────────────────────────── */
.json-editor-holder input[type="text"],
.json-editor-holder input[type="number"],
.json-editor-holder input[type="url"],
.json-editor-holder input[type="email"],
.json-editor-holder textarea {
  display: block;
  width: 100%;
  padding: 10px 14px;
  font-size: 0.9rem;
  line-height: 1.5;
  color: var(--c-text-primary);
  background: var(--c-surface-1);
  border: 1px solid var(--c-border-default);
  border-radius: var(--c-radius-md);
  outline: none;
  box-sizing: border-box;
  font-family: inherit;
  transition: border-color 0.2s ease, background 0.2s ease, box-shadow 0.2s ease;
}

.json-editor-holder input[type="text"]::placeholder,
.json-editor-holder input[type="number"]::placeholder,
.json-editor-holder input[type="url"]::placeholder,
.json-editor-holder textarea::placeholder {
  color: var(--c-text-faint);
}

.json-editor-holder input[type="text"]:hover,
.json-editor-holder input[type="number"]:hover,
.json-editor-holder input[type="url"]:hover,
.json-editor-holder textarea:hover {
  border-color: var(--c-border-strong);
  background: var(--c-surface-2);
}

.json-editor-holder input[type="text"]:focus,
.json-editor-holder input[type="number"]:focus,
.json-editor-holder input[type="url"]:focus,
.json-editor-holder textarea:focus {
  border-color: var(--c-tertiary-color);
  background: var(--c-surface-2);
  box-shadow: 0 0 0 3px rgba(var(--c-tertiary-color-rgb), 0.12);
}

/* ── Select → mimics .c-select__trigger ────────────────────────────────── */
.json-editor-holder select {
  display: block;
  width: 100%;
  padding: 10px 32px 10px 14px;
  font-size: 0.9rem;
  line-height: 1.5;
  color: var(--c-text-primary);
  background-color: var(--c-surface-elevated, rgb(30, 30, 36));
  border: 1px solid var(--c-border-default);
  border-radius: var(--c-radius-md);
  outline: none;
  cursor: pointer;
  appearance: none;
  box-sizing: border-box;
  font-family: inherit;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='rgba(255,255,255,0.4)' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='6 9 12 15 18 9'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 12px center;
  transition: border-color 0.2s ease, background-color 0.2s ease;
}

.json-editor-holder select:hover {
  border-color: var(--c-border-strong);
  background-color: var(--c-surface-elevated, rgb(30, 30, 36));
  filter: brightness(1.08);
}

.json-editor-holder select:focus {
  border-color: var(--c-tertiary-color);
  background-color: var(--c-surface-elevated, rgb(30, 30, 36));
  box-shadow: 0 0 0 3px rgba(var(--c-tertiary-color-rgb), 0.12);
}

/* <option> elements cannot use rgba/transparent backgrounds — must be solid */
.json-editor-holder select option {
  background-color: var(--c-surface-elevated, rgb(30, 30, 36));
  color: var(--c-text-primary, rgba(255, 255, 255, 0.92));
}

.json-editor-holder select option:disabled {
  color: var(--c-text-faint, rgba(255, 255, 255, 0.35));
}

/* ── Checkbox ────────────────────────────────────────────────────────────── */
.json-editor-holder input[type="checkbox"] {
  width: 16px;
  height: 16px;
  accent-color: var(--c-tertiary-color, #0084f0);
  cursor: pointer;
  flex-shrink: 0;
}

/* ── Labels ──────────────────────────────────────────────────────────────── */
.json-editor-holder label {
  display: block;
  font-size: 0.75rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--c-text-muted, rgba(255,255,255,0.45));
  margin-bottom: 4px;
}

/* ── Section headings (array item titles) ────────────────────────────────── */
.json-editor-holder h3 {
  font-size: 0.8rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.6);
  text-transform: uppercase;
  letter-spacing: 0.06em;
  margin: 1rem 0 0.5rem;
}

/* ── Buttons ─────────────────────────────────────────────────────────────── */
.json-editor-holder button {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 6px 12px;
  border-radius: var(--c-radius-md);
  border: 1px solid var(--c-border-default);
  background: var(--c-surface-1);
  color: var(--c-text-secondary, rgba(255,255,255,0.6));
  font-size: 0.8rem;
  font-weight: 500;
  font-family: inherit;
  cursor: pointer;
  transition: background 0.15s, color 0.15s, border-color 0.15s;
}

.json-editor-holder button:hover {
  background: var(--c-surface-2);
  color: var(--c-text-primary);
  border-color: var(--c-border-strong);
}

/* Add button — accent colour */
.json-editor-holder .json-editor-btn-add {
  color: var(--c-tertiary-400, #0084f0);
  border-color: rgba(var(--c-tertiary-color-rgb, 0,132,240), 0.3);
  background: rgba(var(--c-tertiary-color-rgb, 0,132,240), 0.06);
}
.json-editor-holder .json-editor-btn-add:hover {
  background: rgba(var(--c-tertiary-color-rgb, 0,132,240), 0.14);
}

/* Delete button — red tint */
.json-editor-holder .json-editor-btn-delete {
  color: rgba(239, 68, 68, 0.75);
  border-color: rgba(239, 68, 68, 0.2);
  background: rgba(239, 68, 68, 0.05);
}
.json-editor-holder .json-editor-btn-delete:hover {
  background: rgba(239, 68, 68, 0.12);
  color: #f87171;
}

/* ── Button group layout ─────────────────────────────────────────────────── */
.json-editor-holder .btn-group {
  display: flex;
  gap: 4px;
  margin-top: 6px;
  flex-wrap: wrap;
}

/* ── Array item container ────────────────────────────────────────────────── */
.json-editor-holder .je-object__container {
  padding: 0.875rem;
  margin-bottom: 0.5rem;
  border-radius: var(--c-radius-lg, 10px);
  border: 1px solid var(--c-border-subtle, rgba(255,255,255,0.07));
  background: var(--c-surface-0, rgba(255,255,255,0.02));
}

/* ── Indentation ─────────────────────────────────────────────────────────── */
.json-editor-holder .je-indented-panel {
  margin-left: 1rem;
  padding-left: 1rem;
  border-left: 1px solid var(--c-border-subtle, rgba(255,255,255,0.07));
}

/* ── Field row spacing ───────────────────────────────────────────────────── */
.json-editor-holder .form-group {
  margin-bottom: 0.75rem;
}

/* ── SVG icons inside buttons ────────────────────────────────────────────── */
.json-editor-holder button svg.icon {
  opacity: 0.8;
  flex-shrink: 0;
}
</style>
