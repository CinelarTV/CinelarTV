import { defineComponent, computed, ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { Menu, MenuButton, MenuItems, MenuItem } from '@headlessui/vue';
import { useSiteSettings } from '../../services/site-settings';
import { useCurrentUser } from '../../services/current-user';
import { ajax } from '../../../lib/Ajax';
import LoginModal from '../../../components/modals/login.modal.vue';
import SignupModal from '../../../components/modals/signup.modal.vue';

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

    const displayName = computed(() => {
      return currentUser?.current_profile?.name ||
        currentUser?.username ||
        currentUser?.email ||
        'Usuario';
    });

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
        await ajax.post('/session/deassign-profile.json', {
          user: { selected_profile_id: null }
        });
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

    const openLoginModal = () => {
      loginModal.value?.setIsOpen(true);
    };

    const openSignupModal = () => {
      signupModal.value?.setIsOpen(true);
    };

    const menuItemsConfig = computed<MenuItemType[]>(() => [
      {
        text: 'Mi Perfil',
        icon: 'user',
        href: '/profile',
        visible: true,
      },
      {
        text: 'Cambiar Perfil',
        icon: 'arrow-right-left',
        onClick: handleProfileSwitch,
        visible: true,
      },
      {
        text: 'Administrar suscripción',
        icon: 'credit-card',
        href: '/account/billing',
        visible: isMainProfile && siteSettings?.enable_subscription,
      },
      {
        text: 'Administrar contenido',
        icon: 'clapperboard',
        href: '/admin/content-manager',
        visible: Boolean(currentUser?.admin && isMainProfile)
      },
      {
        text: 'Configuración',
        icon: 'settings',
        href: '/account/preferences',
        visible: isMainProfile,
      },
      {
        text: 'Administrador',
        icon: 'wrench',
        href: '/admin',
        visible: Boolean(currentUser?.admin && isMainProfile)
      },
      {
        text: 'Mis Tickets',
        icon: 'help-circle',
        href: '/tickets',
        visible: isMainProfile,
      },
    ]);


    const handleProfileSelect = (profile: any) => {
      ajax.post('/user/select-profile.json', { profile_id: profile.id })
        .then(() => {
          window.location.href = '/';
        })
        .catch(console.log);
    };

    const visibleMenuItems = computed(() => menuItemsConfig.value.filter(item => item.visible));

    const checkAndOpenModal = async () => {
      await router.isReady();
      if (route.redirectedFrom && !currentUser) {
        const { path } = route.redirectedFrom;
        if (path === '/login') {
          openLoginModal();
        } else if (path === '/signup') {
          openSignupModal();
        }
      }
    };

    onMounted(() => {
      checkAndOpenModal();
    });

    return () => (
      <div>
        {currentUser ? (
          <Menu as="div" class="relative inline-block text-left">
            <MenuButton id="current-user">
              <img class="avatar" src={profileAvatar.value} alt={`Avatar de ${displayName.value}`} title={displayName.value} />
            </MenuButton>
            <transition
              enter-active-class="transition duration-100 ease-out"
              enter-from-class="transform scale-95 opacity-0"
              enter-to-class="transform scale-100 opacity-100"
              leave-active-class="transition duration-75 ease-out"
              leave-from-class="transform scale-100 opacity-100"
              leave-to-class="transform scale-95 opacity-0"
            >
              <MenuItems class="user-menu-items before:backdrop-blur-2xl rounded-xl shadow-xl p-4 sm:p-8 flex flex-col sm:flex-row min-w-[90vw] sm:min-w-[500px] max-w-full w-full sm:w-auto max-h-[90vh] overflow-y-auto">
                {/* Columna Mi cuenta */}
                <div class="flex-1 sm:pr-8 sm:border-r border-gray-700 w-full sm:w-auto mb-6 sm:mb-0">
                  <div class="mb-4 text-xs text-gray-400 tracking-widest font-semibold">MI CUENTA</div>
                  <ul>
                    {visibleMenuItems.value.map(item => (
                      <li key={item.text}>
                        {item.href ? (
                          <router-link to={item.href} class="menu-item">
                            <c-icon icon={item.icon} size={20} class="icon" />
                            <span class="ml-2">{item.text}</span>
                          </router-link>
                        ) : (
                          <button onClick={item.onClick} class="menu-item w-full text-left">
                            <c-icon icon={item.icon} size={20} class="icon" />
                            <span class="ml-2">{item.text}</span>
                          </button>
                        )}
                      </li>
                    ))}
                    <li>
                      <button onClick={handleLogout} class="menu-item w-full text-left">
                        <c-icon icon="log-out" size={20} class="icon" />
                        <span class="ml-2">Cerrar sesión</span>
                      </button>
                    </li>
                  </ul>
                </div>
                {/* Columna Perfiles */}
                <div class="flex-1 sm:pl-8 w-full sm:w-auto">
                  <div class="mb-4 text-xs text-gray-400 tracking-widest font-semibold">PERFILES</div>
                  <ul class="flex flex-col gap-2">
                    {currentUser.profiles?.map((profile: any) => (
                      <button class="flex items-center cursor-pointer group" key={profile.id}
                        onClick={() => handleProfileSelect(profile)}
                        aria-label={`Seleccionar perfil ${profile.name}`}
                      >
                        <img src={profile.avatar_id ? `/assets/default/avatars/${profile.avatar_id}.png` : '/assets/default/avatars/coolCat.png'} class="w-8 h-8 group-hover:saturate-[1.25] rounded-full mr-2" />
                        <span class="font-semibold text-zinc-100 group-hover:text-white">{profile.name}</span>
                      </button>
                    ))}
                    {/* Cambiar perfil */}
                    <li class="flex items-center cursor-pointer" onClick={handleProfileSwitch}>
                      <div class="w-8 h-8 rounded-full bg-gray-800 flex items-center justify-center mr-2">
                        <c-icon icon="arrow-right-left" size={20} class="icon text-white" />
                      </div>
                      <span class="font-semibold text-white">Cambiar perfil</span>
                    </li>
                    {currentUser.profiles?.length < 5 && (
                      <li class="flex items-center cursor-pointer" onClick={handleProfileSwitch}>
                        <div class="w-8 h-8 rounded-full bg-gray-800 flex items-center justify-center mr-2">
                          <c-icon icon="plus" size={20} class="icon text-white" />
                        </div>
                        <span class="font-semibold text-white">Añadir perfil</span>
                      </li>
                    )}
                  </ul>
                  <ul class="mt-4">
                    <li>
                      <router-link to="/profiles/edit" class="menu-item">
                        <c-icon icon="pencil" size={20} class="icon" />
                        <span class="ml-2">Editar perfiles</span>
                      </router-link>
                    </li>
                    <li>
                      <router-link to="/info" class="menu-item">
                        <c-icon icon="info" size={20} class="icon" />
                        <span class="ml-2">Más información</span>
                      </router-link>
                    </li>
                  </ul>
                </div>
              </MenuItems>
            </transition>
          </Menu>
        ) : (
          <div class="flex items-center space-x-2">
            {siteSettings.allow_registration && (
              <button onClick={openSignupModal} class="button" aria-label="Registrarse">
                Sign up
              </button>
            )}
            <button onClick={openLoginModal} class="button" aria-label="Iniciar sesión">
              <c-icon icon="user" size={20} class="icon" />
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
