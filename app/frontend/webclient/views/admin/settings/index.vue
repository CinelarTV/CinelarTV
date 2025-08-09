<template>
    <div>
        <div class="center">
            <form @submit.prevent="updateSettings" v-if="settings">
                <div class="setting-container" v-for="(setting, index) in settingsModel" :key="setting.key">
                    <span class="setting-title">
                        {{ $t(`js.admin.settings.${setting.key}.title`) }}
                    </span>
                    <!-- Type 0: String -->

                    <div class="flex flex-col max-w-md">
                        <c-input v-if="setting.type === 'string'" @input="settings[setting.key] = $event.target.value"
                            class="setting-value input" type="text" :value="settingsModel[index].value"
                            :maxlength="setting.options.limit" :label="$t(`js.admin.settings.${setting.key}.title`)" />

                        <!-- Type 1: Boolean -->



                        <SwitchGroup v-else-if="setting.type === 'boolean'">
                            <div class="flex items-center">
                                <SwitchLabel class="mr-4">{{ setting.label }}</SwitchLabel>
                                <Switch v-model="settings[setting.key]" :class="{
                                    'bg-blue-600': settings[setting.key],
                                    'bg-gray-600': !settings[setting.key]
                                }"
                                    class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2">
                                    <span :class="{
                                        'translate-x-6': settings[setting.key],
                                        'translate-x-1': !settings[setting.key]
                                    }"
                                        class="inline-block h-4 w-4 transform rounded-full bg-white transition-transform" />
                                </Switch>
                            </div>
                        </SwitchGroup>

                        <!-- Type 2: Image -->

                        <!-- Type 3: List -->
                        <div v-else-if="setting.type === 'list'">
                            <CSplitList :items="settings[setting.key]" @update:items="settings[setting.key] = $event"
                                splitter="|" />
                        </div>

                        <div v-else-if="setting.type === 'enum'">
                            <c-select
                                :options="setting.options.allowed_values.map(option => ({ value: option, label: $t(`js.admin.settings.${setting.key}.options.${option}`) }))"
                                :placeholder="settings[setting.key] || setting.value" v-model="settings[setting.key]"
                                @update:modelValue="settings[setting.key] = $event"
                                :modelValue="settings[setting.key] || setting.value"
                                :label="$t(`js.admin.settings.${setting.key}.title`)" />

                        </div>


                        <div v-else-if="setting.type === 'image'">
                            <div class="setting-image-uploader">
                                <div class="uploaded-image-preview" :id="`preview-${setting.key}`"
                                    :style="`background-image: url('${setting.value}')`">
                                    <div class="image-upload-controls">
                                        <c-button :title="`${$t('js.admin.image_uploader_title')}`"
                                            @click="uploaderButton(`upload-${setting.key}`)">
                                            <UploadCloudIcon />
                                        </c-button>
                                        <input :ref="`upload-${setting.key}`" class="hidden" @change="handleImageChange"
                                            :v-model:value="settings[setting.key]" :id="`upload-${setting.key}`"
                                            type="file" accept="image/*" />
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Type 4: Long TextBox -->

                        <textarea v-if="setting.type == 'textarea'" @input="settings[setting.key] = $event.target.value"
                            :value="setting.value" class="setting-value textarea" type="text"
                            :label="$t(`js.admin.settings.${setting.key}.title`)"></textarea>

                        <!-- Type : Color Picker -->

                        <template v-if="setting.type === 'color'" class="flex">

                            <span class="flex h-4 w-4 rounded-full"
                                :style="`background-color: ${settings[setting.key] || settingsModel[index].value}`">
                                &nbsp;
                            </span>
                            <c-input @input="e => settings[setting.key] = e.target.value" type="text"
                                v-model="settings[setting.key]" class="setting-value input"
                                :label="$t(`js.admin.settings.${setting.key}.title`)" data-coloris />
                        </template>

                        <template v-if="setting.type === 'code'" class="flex">
                            <vue-monaco-editor theme="vs-dark" @update:value="value => updateValue(setting.key, value)"
                                :value="setting.value" :language="getLanguageByKey(setting.key)" height="350px"
                                @mount="MonacoTools.addTypes" width="100%">
                                <template #loading>
                                    <c-spinner />
                                </template>
                            </vue-monaco-editor>


                        </template>



                        <span class="setting-description" v-html="$t(`js.admin.settings.${setting.key}.description`)" />
                    </div>

                </div>
                <c-button :loading="btnLoading" type="submit" @click="updateSettings" class="settings-submit">
                    {{ $t("js.admin.settings.save") }}
                </c-button>
            </form>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, onUpdated } from 'vue';
