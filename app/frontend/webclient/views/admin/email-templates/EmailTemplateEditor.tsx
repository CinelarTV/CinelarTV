import { defineComponent, ref, watch, onMounted, onBeforeUnmount, computed, Fragment } from 'vue';
import { useHead } from 'unhead';
import { useRouter, useRoute } from 'vue-router';
import { ajax } from '@/lib/Ajax';
import { useEditor, EditorContent } from '@tiptap/vue-3';
import StarterKit from '@tiptap/starter-kit';
import Link from '@tiptap/extension-link';
import Placeholder from '@tiptap/extension-placeholder';
import { toast } from 'vue-sonner';
import CIcon from '../../../components/c-icon.vue';
import CButton from '../../../components/forms/c-button.tsx';

const LOCALES = [
  { code: 'en', label: 'EN' },
  { code: 'es', label: 'ES' },
  { code: 'pt-BR', label: 'PT-BR' },
];

const TEMPLATE_LABELS: Record<string, string> = {
  devise_confirmation_instructions: 'Confirmación de cuenta',
  devise_reset_password_instructions: 'Recuperación de contraseña',
  devise_unlock_instructions: 'Desbloqueo de cuenta',
  devise_email_changed: 'Cambio de email',
};

const VARIABLE_DESCRIPTIONS: Record<string, string> = {
  username: 'Nombre del usuario',
  email: 'Email del usuario',
  confirmation_url: 'URL de confirmación de cuenta',
  edit_password_url: 'URL para restablecer contraseña',
  unlock_url: 'URL de desbloqueo de cuenta',
  site_name: 'Nombre del sitio',
  site_url: 'URL del sitio',
  new_email: 'Nuevo email del usuario',
};

