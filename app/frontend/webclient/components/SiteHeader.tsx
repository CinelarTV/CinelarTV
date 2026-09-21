import { defineComponent, ref, onMounted, onUnmounted } from 'vue';
import { useSiteSettings } from '../app/services/site-settings';
import LoginModal from './modals/login.modal.tsx';
import UserMenu from '../app/components/header/UserMenu';
import CIcon from "./c-icon.vue";
import { RouterLink } from "vue-router";

const headerItems = [
    { to: '/', title: 'Inicio', icon: 'home', showItem: true },
    { to: '/explore/browse', title: 'Explorar', icon: 'telescope', showItem: true },
    { to: '/search', title: 'Buscar', icon: 'search', showItem: true },
    { to: '/collections', title: 'Mi Colección', icon: 'bookmark', showItem: true },
];

export default defineComponent({
    name: 'SiteHeader',
    setup() {
        const { siteSettings } = useSiteSettings();
        const filteredHeaderItems = headerItems.filter(item => item.showItem);
        const scrolled = ref(false);

        const onScroll = () => {
            scrolled.value = window.scrollY > 40;
        };

        onMounted(() => {
            window.addEventListener('scroll', onScroll, { passive: true });
            onScroll();
        });

        onUnmounted(() => {
            window.removeEventListener('scroll', onScroll);
        });

        return () => (
            <header class={`site-header ${scrolled.value ? 'site-header--scrolled' : ''}`}>
                <div class="site-header__wrap">
                    <RouterLink to="/" class="site-header__logo">
                        <img class="site-header__logo-img" src={siteSettings.site_logo} alt={`${siteSettings.site_name} logo`} />
                    </RouterLink>

                    <nav class="site-header__nav hidden-sm-and-down" role="navigation">
                        {filteredHeaderItems.map(item => (
                            <RouterLink
                                to={item.to}
                                class="site-header__nav-item"
                                key={item.to}
                            >
                                <CIcon icon={item.icon} size={18} class="icon" />
                                {item.title}
                            </RouterLink>
                        ))}
                    </nav>

                    <div class="site-header__right">
                        <UserMenu />
                        <LoginModal />
                    </div>
                </div>
            </header>
        );
    }
});
