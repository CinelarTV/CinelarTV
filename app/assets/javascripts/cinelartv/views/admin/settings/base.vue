<template>
    <div class="panel settings">
        <div class="panel-header">
            <div class="panel-title">
                <h1>{{ $t('js.admin.settings.title') }}</h1>
            </div>
        </div>
        <c-button @click="toggleSidebar" class="sidebar-toggle" v-if="isMobile">
            Alternar barra lateral
        </c-button>
        <div class="flex flex-row">
            <section class="sidebar" :class="sidebarOpened ? 'visible' : 's-hidden'">
                <c-button class="sidebar-toggle flex w-full rounded-none" icon="x" @click="toggleSidebar" v-if="isMobile">
                    Close
                </c-button>
                <div class="sidebar-content">
                    <div class="sidebar-body">
                        <ul class="nav nav-pills flex-column">
                            <li class="nav-item" v-for="category in categories" :key="category.name"
                                :class="{ active: currentCategory === category.name }"
                                @click="onCurrentCategoryChange(category.name)">
                                <c-icon :icon="getCategoryIcon(category.name)" class="icon" />
                                <a class="nav-link">
                                    {{ $t(`js.admin.settings.categories.${category.name}`) }}
                                </a>
                            </li>
                        </ul>
                    </div>
                </div>
            </section>
            <section class="main-content">
                <SiteSettingsIndex v-if="currentCategory && filteredSettings" :settingsData="filteredSettings"
                    :category="currentCategory" @current-category-change="onCurrentCategoryChange" />
            </section>
        </div>



    </div>
</template>

<script setup>


import { onMounted, computed } from 'vue'
import SiteSettingsIndex from './index.vue'
import { ref } from 'vue'
import { ajax } from '../../../lib/axios-setup';
import { useRoute, useRouter } from 'vue-router';

const categories = ref(null)
const currentCategory = ref(null)
const settingsData = ref([])
const sidebarOpened = ref(false)
const route = useRoute()
const router = useRouter()

var filteredSettings = computed(() => {
    if (!currentCategory.value) {
        return settingsData.value;
    }
    return settingsData.value.filter((setting) => setting.category === currentCategory.value);
});

const getCategoryIcon = (category) => {
    switch (category) {
        case 'general':
            return 'box';
        case 'content':
            return 'clapperboard';
        case 'player':
            return 'play-square';
        case 'monetization':
            return 'circle-dollar-sign';
        case 'storage':
            return 'hard-drive';
        case 'customization':
            return 'brush';
        case 'developer':
            return 'code2';
        case 'experimental':
            return 'test-tube2';
        default:
            return 'settings';
    }
}

const toggleSidebar = () => {
    sidebarOpened.value = !sidebarOpened.value
}

function getCategories() {
    const categories = {};
    settingsData.value.map((setting) => {
        const category = setting.category;
        if (!categories[category]) {
            categories[category] = [];
        }
        categories[category].push(setting);
    });
    return Object.entries(categories).map(([name, settings]) => {
        return { name, settings };
    });
}

const onCurrentCategoryChange = (value) => {
    router.replace(`/admin/site_settings/${value}`)
    currentCategory.value = value;
    sidebarOpened.value = false

}


onMounted(() => {
    ajax.get('/admin/site_settings.json').then((r) => {
        settingsData.value = r.data.site_settings
        filteredSettings.value = r.data.site_settings
        categories.value = getCategories()

        if(route.params.category){
            currentCategory.value = route.params.category
        } else {
            currentCategory.value = categories.value[0].name
            router.replace(`/admin/site_settings/${categories.value[0].name}`)
        }
    })
})
</script>
  
<script>


export default {
    name: 'AdminSettings',
    components: {
        SiteSettingsIndex
    },
    metaInfo: {
        title: 'Admin'
    },
    setup() {
        return {
            categories,
            currentCategory,
            filteredSettings,
            onCurrentCategoryChange,
        }
    },
}
</script>