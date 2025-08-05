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
  
<script setup lang="ts">
import { ref, getCurrentInstance, inject, onMounted, computed } from 'vue'
import { compile, h } from 'vue/dist/vue.esm-bundler';
import { useBanners } from '../app/services/banner-store';
import { useSiteSettings } from '../app/services/site-settings';
import { useCurrentUser } from '../app/services/current-user';

const { banners, addBanner } = useBanners()
const { siteSettings } = useSiteSettings()
const { currentUser } = useCurrentUser()

const { $t } = getCurrentInstance().appContext.config.globalProperties

onMounted(() => {
    // Add default banners
    addBanner({
        id: 'site-unconfigured',
        content: `${$t("js.admin.wizard_required")} [${$t("js.admin.wizard_link")}](/wizard)`,
        show: !siteSettings.wizard_completed && currentUser?.admin
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