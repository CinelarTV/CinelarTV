import { defineComponent, ref, onMounted } from 'vue';
import { useHead } from 'unhead';
import { useRouter } from 'vue-router';
import { ajax } from '../../../lib/Ajax';

interface LocaleData {
  has_override: boolean;
}

interface Templates {
  [key: string]: {
    [locale: string]: LocaleData;
  };
}

export default defineComponent({
  name: 'EmailTemplates',
  setup() {
    const templates = ref<Templates>({});
    const loading = ref(true);
    const router = useRouter();

    const templateLabels: Record<string, string> = {
      'devise_confirmation_instructions': 'Confirmation Instructions',
      'devise_reset_password_instructions': 'Reset Password Instructions',
      'devise_unlock_instructions': 'Unlock Instructions',
      'devise_email_changed': 'Email Changed'
    };

    const locales = ['en', 'es', 'pt-BR'];

    const fetchTemplates = async () => {
      loading.value = true;
      try {
        const response = await ajax.get('/admin/email-templates.json');
        templates.value = response.data.templates;
      } catch (error) {
        console.error('Failed to fetch email templates:', error);
      } finally {
        loading.value = false;
      }
    };

    const handleEdit = (key: string) => {
      router.push(`/admin/email-templates/${key}`);
    };

    onMounted(() => {
      fetchTemplates();
    });

    useHead({
      title: 'Email Templates - Admin'
    });

    return () => (
      <div class="panel">
        <div class="panel-header">
          <h2 class="panel-title">Email Templates</h2>
        </div>
        <div class="panel-body">
          {loading.value ? (
            <div class="text-center py-8 text-gray-500">Loading...</div>
          ) : (
            <div class="overflow-x-auto">
              <table class="w-full text-left admin-table text-sm">
                <thead>
                  <tr>
                    <th>Template</th>
                    {locales.map(locale => (
                      <th key={locale}>{locale} (Override)</th>
                    ))}
                    <th class="text-center">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {Object.entries(templates.value).map(([key, localeData]) => (
                    <tr key={key}>
                      <td>{templateLabels[key] || key}</td>
                      {locales.map(locale => (
                        <td key={locale}>
                          {localeData[locale]?.has_override ? (
                            <span class="text-green-600">✓</span>
                          ) : (
                            <span class="text-gray-400">-</span>
                          )}
                        </td>
                      ))}
                      <td class="text-center">
                        <a
                          href="#"
                          onClick={() => handleEdit(key)}
                          class="text-blue-600 hover:text-blue-800"
                        >
                          Edit
                        </a>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    );
  }
});
