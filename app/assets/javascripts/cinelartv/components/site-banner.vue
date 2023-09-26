<template>
    <div id="global-alerts" v-if="banners.length > 0 && $route.meta.showHeader !== false">
        <template v-for="banner in banners" :key="banner.id">
            <template v-if="banner.customHtml">
                <div :id="banner.id" :class="`${banner.id}`" v-if="banner.show">
                    <div v-html="banner.customHtml" />
                </div>
            </template>
            <div :id="banner.id" :class="`mx-auto global-notice ${banner.id}`" v-if="banner.show && !banner.customHtml">
                <span v-html="banner.content" />
            </div>
        </template>
    </div>
</template>
  
<script setup>
import { ref, getCurrentInstance, inject, onMounted, computed } from 'vue'
import { compile, h } from 'vue/dist/vue.esm-bundler';
import { useGlobalStore } from '../store/global'

const globalStore = useGlobalStore()

const SiteSettings = inject('SiteSettings')
const currentUser = inject('currentUser')
const { $t } = getCurrentInstance().appContext.config.globalProperties

const banners = computed(() => globalStore.banners)

onMounted(() => {
    // Add default banners
    banners.value.push({
        id: 'site-unconfigured',
        content: `${$t("js.admin.wizard_required")} [${$t("js.admin.wizard_link")}](/wizard)`,
        show: !SiteSettings.wizard_completed && currentUser?.admin
    })
})

const runtimeCompiler = (html) => {
    let componentToRender = h({
        render: compile(html),
    })

    console.log(componentToRender)

    return componentToRender

}



</script>