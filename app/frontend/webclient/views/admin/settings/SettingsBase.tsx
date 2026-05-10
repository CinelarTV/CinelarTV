import { defineComponent, ref, computed, onMounted, getCurrentInstance } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ajax } from '../../../lib/Ajax';
import CIcon from '@/components/c-icon.vue';
import SettingsPanel from './SettingsPanel';

interface Setting {
    key: string;
    type: string;
    value: any;
    label?: string;
    options?: any;
    category?: string;
}

interface Category {
    name: string;
    settings: Setting[];
}

export default defineComponent({
    name: 'SettingsBase',
    components: {
        SettingsPanel,
    },
    setup() {
        const categories = ref<Category[]>([]);
        const currentCategory = ref<string | null>(null);
        const settingsData = ref<Setting[]>([]);
        const sidebarOpened = ref(false);
        const isMobile = ref(false);
        const route = useRoute();
        const router = useRouter();

        // Get I18n translation function
        const { $t } = getCurrentInstance()!.appContext.config.globalProperties;

        const filteredSettings = computed(() => {
            if (!currentCategory.value) return settingsData.value;
            return settingsData.value.filter((setting) => setting.category === currentCategory.value);
        });

        const getCategoryIconName = (category: string): string => {
            const iconMap: Record<string, string> = {
                general: 'box',
                security: 'shield-check',
                content: 'clapperboard',
                maintenance: 'wrench',
                cinelar_intelligence: 'sparkles',
                player: 'play-square',
                monetization: 'circle-dollar-sign',
                storage: 'hard-drive',
                customization: 'brush',
                developer: 'code2',
                experimental: 'test-tube2',
            };
            return iconMap[category] || 'settings';
        };

        const toggleSidebar = () => {
            sidebarOpened.value = !sidebarOpened.value;
        };

        const onCategoryChange = (value: string) => {
            router.replace(`/admin/site_settings/${value}`);
            currentCategory.value = value;
            sidebarOpened.value = false;
        };

        const getCategories = (): Category[] => {
            const cats: Record<string, Setting[]> = {};
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
                    currentCategory.value = route.params.category as string;
                } else if (categories.value.length > 0) {
                    currentCategory.value = categories.value[0].name;
                    router.replace(`/admin/site_settings/${categories.value[0].name}`);
                }
            } catch (error) {
                console.error('Failed to load settings:', error);
            }
        });

        return () => (
            <div class="admin-settings">
                {/* Mobile sidebar toggle */}
                {isMobile.value && (
                    <button class="settings__sidebar-toggle" onClick={toggleSidebar}>
                        <CIcon icon={sidebarOpened.value ? 'x' : 'menu'} size={20} />
                    </button>
                )}

                {/* Sidebar */}
                <aside class={`settings__sidebar ${sidebarOpened.value ? 'settings__sidebar--open' : ''}`}>
                    <nav class="settings__sidebar-nav">
                        {categories.value.map((cat) => (
                            <button
                                key={cat.name}
                                class={`settings__sidebar-item ${currentCategory.value === cat.name ? 'settings__sidebar-item--active' : ''}`}
                                onClick={() => onCategoryChange(cat.name)}
                            >
                                <CIcon icon={getCategoryIconName(cat.name)} size={18} />
                                <span class="settings__sidebar-label">
                                    {$t(`js.admin.settings.categories.${cat.name}`) || cat.name}
                                </span>
                                <span class="settings__sidebar-count">{cat.settings.length}</span>
                            </button>
                        ))}
                    </nav>
                </aside>

                {/* Overlay for mobile */}
                {isMobile.value && sidebarOpened.value && (
                    <div class="settings__overlay" onClick={toggleSidebar} />
                )}

                {/* Main content */}
                <main class="settings__main">
                    {currentCategory.value && filteredSettings.value.length > 0 && (
                        <SettingsPanel settingsData={filteredSettings.value} category={currentCategory.value} />
                    )}
                </main>
            </div>
        );
    },
});
