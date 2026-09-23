import { defineComponent, ref, watch, PropType, getCurrentInstance } from 'vue';
import { Switch, SwitchGroup } from '@headlessui/vue';
import { X } from 'lucide-vue-next';
import { toast } from 'vue-sonner';
import CIcon from '@/components/c-icon.vue';

interface Setting {
  key: string;
  type: string;
  value: any;
  default: any;
  readonly?: boolean;
  allowed_values?: string[];
  min?: number;
  max?: number;
  maxlength?: number;
}

export default defineComponent({
  name: 'PreferencesPanel',
  components: {
    CIcon,
  },
  props: {
    settings: {
      type: Array as PropType<Setting[]>,
      required: true,
    },
    category: {
      type: String,
      required: true,
    },
    profileType: {
      type: String,
      required: true,
    },
  },
  emits: ['save'],
  setup(props, { emit }) {
    const { $t } = getCurrentInstance()!.appContext.config.globalProperties;

    const values = ref<Record<string, any>>({});
    const modifiedKeys = ref<Set<string>>(new Set());
    const isSaving = ref(false);

    const toBoolean = (value: any): boolean => {
      if (typeof value === 'boolean') return value;
      if (typeof value === 'number') return value === 1;
      if (typeof value === 'string') {
        const normalized = value.trim().toLowerCase();
        if (['true', '1', 'yes', 'on'].includes(normalized)) return true;
        if (['false', '0', 'no', 'off', ''].includes(normalized)) return false;
      }
      return !!value;
    };

    const initValues = () => {
      const newValues: Record<string, any> = {};
      props.settings.forEach((setting) => {
        if (setting.type === 'boolean') {
          newValues[setting.key] = toBoolean(setting.value);
        } else {
          newValues[setting.key] = setting.value ?? '';
        }
      });
      values.value = newValues;
      modifiedKeys.value.clear();
    };

    const updateValue = (key: string, value: any) => {
      values.value[key] = value;
      const original = props.settings.find((s) => s.key === key);
      if (original && original.value !== value) {
        modifiedKeys.value.add(key);
      } else {
        modifiedKeys.value.delete(key);
      }
    };

    const handleSwitchChange = (key: string, val: boolean) => {
      values.value[key] = val;
      const original = props.settings.find((s) => s.key === key);
      if (original && toBoolean(original.value) !== val) {
        modifiedKeys.value.add(key);
      } else {
        modifiedKeys.value.delete(key);
      }
    };

    const resetSetting = (key: string) => {
      const original = props.settings.find((s) => s.key === key);
      if (original) {
        if (original.type === 'boolean') {
          values.value[key] = toBoolean(original.value);
        } else {
          values.value[key] = original.value ?? '';
        }
        modifiedKeys.value.delete(key);
      }
    };

    const handleSave = async () => {
      if (modifiedKeys.value.size === 0) {
        toast($t('js.preferences.no_changes') || 'No hay cambios para guardar', {
          class: ['c-notifier', 'warning'],
        });
        return;
      }

      isSaving.value = true;
      const changedValues: Record<string, any> = {};

      modifiedKeys.value.forEach((key) => {
        changedValues[key] = values.value[key];
      });

      const result = await emit('save', changedValues);

      isSaving.value = false;

      if (result?.success) {
        modifiedKeys.value.clear();
        toast($t('js.preferences.saved') || 'Preferencias guardadas', {
          class: ['c-notifier', 'success'],
        });
      } else {
        toast($t('js.preferences.error') || 'Error al guardar', {
          class: ['c-notifier', 'error'],
        });
      }
    };

    watch(
      () => props.settings,
      () => {
        initValues();
      },
      { immediate: true, deep: true }
    );

    return () => (
      <div class="preferences-panel">
        <div class="preferences-panel__header">
          <h2 class="preferences-panel__title">
            {$t(`js.preferences.categories.${props.category}`) || props.category}
          </h2>
        </div>

        <div class="preferences-panel__settings">
          {props.settings.map((setting) => {
            if (setting.type === 'action') return null;

            const isModified = modifiedKeys.value.has(setting.key);

            return (
              <div
                key={setting.key}
                class={[
                  'preferences-panel__card',
                  isModified && 'preferences-panel__card--modified',
                ]}
              >
                <div class="preferences-panel__card-content">
                  <div class="preferences-panel__card-header">
                    <label class="preferences-panel__card-title">
                      {$t(`js.preferences.settings.${setting.key}.title`) || setting.key}
                    </label>
                    <p
                      class="preferences-panel__card-description"
                      innerHTML={$t(`js.preferences.settings.${setting.key}.description`)}
                    />
                  </div>

                  <div class="preferences-panel__card-control">
                    {setting.type === 'string' && (
                      <input
                        type="text"
                        value={values.value[setting.key] || ''}
                        onInput={(e: any) => updateValue(setting.key, e.target.value)}
                        maxlength={setting.maxlength || 255}
                        class="preferences-panel__input"
                        placeholder={$t(`js.preferences.settings.${setting.key}.title`) || ''}
                      />
                    )}

                    {setting.type === 'integer' && (
                      <input
                        type="number"
                        value={values.value[setting.key] ?? ''}
                        onInput={(e: any) => updateValue(setting.key, e.target.value)}
                        min={setting.min}
                        max={setting.max}
                        step="1"
                        class="preferences-panel__input"
                        placeholder={$t(`js.preferences.settings.${setting.key}.title`) || ''}
                      />
                    )}

                    {setting.type === 'boolean' && (
                      <SwitchGroup as="div" class="preferences-panel__switch">
                        <Switch
                          modelValue={toBoolean(values.value[setting.key])}
                          class={[
                            'preferences-panel__toggle',
                            toBoolean(values.value[setting.key])
                              ? 'preferences-panel__toggle--on'
                              : 'preferences-panel__toggle--off',
                          ]}
                          onUpdate:modelValue={(val: boolean) => handleSwitchChange(setting.key, val)}
                        >
                          <span
                            aria-hidden="true"
                            class={[
                              'preferences-panel__toggle-thumb',
                              toBoolean(values.value[setting.key]) ? 'preferences-panel__toggle-thumb--on' : '',
                            ]}
                          />
                        </Switch>
                      </SwitchGroup>
                    )}

                    {setting.type === 'enum' && (
                      <select
                        value={values.value[setting.key] || ''}
                        onChange={(e: any) => updateValue(setting.key, e.target.value)}
                        class="preferences-panel__select"
                      >
                        <option value="" disabled>
                          Select option...
                        </option>
                        {setting.allowed_values?.map((option: string) => (
                          <option key={option} value={option}>
                            {$t(`js.preferences.settings.${setting.key}.values.${option}`) || option}
                          </option>
                        ))}
                      </select>
                    )}
                  </div>
                </div>

                {isModified && (
                  <button
                    type="button"
                    onClick={() => resetSetting(setting.key)}
                    class="preferences-panel__reset"
                    title="Reset"
                  >
                    <X size={14} />
                  </button>
                )}
              </div>
            );
          })}
        </div>

        <div class="preferences-panel__footer">
          <button
            type="button"
            disabled={isSaving.value || modifiedKeys.value.size === 0}
            class={[
              'preferences-panel__submit',
              isSaving.value && 'preferences-panel__submit--loading',
              modifiedKeys.value.size === 0 && 'preferences-panel__submit--disabled',
            ]}
            onClick={handleSave}
          >
            {isSaving.value ? (
              <>
                <CIcon icon="loader" class="animate-spin" size={16} />
                {$t('js.preferences.saving') || 'Guardando...'}
              </>
            ) : (
              <>
                <CIcon icon="check" size={16} />
                {$t('js.preferences.save') || 'Guardar cambios'}
              </>
            )}
          </button>
        </div>
      </div>
    );
  },
});
