import { defineComponent, computed, ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { Menu, MenuButton, MenuItems, MenuItem } from '@headlessui/vue';
import { useSiteSettings } from '../../services/site-settings';
import { useCurrentUser } from '../../services/current-user';
import { ajax } from '../../../lib/Ajax';
import { LogOut, Pencil, Info, Plus } from 'lucide-vue-next';
import LoginModal from '../../../components/modals/login.modal.tsx';
import SignupModal from '../../../components/modals/signup.modal.tsx';
import CIcon from "@/components/c-icon.vue";

interface MenuItemType {
  text: string;
  icon: string;
  href?: string;
  onClick?: () => void;
  visible: boolean;
}

export default defineComponent({
  name: 'UserMenu',
  setup() {
    const route = useRoute();
    const router = useRouter();
    const { currentUser, isMainProfile } = useCurrentUser();
    const { siteSettings } = useSiteSettings();
    const loginModal = ref<any>(null);
    const signupModal = ref<any>(null);

    const displayName = computed(() =>
      currentUser?.current_profile?.name ||
      currentUser?.username ||
      currentUser?.email ||
      'Usuario'
    );

    const profileAvatar = computed(() => {
      const avatar = currentUser?.current_profile?.avatar_id;
      const defaultAvatars = ['coolCat', 'cuteCat'];
      const selectedAvatar = avatar || 'default';
      if (selectedAvatar === 'default') {
        const randomAvatar = defaultAvatars[Math.floor(Math.random() * defaultAvatars.length)];
        return `/assets/default/avatars/${randomAvatar}.png`;
      }
      return `/assets/default/avatars/${selectedAvatar}.png`;
    });

    const handleProfileSwitch = async () => {
      try {
        await ajax.post('/session/deassign-profile.json', { user: { selected_profile_id: null } });
        window.location.href = '/profiles/select';
      } catch (error) {
        console.error('Error switching profile:', error);
      }
    };

    const handleLogout = async () => {
      try {
        await ajax.delete('/logout.json');
        window.location.href = '/';
      } catch (error) {
        console.error('Error during logout:', error);
      }
    };

    const openLoginModal = () => loginModal.value?.setIsOpen(true);
    const openSignupModal = () => signupModal.value?.setIsOpen(true);

    const menuItemsConfig = computed<MenuItemType[]>(() => [
      { text: 'Mi Perfil', icon: 'user', href: '/profile', visible: true },
      { text: 'Administrar suscripción', icon: 'credit-card', href: '/account/billing', visible: isMainProfile && siteSettings?.enable_subscription },
      { text: 'Administrar contenido', icon: 'clapperboard', href: '/admin/content-manager', visible: Boolean(currentUser?.admin && isMainProfile) },
      { text: 'Configuración', icon: 'settings', href: '/account/preferences', visible: isMainProfile },
      { text: 'Administrador', icon: 'wrench', href: '/admin', visible: Boolean(currentUser?.admin && isMainProfile) },
      { text: 'Mis Tickets', icon: 'help-circle', href: '/tickets', visible: isMainProfile },
    ]);

    const visibleMenuItems = computed(() => menuItemsConfig.value.filter(item => item.visible));

    const handleProfileSelect = (profile: any) => {
      ajax.post('/user/select-profile.json', { profile_id: profile.id })
        .then(() => { window.location.href = '/'; })
        .catch(console.log);
    };

    const checkAndOpenModal = async () => {
      await router.isReady();
      if (route.redirectedFrom && !currentUser) {
        const { path } = route.redirectedFrom;
        if (path === '/login' || path === '/users/sign_in') openLoginModal();
        else if (path === '/signup') openSignupModal();
      }
    };

    onMounted(() => { checkAndOpenModal(); });

    const avatarUrl = (avatarId?: string) =>
      avatarId
        ? `/assets/default/avatars/${avatarId}.png`
        : '/assets/default/avatars/coolCat.png';

    return () => (
      <div>
        {currentUser ? (
          <Menu as="div" class="relative">

            {/* Trigger */}
            <MenuButton class="site-header__user-trigger">
              <img
                src={profileAvatar.value}
                alt={`Avatar de ${displayName.value}`}
                title={displayName.value}
                class="site-header__user-avatar"
              />
            </MenuButton>

            {/* Dropdown */}
            <MenuItems class="site-header__dropdown">

              {/* User header strip */}
              <div class="site-header__dropdown-user">
                <img
                  src={profileAvatar.value}
                  class="site-header__dropdown-avatar"
                />
                <div class="site-header__dropdown-user-info">
                  <p class="site-header__dropdown-user-name">
                    {displayName.value}
                  </p>
                  <p class="site-header__dropdown-user-email">
                    {currentUser.email}
                  </p>
                </div>
              </div>

              {/* Two-column body */}
              <div class="site-header__dropdown-body">

                {/* Column: Mi cuenta */}
                <div class="site-header__dropdown-column">
                  <p class="site-header__dropdown-label">
                    Mi cuenta
                  </p>
                  <ul class="site-header__dropdown-list">
                    {visibleMenuItems.value.map(item => (
                      <li key={item.text}>
                        {item.href ? (
                          <router-link
                            to={item.href}
                            class="site-header__dropdown-item"
                          >
                            <CIcon icon={item.icon} size={16} class="icon" />
                            {item.text}
                          </router-link>
                        ) : (
                          <button
                            onClick={item.onClick}
                            class="site-header__dropdown-item"
                          >
                            <CIcon icon={item.icon} size={16} class="icon" />
                            {item.text}
                          </button>
                        )}
                      </li>
                    ))}

                    {/* Divider + Logout */}
                    <li>
                      <div class="site-header__dropdown-divider" />
                    </li>
                    <li>
                      <button
                        onClick={handleLogout}
                        class="site-header__dropdown-item site-header__dropdown-item--danger"
                      >
                        <LogOut size={16} class="icon" />
                        Cerrar sesión
                      </button>
                    </li>
                  </ul>
                </div>

                {/* Column: Perfiles */}
                <div class="site-header__dropdown-column">
                  <p class="site-header__dropdown-label">
                    Perfiles
                  </p>
                  <ul class="site-header__dropdown-list">
                    {currentUser.profiles?.map((profile: any) => (
                      <li key={profile.id}>
                        <button
                          onClick={() => handleProfileSelect(profile)}
                          aria-label={`Seleccionar perfil ${profile.name}`}
                          class="site-header__dropdown-item"
                        >
                          <img
                            src={avatarUrl(profile.avatar_id)}
                            class="site-header__dropdown-profile-avatar"
                          />
                          <span class="truncate font-medium">{profile.name}</span>
                        </button>
                      </li>
                    ))}

                    {currentUser.profiles?.length < 5 && (
                      <li>
                        <button
                          onClick={handleProfileSwitch}
                          class="site-header__dropdown-item"
                        >
                          <span class="site-header__dropdown-add-badge">
                            <Plus size={13} />
                          </span>
                          Añadir perfil
                        </button>
                      </li>
                    )}
                  </ul>

                  {/* Secondary links */}
                  <ul class="site-header__dropdown-list" style="margin-top: 4px; padding-top: 4px; border-top: 1px solid var(--c-border-subtle);">
                    <li>
                      <router-link
                        to="/profiles/edit"
                        class="site-header__dropdown-item"
                      >
                        <Pencil size={16} class="icon" />
                        Editar perfiles
                      </router-link>
                    </li>
                    <li>
                      <router-link
                        to="/info"
                        class="site-header__dropdown-item"
                      >
                        <Info size={16} class="icon" />
                        Más información
                      </router-link>
                    </li>
                  </ul>
                </div>

              </div>
            </MenuItems>
          </Menu>
        ) : (
          <div class="site-header__auth">
            {siteSettings.allow_registration && (
              <button
                onClick={openSignupModal}
                aria-label="Registrarse"
                class="site-header__auth-signup"
              >
                Sign up
              </button>
            )}
            <button
              onClick={openLoginModal}
              aria-label="Iniciar sesión"
              class="site-header__auth-login"
            >
              <CIcon icon="user" size={16} class="shrink-0" />
              Login
            </button>
            <LoginModal ref={loginModal} />
            {siteSettings.allow_registration && <SignupModal ref={signupModal} />}
          </div>
        )}
      </div>
    );
  }
});
