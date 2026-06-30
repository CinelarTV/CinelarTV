import { computed, defineComponent } from 'vue';
import { RouterLink, useRoute } from 'vue-router';
import { useSiteSettings } from '@/app/services/site-settings';
import CIcon from '@/components/c-icon.vue';

type NavItem = {
    key: string;
    to: string;
    icon: string;
    label: string;
    match: (path: string) => boolean;
    enabled?: boolean;
};

export default defineComponent({
    name: 'MobileBottomNav',
    setup() {
        const route = useRoute();
        const { siteSettings } = useSiteSettings();

        const navItems = computed<NavItem[]>(() => {
            const items: NavItem[] = [
                {
                    key: 'home',
                    to: '/',
                    icon: 'home',
                    label: 'Inicio',
                    match: (path: string) => path === '/',
                },
                {
                    key: 'explore',
                    to: '/explore/browse',
                    icon: 'telescope',
                    label: 'Explorar',
                    match: (path: string) => path.startsWith('/explore'),
                },
                {
                    key: 'search',
                    to: '/search',
                    icon: 'search',
                    label: 'Buscar',
                    match: (path: string) => path.startsWith('/search'),
                },
                {
                    key: 'live-tv',
                    to: '/live_tv',
                    icon: 'cast',
                    label: 'Live TV',
                    enabled: Boolean(siteSettings?.enable_live_tv),
                    match: (path: string) => path.startsWith('/live_tv'),
                },
            ];

            return items.filter(item => item.enabled !== false);
        });

        const isActive = (item: NavItem) => item.match(route.path);
        const activeIndex = computed(() => {
            const index = navItems.value.findIndex(item => isActive(item));
            return index >= 0 ? index : 0;
        });

        return () => (
            <nav class="mobile-bottom-nav" aria-label="Navegacion principal movil">
                <div
                    class="mobile-bottom-nav__inner"
                    style={{
                        '--mobile-nav-count': String(navItems.value.length),
                        '--mobile-nav-active-index': String(activeIndex.value),
                        '--mobile-nav-gap': '6px',
                        '--mobile-nav-padding-x': '10px',
                    }}
                >
                    <span class="mobile-bottom-nav__active-pill" aria-hidden="true" />
                    {navItems.value.map(item => (
                        <RouterLink
                            key={item.key}
                            to={item.to}
                            class={[
                                'mobile-bottom-nav__item',
                                isActive(item) && 'mobile-bottom-nav__item--active',
                            ]}
                        >
                            <span class="mobile-bottom-nav__icon-wrap">
                                <CIcon icon={item.icon} size={22} class="icon mobile-bottom-nav__icon" />
                            </span>
                            <span class="mobile-bottom-nav__label">{item.label}</span>
                        </RouterLink>
                    ))}
                </div>
            </nav>
        );
    },
});
