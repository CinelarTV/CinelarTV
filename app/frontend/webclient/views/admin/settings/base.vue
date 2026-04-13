<template>
    <div class="admin-settings">
        <!-- Mobile sidebar toggle -->
        <button v-if="isMobile" class="settings__sidebar-toggle" @click="toggleSidebar">
            <CIcon :icon="sidebarOpened ? 'x' : 'menu'" size={20} />
        </button>

        <!-- Sidebar -->
        <aside class="settings__sidebar" :class="sidebarOpened ? 'settings__sidebar--open' : ''">

            <nav class="settings__sidebar-nav">
                <button v-for="cat in categories" :key="cat.name" class="settings__sidebar-item"
                    :class="{ 'settings__sidebar-item--active': currentCategory === cat.name }"
                    @click="onCategoryChange(cat.name)">
                    <component :is="getCategoryIconComponent(cat.name)" :size="18" />
                    <span class="settings__sidebar-label">
                        {{ $t(`js.admin.settings.categories.${cat.name}`) || cat.name }}
                    </span>
                    <span class="settings__sidebar-count">{{ cat.settings.length }}</span>
                </button>
            </nav>
        </aside>

        <!-- Overlay for mobile -->
        <div v-if="isMobile && sidebarOpened" class="settings__overlay" @click="toggleSidebar" />

        <!-- Main content -->
        <main class="settings__main">
            <SettingsPanel v-if="currentCategory && filteredSettings.length" :settingsData="filteredSettings"
                :category="currentCategory" />
        </main>
    </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ajax } from '../../../lib/Ajax';
import CIcon from '@/components/c-icon.vue';
import SettingsPanel from './SettingsPanel.tsx';
import {
    Settings,
    Box,
    Clapperboard,
    PlaySquare,
    CircleDollarSign,
    HardDrive,
    Brush,
    Code2,
    TestTube2,
} from 'lucide-vue-next';

const categories = ref([]);
const currentCategory = ref(null);
const settingsData = ref([]);
const sidebarOpened = ref(false);
const isMobile = ref(false);
const route = useRoute();
const router = useRouter();

const filteredSettings = computed(() => {
    if (!currentCategory.value) return settingsData.value;
    return settingsData.value.filter((setting) => setting.category === currentCategory.value);
});

const getCategoryIconComponent = (category) => {
    const iconMap = {
        general: Box,
        content: Clapperboard,
        player: PlaySquare,
        monetization: CircleDollarSign,
        storage: HardDrive,
        customization: Brush,
        developer: Code2,
        experimental: TestTube2,
    };
    return iconMap[category] || Settings;
};

const toggleSidebar = () => {
    sidebarOpened.value = !sidebarOpened.value;
};

const onCategoryChange = (value) => {
    router.replace(`/admin/site_settings/${value}`);
    currentCategory.value = value;
    sidebarOpened.value = false;
};

const getCategories = () => {
    const cats = {};
    settingsData.value.forEach((setting) => {
        const category = setting.category;
        if (!cats[category]) cats[category] = [];
        cats[category].push(setting);
    });
    return Object.entries(cats).map(([name, settings]) => ({ name, settings }));
};

const checkMobile = () => {
    isMobile.value = window.innerWidth < 768;
};

onMounted(async () => {
    checkMobile();
    window.addEventListener('resize', checkMobile);

    try {
        const response = await ajax.get('/admin/site_settings.json');
        settingsData.value = response.data.site_settings;
        categories.value = getCategories();

        if (route.params.category) {
            currentCategory.value = route.params.category;
        } else if (categories.value.length > 0) {
            currentCategory.value = categories.value[0].name;
            router.replace(`/admin/site_settings/${categories.value[0].name}`);
        }
    } catch (error) {
        console.error('Failed to load settings:', error);
    }
});
</script>
