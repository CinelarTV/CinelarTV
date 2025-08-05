import { defineComponent } from 'vue';
import { useSiteSettings } from '../app/services/site-settings';
import LoginModal from './modals/login.modal.vue';
import UserMenu from '../app/components/header/UserMenu';

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
                        <router-link to="/">
                            <img id="site-logo" src={siteSettings.site_logo} alt={`${siteSettings.site_name} logo`} />
                        </router-link>
                    </div>
                    <div class="site-navigation--nav hidden-sm-and-down" role="navigation">
                        {filteredHeaderItems.map(item => (
                            <router-link to={item.to} class="flex site-nav--btn" key={item.to}>
                                <c-icon icon={item.icon} size={20} class="icon" />
                                {item.title}
                            </router-link>
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