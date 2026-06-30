import { defineComponent, ref, onMounted, computed } from 'vue';
import { useHead } from 'unhead';
import { ajax } from '@/lib/Ajax';
import { toast } from 'vue-sonner';
import CIcon from '../../../components/c-icon.vue';
import CButton from '../../../components/forms/c-button.tsx';

export default defineComponent({
  name: 'EmailStyleEditor',
  components: { CIcon, CButton },
  setup() {
    const loading = ref(true);
    const saving = ref(false);
    const activeTab = ref<'html' | 'css'>('html');
    const html = ref('');
    const css = ref('');
    const defaultHtml = ref('');
    const defaultCss = ref('');

    // Preview
    const previewHtml = ref('');
    const previewLoading = ref(false);
    const previewDevice = ref<'desktop' | 'mobile'>('desktop');

    useHead({ title: 'Email Style - Admin' });

    const hasChanges = computed(() => {
      return html.value !== defaultHtml.value || css.value !== defaultCss.value;
    });

    const fetchStyle = async () => {
      loading.value = true;
      try {
        const response = await ajax.get('/admin/customize/email-style.json');
        html.value = response.data.html;
        css.value = response.data.css;
        defaultHtml.value = response.data.default_html;
        defaultCss.value = response.data.default_css;
      } catch (error) {
        console.error('Failed to fetch email style:', error);
        toast.error('Failed to load email style');
      } finally {
        loading.value = false;
      }
    };

    const handleSave = async () => {
      saving.value = true;
      try {
        await ajax.put('/admin/customize/email-style.json', {
          email_style: {
            html: html.value,
            css: css.value,
          },
        });
        toast.success('Email style saved successfully');
      } catch (error) {
        console.error('Failed to save email style:', error);
        toast.error('Failed to save email style');
      } finally {
        saving.value = false;
      }
    };

    const handleRevertHtml = async () => {
      saving.value = true;
      try {
        await ajax.put('/admin/customize/email-style.json', {
          email_style: { html: defaultHtml.value },
        });
        html.value = defaultHtml.value;
        toast.success('HTML template reverted to default');
      } catch (error) {
        console.error('Failed to revert HTML:', error);
        toast.error('Failed to revert HTML template');
      } finally {
        saving.value = false;
      }
    };

    const handleRevertCss = async () => {
      saving.value = true;
      try {
        await ajax.put('/admin/customize/email-style.json', {
          email_style: { css: defaultCss.value },
        });
        css.value = defaultCss.value;
        toast.success('CSS reverted to default');
      } catch (error) {
        console.error('Failed to revert CSS:', error);
        toast.error('Failed to revert CSS');
      } finally {
        saving.value = false;
      }
    };

    const handlePreview = async () => {
      previewLoading.value = true;
      try {
        const response = await ajax.post('/admin/email-templates/devise_confirmation_instructions/preview', {
          locale: 'en',
        });
        previewHtml.value = response.data.html;
      } catch (error) {
        console.error('Failed to generate preview:', error);
        toast.error('Failed to generate preview');
      } finally {
        previewLoading.value = false;
      }
    };

    const isDefaultHtml = computed(() => html.value === defaultHtml.value);
    const isDefaultCss = computed(() => css.value === defaultCss.value);

    onMounted(() => {
      fetchStyle();
    });

    return {
      loading,
      saving,
      activeTab,
      html,
      css,
      defaultHtml,
      defaultCss,
      previewHtml,
      previewLoading,
      previewDevice,
      hasChanges,
      isDefaultHtml,
      isDefaultCss,
      handleSave,
      handleRevertHtml,
      handleRevertCss,
      handlePreview,
    };
  },
  render() {
    if (this.loading) {
      return (
        <div class="email-style-editor__loading">
          <CIcon icon="loader" size={32} />
          <p>Loading email style...</p>
        </div>
      );
    }

    return (
      <div class="email-style-editor">
        <div class="email-style-editor__header">
          <h1 class="email-style-editor__title">
            <CIcon icon="mail" size={24} />
            Email Style
          </h1>
          <p class="email-style-editor__subtitle">
            Customize the outer HTML template and CSS for all emails
          </p>
        </div>

        <div class="email-style-editor__layout">
          {/* Editor */}
          <div class="email-style-editor__main">
            {/* Tabs */}
            <div class="email-style-editor__tabs">
              <button
                class={`email-style-editor__tab ${this.activeTab === 'html' ? 'is-active' : ''}`}
                onClick={() => this.activeTab = 'html'}
              >
                <CIcon icon="code" size={16} />
                HTML Template
              </button>
              <button
                class={`email-style-editor__tab ${this.activeTab === 'css' ? 'is-active' : ''}`}
                onClick={() => this.activeTab = 'css'}
              >
                <CIcon icon="palette" size={16} />
                CSS
              </button>
            </div>

            {/* HTML Editor */}
            {this.activeTab === 'html' && (
              <div class="email-style-editor__card">
                <div class="email-style-editor__card-header">
                  <h3 class="email-style-editor__card-title">HTML Template</h3>
                  {!this.isDefaultHtml && (
                    <CButton
                      icon="rotate-ccw"
                      variant="danger"
                      size="small"
                      loading={this.saving}
                      onClick={this.handleRevertHtml}
                    >
                      Revert to Default
                    </CButton>
                  )}
                </div>
                <p class="email-style-editor__help">
                  Use <code>%{'{email_content}'}</code> as placeholder for the email body.
                  Other placeholders: <code>%{'{email_preview}'}</code>, <code>%{'{html_lang}'}</code>,
                  <code>%{'{dark_mode_meta_tags}'}</code>, <code>%{'{dark_mode_styles}'}</code>.
                </p>
                <textarea
                  class="email-style-editor__textarea"
                  v-model={this.html}
                  spellcheck={false}
                  rows={25}
                />
              </div>
            )}

            {/* CSS Editor */}
            {this.activeTab === 'css' && (
              <div class="email-style-editor__card">
                <div class="email-style-editor__card-header">
                  <h3 class="email-style-editor__card-title">Custom CSS</h3>
                  {!this.isDefaultCss && (
                    <CButton
                      icon="rotate-ccw"
                      variant="danger"
                      size="small"
                      loading={this.saving}
                      onClick={this.handleRevertCss}
                    >
                      Revert to Default
                    </CButton>
                  )}
                </div>
                <p class="email-style-editor__help">
                  CSS rules will be converted to inline styles at send time for email client compatibility.
                </p>
                <textarea
                  class="email-style-editor__textarea"
                  v-model={this.css}
                  spellcheck={false}
                  rows={20}
                  placeholder="/* Add custom CSS here */"
                />
              </div>
            )}

            {/* Actions */}
            <div class="email-style-editor__actions">
              <CButton
                icon="save"
                loading={this.saving}
                onClick={this.handleSave}
              >
                Save
              </CButton>
              <CButton
                icon="eye"
                loading={this.previewLoading}
                onClick={this.handlePreview}
              >
                Preview
              </CButton>
            </div>
          </div>

          {/* Sidebar - Preview */}
          <div class="email-style-editor__sidebar">
            <div class="email-style-editor__card">
              <div class="email-style-editor__card-header">
                <h3 class="email-style-editor__card-title">
                  <CIcon icon="eye" size={16} />
                  Preview
                </h3>
                <div class="email-style-editor__preview-toggle">
                  <button
                    class={`email-style-editor__preview-toggle-btn ${this.previewDevice === 'desktop' ? 'is-active' : ''}`}
                    onClick={() => this.previewDevice = 'desktop'}
                  >
                    <CIcon icon="monitor" size={14} />
                  </button>
                  <button
                    class={`email-style-editor__preview-toggle-btn ${this.previewDevice === 'mobile' ? 'is-active' : ''}`}
                    onClick={() => this.previewDevice = 'mobile'}
                  >
                    <CIcon icon="smartphone" size={14} />
                  </button>
                </div>
              </div>
              <div class="email-style-editor__preview-container">
                {this.previewHtml ? (
                  <iframe
                    srcdoc={this.previewHtml}
                    class={`email-style-editor__preview-iframe ${this.previewDevice === 'mobile' ? 'is-mobile' : ''}`}
                    sandbox="allow-same-origin"
                  />
                ) : (
                  <div class="email-style-editor__preview-empty">
                    <CIcon icon="eye-off" size={48} />
                    <p>Click "Preview" to see how your emails will look</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  },
});
