import { defineComponent } from 'vue';
import { useSiteSettings } from '../app/services/site-settings';
import LoginModal from './modals/login.modal.vue';
import UserMenu from '../app/components/header/UserMenu';
import CIcon from "./c-icon.vue";
import { RouterLink } from "vue-router";

const headerItems = [
    { to: '/', title: 'Explorar', icon: 'compass', showItem: true },
    { to: '/search', title: 'Buscar', icon: 'search', showItem: true },
    { to: '/collections', title: 'Mi Colección', icon: 'bookmark', showItem: true },
];

export default defineComponent({
    name: 'SiteHeader',
    setup() {
        const { siteSettings } = useSiteSettings();
        const filteredHeaderItems = headerItems.filter(item => item.showItem);

        return () => (
            <header id="site-header">
                <div class="site-header-wrap">
                    <div class="title">
                        <RouterLink to="/">
                            <img id="site-logo" src={siteSettings.site_logo} alt={`${siteSettings.site_name} logo`} />
                        </RouterLink>
                    </div>
                    <div class="site-navigation--nav hidden-sm-and-down" role="navigation">
                        {filteredHeaderItems.map(item => (
                            <RouterLink to={item.to} class="flex site-nav--btn" key={item.to}>
                                <CIcon icon={item.icon} size={20} class="icon" />
                                {item.title}
                            </RouterLink>
                        ))}
                    </div>
                    <div class="header-user-panel--nav">
                        <UserMenu />
                        <LoginModal />
                    </div>
                </div>
            </header>
        );
    }
});