export default defineComponent({
  name: 'EmailTemplateEditor',
  components: { EditorContent, CIcon, CButton },
  setup() {
    const route = useRoute();
    const router = useRouter();
    const key = route.params.key as string;

    const locale = ref('en');
    const subject = ref('');
    const loading = ref(true);
    const saving = ref(false);
    const hasOverride = ref(false);
    const interpolationVariables = ref<string[]>([]);

    // Preview
    const previewHtml = ref('');
    const previewSubject = ref('');
    const previewLoading = ref(false);
    const previewDevice = ref<'desktop' | 'mobile'>('desktop');

    // Test email modal
    const showTestModal = ref(false);
    const testEmail = ref('');
    const testSending = ref(false);

    const editor = useEditor({
      content: '',
      extensions: [
        StarterKit,
        Link.configure({
          openOnClick: false,
          HTMLAttributes: { class: 'email-editor-link' },
        }),
        Placeholder.configure({
          placeholder: 'Escribe el contenido del email aquí...',
        }),
      ],
      editorProps: {
        attributes: {
          class: 'prose max-w-none',
        },
      },
    });

    const templateLabel = computed(() => TEMPLATE_LABELS[key] || key);

    const fetchTemplate = async () => {
      loading.value = true;
      try {
        const response = await ajax.get(`/admin/email-templates/${key}.json`, {
          params: { locale: locale.value },
        });
        subject.value = response.data.subject;
        editor.value?.commands.setContent(response.data.body);
        hasOverride.value = response.data.has_override;
        interpolationVariables.value = response.data.interpolation_variables;
      } catch (error) {
        console.error('Failed to fetch email template:', error);
        toast.error('Error al cargar la plantilla');
      } finally {
        loading.value = false;
      }
    };

    const handleSave = async () => {
      saving.value = true;
      try {
        await ajax.put(`/admin/email-templates/${key}`, {
          locale: locale.value,
          subject: subject.value,
          body: editor.value?.getHTML(),
        });
        hasOverride.value = true;
        toast.success('Plantilla guardada correctamente');
      } catch (error) {
        console.error('Failed to save email template:', error);
        toast.error('Error al guardar la plantilla');
      } finally {
        saving.value = false;
      }
    };

    const handleRevert = async () => {
      if (!confirm('¿Estás seguro de que deseas revertir a la plantilla por defecto? Se eliminará tu personalización.')) {
        return;
      }
      saving.value = true;
      try {
        await ajax.delete(`/admin/email-templates/${key}`, {
          params: { locale: locale.value },
        });
        hasOverride.value = false;
        await fetchTemplate();
        toast.success('Plantilla revertida a los valores por defecto');
      } catch (error) {
        console.error('Failed to revert email template:', error);
        toast.error('Error al revertir la plantilla');
      } finally {
        saving.value = false;
      }
    };

    const handlePreview = async () => {
      previewLoading.value = true;
      try {
        const response = await ajax.post(`/admin/email-templates/${key}/preview`, {
          locale: locale.value,
          subject: subject.value,
          body: editor.value?.getHTML(),
        });
        previewSubject.value = response.data.subject;
        previewHtml.value = response.data.html;
      } catch (error) {
        console.error('Failed to generate preview:', error);
        toast.error('Error al generar la vista previa');
      } finally {
        previewLoading.value = false;
      }
    };

    const handleTestSend = async () => {
      if (!testEmail.value || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(testEmail.value)) {
        toast.error('Ingresa un email válido');
        return;
      }
      testSending.value = true;
      try {
        await ajax.post(`/admin/email-templates/${key}/test_send`, {
          locale: locale.value,
          subject: subject.value,
          body: editor.value?.getHTML(),
          recipient_email: testEmail.value,
        });
        toast.success(`Email de prueba enviado a ${testEmail.value}`);
        showTestModal.value = false;
        testEmail.value = '';
      } catch (error: any) {
        const msg = error?.response?.data?.error || 'Error al enviar el email de prueba';
        toast.error(msg);
      } finally {
        testSending.value = false;
      }
    };

    const insertVariable = (variable: string) => {
      editor.value?.chain().focus().insertContent(`%{${variable}}`).run();
    };

    // Toolbar actions
    const toggleBold = () => editor.value?.chain().focus().toggleBold().run();
    const toggleItalic = () => editor.value?.chain().focus().toggleItalic().run();
    const toggleStrike = () => editor.value?.chain().focus().toggleStrike().run();
    const toggleH1 = () => editor.value?.chain().focus().toggleHeading({ level: 1 }).run();
    const toggleH2 = () => editor.value?.chain().focus().toggleHeading({ level: 2 }).run();
    const toggleH3 = () => editor.value?.chain().focus().toggleHeading({ level: 3 }).run();
    const toggleBulletList = () => editor.value?.chain().focus().toggleBulletList().run();
    const toggleOrderedList = () => editor.value?.chain().focus().toggleOrderedList().run();
    const toggleBlockquote = () => editor.value?.chain().focus().toggleBlockquote().run();
    const toggleCodeBlock = () => editor.value?.chain().focus().toggleCodeBlock().run();
    const setHorizontalRule = () => editor.value?.chain().focus().setHorizontalRule().run();
    const undo = () => editor.value?.chain().focus().undo().run();
    const redo = () => editor.value?.chain().focus().redo().run();

    const setLink = () => {
      const previousUrl = editor.value?.getAttributes('link').href;
      const url = window.prompt('URL del enlace', previousUrl || 'https://');
      if (url === null) return;
      if (url === '') {
        editor.value?.chain().focus().extendMarkRange('link').unsetLink().run();
        return;
      }
      editor.value?.chain().focus().extendMarkRange('link').setLink({ href: url }).run();
    };

    const isActive = (name: string, attrs?: any) => editor.value?.isActive(name, attrs);

    // Auto-fetch preview on content change (debounced)
    let previewTimeout: ReturnType<typeof setTimeout> | null = null;
    const schedulePreview = () => {
      if (previewTimeout) clearTimeout(previewTimeout);
      previewTimeout = setTimeout(() => {
        if (subject.value || editor.value?.getHTML()) {
          handlePreview();
        }
      }, 800);
    };

    watch(locale, () => {
      fetchTemplate();
    });

    watch([subject, editor], () => {
      schedulePreview();
    }, { deep: true });

    onMounted(() => {
      fetchTemplate();
    });

    onBeforeUnmount(() => {
      if (previewTimeout) clearTimeout(previewTimeout);
      editor.value?.destroy();
    });

    useHead({
      title: computed(() => `Editar ${templateLabel.value} - Admin`),
    });

    return () => (
      <div class="email-editor">
        {/* Hero header */}
        <header class="email-editor__hero">
          <div class="email-editor__hero-top">
            <button
              class="email-editor__back"
              onClick={() => router.push('/admin/email-templates')}
            >
              <CIcon icon="arrow-left" size={16} />
              Volver
            </button>
          </div>
          <div style="display: flex; align-items: 'flex-start'; justify-content: 'space-between'; gap: '12px'; flex-wrap: 'wrap'">
            <div>
              <p class="email-editor__eyebrow">Email Template</p>
              <h1 class="email-editor__title">{templateLabel.value}</h1>
              <p class="email-editor__subtitle">
                Edita el asunto y contenido de este email. Usa las variables de interpolación para personalizar el mensaje.
              </p>
            </div>
            <div class="email-editor__locale-pills">
              {LOCALES.map((l) => (
                <button
                  key={l.code}
                  class={`email-editor__locale-pill ${locale.value === l.code ? 'is-active' : ''}`}
                  onClick={() => locale.value = l.code}
                >
                  {l.label}
                </button>
              ))}
            </div>
          </div>
        </header>

        {loading.value ? (
          <div class="email-editor__card" style="padding: 2rem; text-align: center;">
            <CIcon icon="loader" size={20} class="animate-spin size-8" />
            <p style="color: rgba(255,255,255,0.45); margin: 8px 0 0; font-size: 0.85rem;">
              Cargando plantilla...
            </p>
          </div>
        ) : (
          <Fragment>
            {/* Override banner */}
            {!hasOverride.value && (
              <div class="email-editor__override-banner">
                <CIcon icon="info" size={16} />
                <span>
                  Usando plantilla por defecto del YAML. Guarda para crear una personalización.
                </span>
              </div>
            )}

            {/* Two-column layout */}
            <div class="email-editor__layout">
              {/* Main editor column */}
              <div class="email-editor__main">
                {/* Subject */}
                <div class="email-editor__card">
                  <div class="email-editor__field">
                    <label class="email-editor__field-label">Asunto del email</label>
                    <input
                      type="text"
                      value={subject.value}
                      onInput={(e: any) => subject.value = e.target.value}
                      class="email-editor__input"
                      placeholder="Asunto del email..."
                    />
                  </div>
                </div>

                {/* Rich text editor */}
                <div class="email-editor__card" style="padding: 0; overflow: hidden;">
                  <div class="email-editor__toolbar">
                    <button
                      class={`email-editor__toolbar-btn ${isActive('bold') ? 'is-active' : ''}`}
                      onClick={toggleBold}
                      title="Negrita"
                    >
                      <CIcon icon="bold" size={16} />
                    </button>
                    <button
                      class={`email-editor__toolbar-btn ${isActive('italic') ? 'is-active' : ''}`}
                      onClick={toggleItalic}
                      title="Cursiva"
                    >
                      <CIcon icon="italic" size={16} />
                    </button>
                    <button
                      class={`email-editor__toolbar-btn ${isActive('strike') ? 'is-active' : ''}`}
                      onClick={toggleStrike}
                      title="Tachado"
                    >
                      <CIcon icon="strikethrough" size={16} />
                    </button>

                    <div class="email-editor__toolbar-separator" />

                    <button
                      class={`email-editor__toolbar-btn ${isActive('heading', { level: 1 }) ? 'is-active' : ''}`}
                      onClick={toggleH1}
                      title="Título 1"
                    >
                      <CIcon icon="heading-1" size={16} />
                    </button>
                    <button
                      class={`email-editor__toolbar-btn ${isActive('heading', { level: 2 }) ? 'is-active' : ''}`}
                      onClick={toggleH2}
                      title="Título 2"
                    >
                      <CIcon icon="heading-2" size={16} />
                    </button>
                    <button
                      class={`email-editor__toolbar-btn ${isActive('heading', { level: 3 }) ? 'is-active' : ''}`}
                      onClick={toggleH3}
                      title="Título 3"
                    >
                      <CIcon icon="heading-3" size={16} />
                    </button>

                    <div class="email-editor__toolbar-separator" />

                    <button
                      class={`email-editor__toolbar-btn ${isActive('bulletList') ? 'is-active' : ''}`}
                      onClick={toggleBulletList}
                      title="Lista"
                    >
                      <CIcon icon="list" size={16} />
                    </button>
                    <button
                      class={`email-editor__toolbar-btn ${isActive('orderedList') ? 'is-active' : ''}`}
                      onClick={toggleOrderedList}
                      title="Lista numerada"
                    >
                      <CIcon icon="list-ordered" size={16} />
                    </button>

                    <div class="email-editor__toolbar-separator" />

                    <button
                      class={`email-editor__toolbar-btn ${isActive('blockquote') ? 'is-active' : ''}`}
                      onClick={toggleBlockquote}
                      title="Cita"
                    >
                      <CIcon icon="quote" size={16} />
                    </button>
                    <button
                      class={`email-editor__toolbar-btn ${isActive('codeBlock') ? 'is-active' : ''}`}
                      onClick={toggleCodeBlock}
                      title="Código"
                    >
                      <CIcon icon="code" size={16} />
                    </button>
                    <button
                      class="email-editor__toolbar-btn"
                      onClick={setHorizontalRule}
                      title="Línea horizontal"
                    >
                      <CIcon icon="minus" size={16} />
                    </button>

                    <div class="email-editor__toolbar-separator" />

                    <button
                      class={`email-editor__toolbar-btn ${isActive('link') ? 'is-active' : ''}`}
                      onClick={setLink}
                      title="Enlace"
                    >
                      <CIcon icon="link" size={16} />
                    </button>

                    <div style="flex: 1" />

                    <button
                      class="email-editor__toolbar-btn"
                      onClick={undo}
                      title="Deshacer"
                    >
                      <CIcon icon="undo" size={16} />
                    </button>
                    <button
                      class="email-editor__toolbar-btn"
                      onClick={redo}
                      title="Rehacer"
                    >
                      <CIcon icon="redo" size={16} />
                    </button>
                  </div>
                  <div class="email-editor__content">
                    <EditorContent editor={editor.value} />
                  </div>
                </div>

                {/* Actions */}
                <div class="email-editor__card">
                  <div class="email-editor__actions">
                    <CButton
                      icon="save"
                      loading={saving.value}
                      onClick={handleSave}
                    >
                      Guardar
                    </CButton>
                    <CButton
                      icon="eye"
                      loading={previewLoading.value}
                      onClick={handlePreview}
                    >
                      Vista previa
                    </CButton>
                    <CButton
                      icon="send"
                      onClick={() => showTestModal.value = true}
                    >
                      Enviar prueba
                    </CButton>
                    <div class="email-editor__actions-spacer" />
                    {hasOverride.value && (
                      <CButton
                        icon="rotate-ccw"
                        variant="danger"
                        loading={saving.value}
                        onClick={handleRevert}
                      >
                        Revertir
                      </CButton>
                    )}
                  </div>
                </div>
              </div>

              {/* Sidebar */}
              <div class="email-editor__sidebar">
                {/* Preview */}
                <div class="email-editor__card">
                  <div style="display: flex; align-items: center; justify-content: space-between; gap: 8px;">
                    <h3 class="email-editor__card-title">
                      <CIcon icon="eye" size={16} />
                      Vista previa
                    </h3>
                    <div class="email-editor__preview-toggle">
                      <button
                        class={`email-editor__preview-toggle-btn ${previewDevice.value === 'desktop' ? 'is-active' : ''}`}
                        onClick={() => previewDevice.value = 'desktop'}
                      >
                        <CIcon icon="monitor" size={14} />
                      </button>
                      <button
                        class={`email-editor__preview-toggle-btn ${previewDevice.value === 'mobile' ? 'is-active' : ''}`}
                        onClick={() => previewDevice.value = 'mobile'}
                      >
                        <CIcon icon="smartphone" size={14} />
                      </button>
                    </div>
                  </div>

                  {previewSubject.value && (
                    <div style="padding: 8px 10px; background: rgba(0,0,0,0.2); border-radius: 6px; font-size: 0.78rem;">
                      <span style={{ color: 'rgba(255,255,255,0.45)' }}>Asunto: </span>
                      <span style={{ color: 'rgba(255,255,255,0.85)' }}>{previewSubject.value}</span>
                    </div>
                  )}

                  {previewLoading.value ? (
                    <div style="padding: 2rem; text-align: center;">
                      <CIcon icon="loader" size={18} class="animate-spin" />
                    </div>
                  ) : previewHtml.value ? (
                    <iframe
                      srcDoc={previewHtml.value}
                      class={`email-editor__preview-frame ${previewDevice.value === 'mobile' ? 'is-mobile' : ''}`}
                      style={{ height: '500px' }}
                      title="Vista previa del email"
                    />
                  ) : (
                    <div style="padding: 2rem; text-align: center; color: rgba(255,255,255,0.35); font-size: 0.82rem;">
                      Haz cambios para ver la vista previa
                    </div>
                  )}
                </div>

                {/* Interpolation Variables */}
                <div class="email-editor__card">
                  <h3 class="email-editor__card-title">
                    <CIcon icon="braces" size={16} />
                    Variables
                  </h3>
                  <div class="email-editor__variables">
                    {interpolationVariables.value.map((variable) => (
                      <button
                        key={variable}
                        class="email-editor__variable-chip"
                        onClick={() => insertVariable(variable)}
                        title={VARIABLE_DESCRIPTIONS[variable] || variable}
                      >
                        {`%{${variable}}`}
                      </button>
                    ))}
                  </div>
                  <p style="margin: 0; font-size: 0.73rem; color: rgba(255,255,255,0.35); line-height: 1.4;">
                    Haz clic en una variable para insertarla en el cursor del editor.
                  </p>
                </div>
              </div>
            </div>
          </Fragment>
        )}

        {/* Test Email Modal */}
        {showTestModal.value && (
          <div
            class="email-editor__modal-overlay"
            onClick={(e) => {
              if (e.target === e.currentTarget) showTestModal.value = false;
            }}
          >
            <div class="email-editor__modal">
              <div class="email-editor__modal-header">
                <h3 class="email-editor__modal-title">Enviar email de prueba</h3>
                <button
                  class="email-editor__modal-close"
                  onClick={() => showTestModal.value = false}
                >
                  <CIcon icon="x" size={16} />
                </button>
              </div>
              <div class="email-editor__modal-body">
                <div class="email-editor__field">
                  <label class="email-editor__field-label">Dirección de email</label>
                  <input
                    type="email"
                    value={testEmail.value}
                    onInput={(e: any) => testEmail.value = e.target.value}
                    class="email-editor__input"
                    placeholder="test@ejemplo.com"
                  />
                </div>
                <p style="margin: 0; font-size: 0.78rem; color: rgba(255,255,255,0.4); line-height: 1.4;">
                  Se enviará el email con los datos de prueba actuales a esta dirección.
                </p>
              </div>
              <div class="email-editor__modal-footer">
                <CButton onClick={() => showTestModal.value = false}>
                  Cancelar
                </CButton>
                <CButton
                  icon="send"
                  loading={testSending.value}
                  onClick={handleTestSend}
                >
                  Enviar prueba
                </CButton>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  },
});
