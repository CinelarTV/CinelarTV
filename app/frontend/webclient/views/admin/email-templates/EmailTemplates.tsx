import { defineComponent, ref, onMounted, computed } from 'vue';
import { useHead } from 'unhead';
import { useRouter } from 'vue-router';
import { ajax } from '../../../lib/Ajax';
import CIcon from '../../../components/c-icon.vue';
import CButton from '../../../components/forms/c-button.tsx';

interface LocaleData {
  has_override: boolean;
  interpolation_variables: string[];
}

interface TemplateMeta {
  label: string;
  description: string;
}

interface Templates {
  [key: string]: {
    [locale: string]: LocaleData;
    meta?: TemplateMeta;
  };
}

const TEMPLATE_ICONS: Record<string, string> = {
  devise_confirmation_instructions: 'mail-check',
  devise_reset_password_instructions: 'key-round',
  devise_unlock_instructions: 'unlock',
  devise_email_changed: 'mail',
};

const LOCALES = [
  { code: 'en', label: 'EN' },
  { code: 'es', label: 'ES' },
  { code: 'pt-BR', label: 'PT-BR' },
];

export default defineComponent({
  name: 'EmailTemplates',
  components: { CIcon, CButton },
  setup() {
    const templates = ref<Templates>({});
    const loading = ref(true);
    const router = useRouter();

    const templateKeys = computed(() => Object.keys(templates.value));

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

    const getOverrideCount = (key: string) => {
      const tmpl = templates.value[key];
      if (!tmpl) return 0;
      return LOCALES.filter(l => tmpl[l.code]?.has_override).length;
    };

    onMounted(() => {
      fetchTemplates();
    });

    useHead({
      title: 'Email Templates - Admin'
    });

    return () => (
      <div class="email-templates">
        {/* Hero header */}
        <header class="email-templates__hero">
          <div class="email-templates__hero-header">
            <div>
              <p class="email-templates__eyebrow">Email System</p>
              <h1 class="email-templates__title">Email Templates</h1>
              <p class="email-templates__subtitle">
                Gestiona las plantillas de email que se envían a los usuarios. Modifica el asunto, contenido y variables de interpolación.
              </p>
            </div>
          </div>
        </header>

        {/* Template cards grid */}
        {loading.value ? (
          <div class="email-editor__card" style="padding: 2rem; text-align: center;">
            <CIcon icon="loader" size={20} class="animate-spin" />
            <p style="color: rgba(255,255,255,0.45); margin: 8px 0 0; font-size: 0.85rem;">
              Cargando plantillas...
            </p>
          </div>
        ) : (
          <div class="email-templates__grid">
            {templateKeys.value.map((key) => {
              const tmpl = templates.value[key];
              const meta = tmpl?.meta;
              const overrideCount = getOverrideCount(key);
              const icon = TEMPLATE_ICONS[key] || 'mail';

              return (
                <div key={key} class="email-template-card">
                  <div class="email-template-card__header">
                    <div class="email-template-card__icon">
                      <CIcon icon={icon} size={20} />
                    </div>
                    <div class="email-template-card__info">
                      <h3 class="email-template-card__name">
                        {meta?.label || key}
                      </h3>
                      <p class="email-template-card__description">
                        {meta?.description || key}
                      </p>
                    </div>
                  </div>

                  <div class="email-template-card__locales">
                    {LOCALES.map((locale) => {
                      const hasOverride = tmpl?.[locale.code]?.has_override;
                      return (
                        <span
                          key={locale.code}
                          class={`email-template-card__locale-badge ${hasOverride ? 'is-overridden' : 'is-default'}`}
                        >
                          {locale.label}
                          {hasOverride ? ' ✓' : ''}
                        </span>
                      );
                    })}
                    {overrideCount > 0 && (
                      <span style={{
                        fontSize: '0.7rem',
                        color: 'rgba(255,255,255,0.4)',
                        alignSelf: 'center',
                        marginLeft: '4px'
                      }}>
                        {overrideCount}/{LOCALES.length} overrides
                      </span>
                    )}
                  </div>

                  <div class="email-template-card__actions">
                    <CButton
                      icon="pencil"
                      onClick={() => handleEdit(key)}
                    >
                      Editar
                    </CButton>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    );
  }
});
