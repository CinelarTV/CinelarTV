<template>
    <div id="global-alerts">
        <template v-for="banner in banners" :key="banner.id">
            <div :id="banner.id" :class="`mx-auto global-notice ${banner.id}`" v-if="banner.show">
                <span v-md.html.breaks.linkify v-emoji v-html="banner.content" />
            </div>
        </template>
    </div>
</template>
  
<script setup>
import { ref, getCurrentInstance, inject } from 'vue'
import { SiteSettings } from '../../pre-initializers/essentials-preload'
import { currentUser } from '../../pre-initializers/essentials-preload'

const { $t } = getCurrentInstance().appContext.config.globalProperties
const banners = ref([
    {
        id: 'anon-banner',
        content: 'You are browsing the site as an anonymous user, register to take full advantage 😁',
        show: !currentUser && SiteSettings.public_site
    },
    {
        id: 'site-banner',
        content: SiteSettings.site_banner_content,
        show: SiteSettings.show_site_banner
    },
    {
        id: 'site-unconfigured',
        content: `${$t("js.admin.wizard_required")} [${$t("js.admin.wizard_link")}](/wizard)`,
        show: !SiteSettings.wizard_completed && !SiteSettings.bypass_wizard_check && currentUser && currentUser.admin
    }
])

</script>