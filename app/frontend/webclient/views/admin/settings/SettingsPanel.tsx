import { defineComponent, ref, computed, PropType, watch, getCurrentInstance } from 'vue';
import { Switch, SwitchGroup } from '@headlessui/vue';
import { UploadCloud, X, RefreshCw } from 'lucide-vue-next';
import { ajax } from '../../../lib/Ajax';
import { toast } from 'vue-sonner';
import CColorPicker from '@/components/forms/c-color-picker.vue';
import CSplitList from '@/components/forms/CSplitList.tsx';
import CIcon from '@/components/c-icon.vue';
import MonacoTools from '@/app/lib/MonacoTools';


interface Setting {
    key: string;
    type: string;
    value: any;
    label?: string;
    options?: any;
    category?: string;
}

export default defineComponent({
    name: 'SettingsPanel',
    components: {
        CColorPicker,
        CSplitList,
        'vue-monaco-editor': (window as any).VueMonacoEditor || undefined,
    },
    props: {
        settingsData: {
            type: Array as PropType<Setting[]>,
            required: true,
        },
        category: {
            type: String,
            required: true,
        },
    },
    setup(props) {
        const settings = ref<Record<string, any>>({});
        const btnLoading = ref(false);
        const modifiedKeys = ref<Set<string>>(new Set());
        const category = ref(props.category);
        const settingsModel = ref<Setting[]>(props.settingsData);

        // Switch local state for reactivity
        const switchValues = ref<Record<string, boolean>>({});

        // Get I18n translation function
        const { $t } = getCurrentInstance()!.appContext.config.globalProperties;

        const getLanguageByKey = (key: string) => {
            const languageMap: Record<string, string> = {
                'custom_css': 'css',
                'custom_js': 'javascript',
                'custom_html': 'html',
                'custom_json': 'json',
                'additonal_player_settings': 'json',
                'api_custom_data': 'json',
            };
            return languageMap[key] || 'plaintext';
        };

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

        const updateValue = (key: string, value: any) => {
            settings.value[key] = value;
            const original = settingsModel.value.find(s => s.key === key);
            if (original && original.value !== value) {
                modifiedKeys.value.add(key);
            } else {
                modifiedKeys.value.delete(key);
            }
        };

        const updateSettings = async (e: Event) => {
            e.preventDefault();
            const modifiedSettings: Record<string, any> = {};

            for (const key in settings.value) {
                const setting = settingsModel.value.find((s) => s.key === key);
                if (setting && setting.value !== settings.value[key]) {
                    modifiedSettings[key] = settings.value[key];
                }
            }

            if (Object.keys(modifiedSettings).length === 0) {
                toast($t('js.admin.settings.no_changes') || 'No hay cambios para guardar', {
                    class: ['c-notifier', 'warning']
                });
                return;
            }

            btnLoading.value = true;

            const formData = new FormData();
            for (const key in modifiedSettings) {
                formData.append(`setting[${key}]`, modifiedSettings[key]);
            }

            try {
                const response = await ajax.put('/admin/site_settings.json', formData);
                btnLoading.value = false;

                settingsModel.value.forEach((setting) => {
                    if (modifiedSettings.hasOwnProperty(setting.key)) {
                        setting.value = modifiedSettings[setting.key];
                        settings.value[setting.key] = modifiedSettings[setting.key];
                    }
                });

                modifiedKeys.value.clear();

                toast(response.data.message || 'Settings guardados', {
                    class: ['c-notifier', 'success']
                });

                for (const key in modifiedSettings) {
                    const setting = settingsModel.value.find((s) => s.key === key);
                    if (setting?.options?.refresh) {
                        window.location.reload();
                        break;
                    }
                }
            } catch (error) {
                btnLoading.value = false;
                toast($t('js.core.generic_error') || 'Error al guardar', {
                    class: ['c-notifier', 'error']
                });
            }
        };

        const uploaderButton = (formId: string) => {
            document.getElementById(formId)?.click();
        };

        const handleImageChange = (e: Event, settingName: string) => {
            const target = e.target as HTMLInputElement;
            const data = target.files?.[0];
            if (data) {
                settings.value[settingName] = data;
                modifiedKeys.value.add(settingName);
            }
        };

        const resetSetting = (key: string) => {
            const original = settingsModel.value.find(s => s.key === key);
            if (original) {
                settings.value[key] = original.value;
                modifiedKeys.value.delete(key);
            }
        };

        const testStorageConnection = async () => {
            try {
                const response = await ajax.post('/admin/site_settings/test_connection.json');

                if (response.data.success) {
                    toast(response.data.message || 'Connection successful', {
                        class: ['c-notifier', 'success']
                    });
                } else {
                    toast(response.data.error || 'Connection failed', {
                        class: ['c-notifier', 'error']
                    });
                }
            } catch (error) {
                toast($t('js.core.generic_error') || 'Error testing connection', {
                    class: ['c-notifier', 'error']
                });
            }
        };

        watch(
            () => props.settingsData,
            (newData) => {
                settingsModel.value = newData;
                settings.value = {};
                modifiedKeys.value.clear();
                switchValues.value = {};
                settingsModel.value.forEach((setting) => {
                    settings.value[setting.key] = setting.value;
                    // Initialize switch values as proper booleans
                    if (setting.type === 'boolean') {
                        switchValues.value[setting.key] = toBoolean(setting.value);
                        settings.value[setting.key] = switchValues.value[setting.key];
                    }
                });
            },
            { immediate: true }
        );

        watch(
            () => props.category,
            (newCategory) => {
                category.value = newCategory;
            },
            { immediate: true }
        );

        return () => (
            <div class="settings-panel">
                <div class="settings-panel__header">
                    <h2 class="settings-panel__title">
                        {$t(`js.admin.settings.categories.${category.value}`) || category.value}
                    </h2>
                    <div class="settings-panel__header-actions">
                        {category.value === 'storage' && (
                            <button
                                type="button"
                                onClick={testStorageConnection}
                                class="settings-panel__test-btn"
                                title={$t('js.admin.settings.test_connection') || 'Test Connection'}
                            >
                                <RefreshCw size={16} />
                                <span>{$t('js.admin.settings.test_connection') || 'Test Connection'}</span>
                            </button>
                        )}
                        {modifiedKeys.value.size > 0 && (
                            <span class="settings-panel__badge">
                                {modifiedKeys.value.size} cambio{modifiedKeys.value.size > 1 ? 's' : ''}
                            </span>
                        )}
                    </div>
                </div>

                <form onSubmit={updateSettings} class="settings-panel__form">
                    {settingsModel.value.map((setting) => {
                        const isModified = modifiedKeys.value.has(setting.key);

                        return (
                            <div
                                key={setting.key}
                                class={[
                                    'settings-panel__card',
                                    isModified && 'settings-panel__card--modified',
                                ]}
                            >
                                <div class="settings-panel__card-content">
                                    <div class="settings-panel__card-header">
                                        <label class="settings-panel__card-title">
                                            {$t(`js.admin.settings.${setting.key}.title`) || setting.label || setting.key}
                                        </label>
                                        <p
                                            class="settings-panel__card-description"
                                            innerHTML={$t(`js.admin.settings.${setting.key}.description`)}
                                        />
                                    </div>

                                    <div class="settings-panel__card-control">
                                        {/* String input */}
                                        {setting.type === 'string' && (
                                            <>
                                                <input
                                                    type="text"
                                                    value={settings.value[setting.key] || ''}
                                                    onInput={(e: any) => updateValue(setting.key, e.target.value)}
                                                    maxlength={setting.options?.maxlength || 255}
                                                    class="settings-panel__input"
                                                    placeholder={$t(`js.admin.settings.${setting.key}.title`) || ''}
                                                />
                                            </>
                                        )}

                                        {/* Integer/number input */}
                                        {(setting.type === 'integer' || setting.type === 'number') && (
                                            <input
                                                type="number"
                                                value={settings.value[setting.key] ?? ''}
                                                onInput={(e: any) => updateValue(setting.key, e.target.value)}
                                                min={setting.options?.min}
                                                max={setting.options?.max}
                                                step={setting.type === 'integer' ? '1' : 'any'}
                                                class="settings-panel__input"
                                                placeholder={$t(`js.admin.settings.${setting.key}.title`) || ''}
                                            />
                                        )}

                                        {/* Boolean switch */}
                                        {setting.type === 'boolean' && (
                                            <SwitchGroup as="div" class="settings-panel__switch">
                                                <Switch
                                                    modelValue={switchValues.value[setting.key] ?? false}
                                                    class={[
                                                        'settings-panel__toggle',
                                                        switchValues.value[setting.key] ? 'settings-panel__toggle--on' : 'settings-panel__toggle--off',
                                                    ]}
                                                    onUpdate:modelValue={(val: boolean) => {
                                                        switchValues.value[setting.key] = val;
                                                        settings.value[setting.key] = val;
                                                        const original = settingsModel.value.find(s => s.key === setting.key);
                                                        if (original && toBoolean(original.value) !== val) {
                                                            modifiedKeys.value.add(setting.key);
                                                        } else {
                                                            modifiedKeys.value.delete(setting.key);
                                                        }
                                                    }}
                                                >
                                                    <span
                                                        aria-hidden="true"
                                                        class={[
                                                            'settings-panel__toggle-thumb',
                                                            switchValues.value[setting.key] ? 'settings-panel__toggle-thumb--on' : '',
                                                        ]}
                                                    />
                                                </Switch>
                                            </SwitchGroup>
                                        )}

                                        {/* Image upload */}
                                        {setting.type === 'image' && (
                                            <div class="settings-panel__image">
                                                <div
                                                    class="settings-panel__image-preview"
                                                    style={{
                                                        backgroundImage: settings.value[setting.key]
                                                            ? `url(${typeof settings.value[setting.key] === 'string' ? settings.value[setting.key] : setting.value})`
                                                            : `url(${setting.value})`,
                                                    }}
                                                >
                                                    <div class="settings-panel__image-controls">
                                                        <button
                                                            type="button"
                                                            onClick={() => uploaderButton(`upload-${setting.key}`)}
                                                            class="settings-panel__image-btn"
                                                            title={$t('js.admin.Image_uploader_title') || 'Upload'}
                                                        >
                                                            <UploadCloud size={16} />
                                                        </button>
                                                        <input
                                                            id={`upload-${setting.key}`}
                                                            type="file"
                                                            accept="image/*"
                                                            class="hidden"
                                                            onChange={(e) => handleImageChange(e, setting.key)}
                                                        />
                                                    </div>
                                                </div>
                                            </div>
                                        )}

                                        {/* List */}
                                        {setting.type === 'list' && (
                                            <CSplitList
                                                items={settings.value[setting.key] || []}
                                                onUpdate:items={(items: any) => updateValue(setting.key, items)}
                                                splitter="|"
                                            />
                                        )}

                                        {/* Enum select */}
                                        {setting.type === 'enum' && (
                                            <select
                                                value={settings.value[setting.key] || setting.value || ''}
                                                onChange={(e: any) => updateValue(setting.key, e.target.value)}
                                                class="settings-panel__select"
                                            >
                                                <option value="" disabled>
                                                    Select option...
                                                </option>
                                                {setting.options?.allowed_values?.map((option: string) => (
                                                    <option key={option} value={option}>
                                                        {$t(`js.admin.settings.${setting.key}.values.${option}`) || option}
                                                    </option>
                                                ))}
                                            </select>
                                        )}

                                        {/* Textarea */}
                                        {setting.type === 'textarea' && (
                                            <textarea
                                                value={settings.value[setting.key] || ''}
                                                onInput={(e: any) => updateValue(setting.key, e.target.value)}
                                                class="settings-panel__textarea"
                                                rows={3}
                                                placeholder={$t(`js.admin.settings.${setting.key}.title`) || ''}
                                            />
                                        )}

                                        {/* Color picker */}
                                        {setting.type === 'color' && (
                                            <div class="settings-panel__color">
                                                <span
                                                    class="settings-panel__color-preview"
                                                    style={{
                                                        backgroundColor: settings.value[setting.key] || setting.value || '#000000',
                                                    }}
                                                />
                                                <CColorPicker
                                                    modelValue={settings.value[setting.key] || setting.value}
                                                    onUpdate:modelValue={(value: string) => updateValue(setting.key, value)}
                                                />
                                            </div>
                                        )}

                                        {/* Code editor */}
                                        {setting.type === 'code' && (
                                            <div class="settings-panel__code">
                                                <vue-monaco-editor
                                                    theme="vs-dark"
                                                    onUpdate:value={(value: string) => updateValue(setting.key, value)}
                                                    value={settings.value[setting.key] || setting.value}
                                                    language={getLanguageByKey(setting.key)}
                                                    height="300px"
                                                    width="100%"
                                                    onMount={MonacoTools.addTypes}
                                                />
                                            </div>
                                        )}
                                    </div>
                                </div>

                                {isModified && (
                                    <button
                                        type="button"
                                        onClick={() => resetSetting(setting.key)}
                                        class="settings-panel__reset"
                                        title="Reset"
                                    >
                                        <X size={14} />
                                    </button>
                                )}
                            </div>
                        );
                    })}

                    <div class="settings-panel__footer">
                        <button
                            type="submit"
                            disabled={btnLoading.value || modifiedKeys.value.size === 0}
                            class={[
                                'settings-panel__submit',
                                btnLoading.value && 'settings-panel__submit--loading',
                                modifiedKeys.value.size === 0 && 'settings-panel__submit--disabled',
                            ]}
                        >
                            {btnLoading.value ? (
                                <>
                                    <CIcon icon="loader" class="animate-spin" size={16} />
                                    {$t('js.admin.settings.saving') || 'Guardando...'}
                                </>
                            ) : (
                                <>
                                    <CIcon icon="check" size={16} />
                                    {$t('js.admin.settings.save') || 'Guardar cambios'}
                                </>
                            )}
                        </button>
                    </div>
                </form>
            </div>
        );
    },
});