import { toast } from 'vue-sonner';
import MonacoTools from '../../../app/lib/MonacoTools';
import CColorPicker from '../../../components/forms/c-color-picker.vue';
import {
    Listbox,
    ListboxButton,
    ListboxOptions,
    ListboxOption,
    Switch,
    SwitchGroup,
    SwitchLabel
} from '@headlessui/vue';
import { UploadCloudIcon } from 'lucide-vue-next';
import CSplitList from "../../../components/forms/CSplitList";

const settings = ref({});
const btnLoading = ref(null);
var settingsModel = ref(null);
var category = ref(null);
const props = defineProps(['settingsData', 'category']);

const updateValue = (key, value) => {
    settings.value[key] = value;
};

const getLanguageByKey = (key) => {
    const languageMap = {
        'custom_css': 'css',
        'custom_js': 'javascript',
        'custom_html': 'html',
        'custom_json': 'json',
        'additonal_player_settings': 'json',
        'api_custom_data': 'json',
    };

    return languageMap[key] || 'plaintext';
};

function updateSettings(e) {
    e.preventDefault();
    const modifiedSettings = {};

    const formData = new FormData();
    for (const key in settings.value) {
        const setting = settingsModel.value.find((s) => s.key === key);
        if (setting && setting.value !== settings.value[key]) {
            modifiedSettings[key] = settings.value[key];
            formData.append(`setting[${key}]`, settings.value[key]);
        }
    }

    if (Object.keys(modifiedSettings).length === 0) {
        toast(I18n.t('js.admin.settings.no_changes'), {
            class: ['c-notifier', 'warning']
        });
        return;
    }

    btnLoading.value = true;

    ajax
        .put('/admin/site_settings.json', formData)
        .then((response) => {
            btnLoading.value = false;
            settingsModel.value.forEach((setting) => {
                if (modifiedSettings.hasOwnProperty(setting.key)) {
                    setting.value = modifiedSettings[setting.key];
                    settings.value[setting.key] = modifiedSettings[setting.key];
                }
            });

            try {
                toast(response.data.message, {
                    class: ['m-notifier', 'success']
                });
            } catch (error) { }

            for (const key in modifiedSettings) {
                const setting = settingsModel.value.find((s) => s.key === key);
                if (setting && setting.options && setting.options.refresh) {
                    window.location.reload();
                    break;
                }
            }
        })
        .catch((error) => {
            error = true;
            btnLoading.value = false;
            toast(I18n.t('js.core.generic_error'));
        });
}

function uploaderButton(form) {
    document.getElementById(`${form}`).click();
}

function handleImageChange(e) {
    let settingName = e.target.id.replace('upload-', '');
    const data = e.target.files[0];
    settings.value[settingName] = data;
    console.log(data);
    console.log(settingName);

    const preview = document.getElementById(e.target.id.replace('upload-', 'preview-'));
}

onMounted(onDataLoaded);
onUpdated(onDataLoaded);

function onDataLoaded() {
    settingsModel.value = props.settingsData;
    category.value = props.category;

    settingsModel.value.forEach((setting) => {
        settings.value[setting.key] = setting.value;
    });
}
</script>
