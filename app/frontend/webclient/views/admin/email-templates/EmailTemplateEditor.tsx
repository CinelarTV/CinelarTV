import { defineComponent, ref, watch, onMounted, Fragment } from 'vue';
import { useHead } from 'unhead';
import { useRouter, useRoute } from 'vue-router';
import { ajax } from '@/lib/Ajax';
import { useEditor, EditorContent } from '@tiptap/vue-3';
import StarterKit from '@tiptap/starter-kit';

export default defineComponent({
  name: 'EmailTemplateEditor',
  components: {
    EditorContent
  },
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
    const showPreview = ref(false);
    const previewHtml = ref('');
    const previewSubject = ref('');
    const previewLoading = ref(false);

    const editor = useEditor({
      content: '',
      extensions: [StarterKit],
      editorProps: {
        attributes: {
          class: 'prose max-w-none min-h-[300px] p-4 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500'
        }
      }
    });

    const templateLabels: Record<string, string> = {
      'devise_confirmation_instructions': 'Confirmation Instructions',
      'devise_reset_password_instructions': 'Reset Password Instructions',
      'devise_unlock_instructions': 'Unlock Instructions',
      'devise_email_changed': 'Email Changed'
    };

    const fetchTemplate = async () => {
      loading.value = true;
      try {
        const response = await ajax.get(`/admin/email-templates/${key}.json`, {
          params: { locale: locale.value }
        });
        subject.value = response.data.subject;
        editor.value?.commands.setContent(response.data.body);
        hasOverride.value = response.data.has_override;
        interpolationVariables.value = response.data.interpolation_variables;
      } catch (error) {
        console.error('Failed to fetch email template:', error);
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
          body: editor.value?.getHTML()
        });
        hasOverride.value = true;
        alert('Template saved successfully');
      } catch (error) {
        console.error('Failed to save email template:', error);
        alert('Failed to save template');
      } finally {
        saving.value = false;
      }
    };

    const handleRevert = async () => {
      if (!confirm('Are you sure you want to revert to the default template? This will delete your custom override.')) {
        return;
      }
      saving.value = true;
      try {
        await ajax.delete(`/admin/email-templates/${key}`, {
          params: { locale: locale.value }
        });
        hasOverride.value = false;
        fetchTemplate();
        alert('Template reverted to default');
      } catch (error) {
        console.error('Failed to revert email template:', error);
        alert('Failed to revert template');
      } finally {
        saving.value = false;
      }
    };

    const insertVariable = (variable: string) => {
      editor.value?.chain().focus().insertContent(`%{${variable}}`).run();
    };

    const handlePreview = async () => {
      previewLoading.value = true;
      try {
        const response = await ajax.post(`/admin/email-templates/${key}/preview`, {
          locale: locale.value,
          subject: subject.value,
          body: editor.value?.getHTML()
        });
        previewSubject.value = response.data.subject;
        previewHtml.value = response.data.html;
        showPreview.value = true;
      } catch (error) {
        console.error('Failed to generate preview:', error);
        alert('Failed to generate preview');
      } finally {
        previewLoading.value = false;
      }
    };

    const toggleBold = () => editor.value?.chain().focus().toggleBold().run();
    const toggleItalic = () => editor.value?.chain().focus().toggleItalic().run();
    const toggleBulletList = () => editor.value?.chain().focus().toggleBulletList().run();
    const isBold = () => editor.value?.isActive('bold');
    const isItalic = () => editor.value?.isActive('italic');
    const isBulletList = () => editor.value?.isActive('bulletList');

    watch(locale, () => {
      fetchTemplate();
    });

    onMounted(() => {
      fetchTemplate();
    });

    useHead({
      title: `Edit ${templateLabels[key] || key} - Admin`
    });

    return () => (
      <Fragment>
        <div class="panel">
          <div class="panel-header">
            <button
              onClick={() => router.push('/admin/email-templates')}
              class="text-blue-600 hover:text-blue-800 mb-2"
            >
              ← Back to Templates
            </button>
            <h2 class="panel-title">Edit {templateLabels[key] || key}</h2>
          </div>
          <div class="panel-body">
            {loading.value ? (
              <div class="text-center py-8 text-gray-500">Loading...</div>
            ) : (
              <div>
                <div class="mb-4">
                  <label class="block text-sm font-medium text-gray-700 mb-2">
                    Locale
                  </label>
                  <select
                    value={locale.value}
                    onInput={(e: any) => locale.value = e.target.value}
                    class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 border"
                  >
                    <option value="en">English (en)</option>
                    <option value="es">Español (es)</option>
                    <option value="pt-BR">Português (pt-BR)</option>
                  </select>
                </div>

                <div class="mb-4">
                  <label class="block text-sm font-medium text-gray-700 mb-2">
                    Subject
                  </label>
                  <input
                    type="text"
                    value={subject.value}
                    onInput={(e: any) => subject.value = e.target.value}
                    class="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm p-2 border"
                  />
                </div>

                <div class="mb-4">
                  <label class="block text-sm font-medium text-gray-700 mb-2">
                    Body
                  </label>
                  <div class="border rounded-lg">
                    <div class="bg-[var(--c-primary-400)] border-b p-2 flex gap-2">
                      <button
                        onClick={toggleBold}
                        class={`px-3 py-1 rounded ${isBold() ? 'bg-blue-100' : 'hover:bg-gray-200'}`}
                      >
                        Bold
                      </button>
                      <button
                        onClick={toggleItalic}
                        class={`px-3 py-1 rounded ${isItalic() ? 'bg-blue-100' : 'hover:bg-gray-200'}`}
                      >
                        Italic
                      </button>
                      <button
                        onClick={toggleBulletList}
                        class={`px-3 py-1 rounded ${isBulletList() ? 'bg-blue-100' : 'hover:bg-gray-200'}`}
                      >
                        Bullet List
                      </button>
                    </div>
                    <EditorContent editor={editor.value} />
                  </div>
                </div>

                <div class="mb-4">
                  <label class="block text-sm font-medium text-gray-700 mb-2">
                    Interpolation Variables (click to insert)
                  </label>
                  <div class="flex flex-wrap gap-2">
                    {interpolationVariables.value.map((variable) => (
                      <button
                        key={variable}
                        onClick={() => insertVariable(variable)}
                        class="px-3 py-1 bg-blue-100 text-blue-800 rounded hover:bg-blue-200 text-sm"
                      >
                        {`%{${variable}}`}
                      </button>
                    ))}
                  </div>
                </div>

                {!hasOverride.value && (
                  <div class="mb-4 p-3 bg-yellow-50 border border-yellow-200 rounded">
                    <p class="text-sm text-yellow-800">
                      ⚠️ Using default template from YAML. Save to create a custom override.
                    </p>
                  </div>
                )}

                <div class="flex gap-4">
                  <button
                    onClick={handleSave}
                    disabled={saving.value}
                    class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
                  >
                    {saving.value ? 'Saving...' : 'Save'}
                  </button>
                  <button
                    onClick={handlePreview}
                    disabled={previewLoading.value}
                    class="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50"
                  >
                    {previewLoading.value ? 'Generating...' : 'Preview'}
                  </button>
                  {hasOverride.value && (
                    <button
                      onClick={handleRevert}
                      disabled={saving.value}
                      class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 disabled:opacity-50"
                    >
                      {saving.value ? 'Reverting...' : 'Revert to Default'}
                    </button>
                  )}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Preview Modal */}
        {showPreview.value && (
          <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div class="bg-white rounded-lg max-w-4xl max-h-[90vh] overflow-hidden flex flex-col">
              <div class="p-4 border-b flex justify-between items-center">
                <h3 class="text-lg font-semibold">Email Preview</h3>
                <button
                  onClick={() => showPreview.value = false}
                  class="text-gray-500 hover:text-gray-700 text-2xl leading-none"
                >
                  ×
                </button>
              </div>
              <div class="p-4 border-b bg-gray-50">
                <p class="text-sm text-gray-600">
                  <strong>Subject:</strong> {previewSubject.value}
                </p>
              </div>
              <div class="flex-1 overflow-auto p-4">
                <div class="border rounded-lg">
                  <iframe
                    srcDoc={previewHtml.value}
                    class="w-full h-[600px] border-0"
                    title="Email Preview"
                  />
                </div>
              </div>
              <div class="p-4 border-t flex justify-end gap-2">
                <button
                  onClick={() => {
                    const printWindow = window.open('', '_blank');
                    printWindow!.document.write(previewHtml.value);
                    printWindow!.document.close();
                    printWindow!.print();
                  }}
                  class="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
                >
                  Print
                </button>
                <button
                  onClick={() => showPreview.value = false}
                  class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        )}
      </Fragment>
    );
  }
});
