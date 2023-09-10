<template>
    <div>
        <div class="center">
            <h1>{{ $t(`js.admin.settings.${category}.title`) }}</h1>
            <div class="pt-4">
                <form @submit.prevent="updateSettings">
                    <div class="setting-container" v-for="(setting, index) in settingsModel" :key="setting.key">
                        <span class="setting-title">
                            {{ $t(`js.admin.settings.${category}.${setting.key}.title`) }}
                        </span>
                        <!-- Type 0: String -->

                        <div class="flex flex-col max-w-md">
                            <c-input v-if="setting.type === 'string'" @input="settings[setting.key] = $event.target.value"
                                class="setting-value input" type="text" :value="settingsModel[index].value"
                                :maxlength="setting.options.limit"
                                :label="$t(`js.admin.settings.${category}.${setting.key}.title`)" />

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
                                <Listbox v-model="settings[setting.key]">
                                    <ListboxButton class="setting-value input">{{ settings[setting.key] || setting.value }}
                                    </ListboxButton>
                                    <ListboxOptions>
                                        <ListboxOption v-for="option in setting.options.values" :key="option"
                                            :value="option">
                                            {{ option }}
                                        </ListboxOption>
                                    </ListboxOptions>
                                </Listbox>
                            </div>

                            <div v-else-if="setting.type === 'enum'">
                                <c-select
                                    :options="setting.options.allowed_values.map(option => ({ value: option, label: $t(`js.admin.settings.${category}.${setting.key}.options.${option}`) }))"
                                    :placeholder="settings[setting.key] || setting.value" v-model="settings[setting.key]"
                                    @update:modelValue="settings[setting.key] = $event"
                                    :modelValue="settings[setting.key] || setting.value"
                                    :label="$t(`js.admin.settings.${category}.${setting.key}.title`)" />

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
                                            <input :ref="`upload-${setting.key}`" class="d-none" @change="handleImageChange"
                                                :v-model:value="settings[setting.key]" :id="`upload-${setting.key}`"
                                                type="file" accept="image/*" />
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Type 4: Long TextBox -->

                            <textarea v-if="setting.type == 'textarea'" @input="settings[setting.key] = $event.target.value"
                                :value="setting.value" class="setting-value textarea" type="text"
                                :label="$t(`js.admin.settings.${category}.${setting.key}.title`)"></textarea>

                            <!-- Type : Color Picker -->

                            <template v-if="setting.type === 'color'" class="flex">
                                <span class="flex h-4 w-4 rounded-full"
                                    :style="`background-color: ${settings[setting.key] || settingsModel[index].value}`">
                                    &nbsp;
                                </span>
                                <c-input @input="settings[setting.key] = $event.target.value" class="setting-value input"
                                    type="text" :value="settingsModel[index].value"
                                    :label="$t(`js.admin.settings.${category}.${setting.key}.title`)" data-coloris />
                            </template>



                            <span class="setting-description"
                                v-html="$t(`js.admin.settings.${category}.${setting.key}.description`)" />
                        </div>

                    </div>
                    <c-button :loading="btnLoading" type="submit" @click="updateSettings" class="settings-submit">
                        {{ $t("js.admin.settings.save") }}
                    </c-button>
                </form>
            </div>
        </div>
    </div>
</template>
  
<script setup>








import { ref, reactive, onMounted, inject, onUpdated } from 'vue'
import { toast } from 'vue3-toastify'
import {
    Listbox,
    ListboxButton,
    ListboxOptions,
    ListboxOption,
    Switch,
    SwitchGroup,
    SwitchLabel
} from '@headlessui/vue'
import { UploadCloudIcon } from 'lucide-vue-next';


const settings = reactive({})
const btnLoading = ref(null)
var settingsModel = ref(null)
var category = ref(null)
const props = defineProps(['settingsData', 'category'])



function updateSettings(e) {
    e.preventDefault()
    // Check if are a modifed settings (if not, maybe don't have modified settings)
    let modifedSettings = {}
    const formData = new FormData()

    for (const key in settings) {
        if (settings.hasOwnProperty(key)) {
            const setting = settings[key]
            if (setting !== settingsModel.value.find((setting) => setting.key === key).value) {
                modifedSettings[key] = setting
                formData.append(`setting[${key}]`, setting)
            }
        }
    }

    if (Object.keys(modifedSettings).length === 0) {
        toast(
            I18n.t('js.admin.settings.no_changes'), {
            class: [
                'c-notifier',
                'warning'
            ]
        }
        )
        return
    }

    btnLoading.value = true

    ajax.post('/admin/site_settings.json', formData)
        .then((response) => {
            btnLoading.value = false
            settingsModel.value.forEach((setting) => {
                if (modifedSettings.hasOwnProperty(setting.key)) {
                    setting.value = modifedSettings[setting.key]
                    settings[setting.key] = modifedSettings[setting.key]
                }
            })
            try {
                toast(
                    response.data.message, {
                    class: [
                        'm-notifier',
                        'success'
                    ]
                }
                )
            } catch (error) {
                //
            }

            for (const key in modifedSettings) {
                if (modifedSettings.hasOwnProperty(key)) {
                    const setting = settingsModel.value.find((setting) => setting.key === key);
                    if (setting && setting.options && setting.options.refresh) {
                        window.location.reload()
                        break
                    }
                }
            }

            // Update the settingsModel and settings ref with the new values





        })
        .catch((error) => {
            error = true
            btnLoading.value = false
            toast(
                I18n.t('js.core.generic_error')
            )
        })
}



function uploaderButton(form) {
    document.getElementById(`${form}`).click()
}

function handleImageChange(e) {
    const data = e.target.files[0]
    settings[`${e.target.id.replace("upload-", "")}`] = data
    const preview = document.getElementById(e.target.id.replace("upload-", "preview-"))
}

onMounted(() => {
    settingsModel.value = props.settingsData
    category.value = props.category

    settingsModel.value.forEach((setting) => {
        settings[setting.key] = setting.value
    })
})

onUpdated(() => {
    settingsModel.value = props.settingsData
    category.value = props.category

    settingsModel.value.forEach((setting) => {
        settings[setting.key] = setting.value
    })
})

</script>