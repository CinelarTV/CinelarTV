import { defineComponent, computed, ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { Menu, MenuButton, MenuItems, MenuItem } from '@headlessui/vue';
import { useSiteSettings } from '../../services/site-settings';
import { useCurrentUser } from '../../services/current-user';
import { ajax } from '../../../lib/Ajax';
import { LogOut, Pencil, Info, Plus, ArrowRightLeft } from 'lucide-vue-next';
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
        if (path === '/login') openLoginModal();
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
            <MenuButton
              id="current-user"
              class="group flex items-center gap-2.5 rounded-full p-0.5 transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--c-tertiary-color)]"
            >
              <img
                src={profileAvatar.value}
                alt={`Avatar de ${displayName.value}`}
                title={displayName.value}
                class="h-9 w-9 rounded-full object-cover ring-2 ring-[var(--c-primary-300)] transition-all group-hover:ring-[var(--c-tertiary-color)]"
              />
            </MenuButton>

            {/* Dropdown */}
            <transition
              enterActiveClass="transition duration-150 ease-out"
              enterFromClass="opacity-0 scale-95 -translate-y-1"
              enterToClass="opacity-100 scale-100 translate-y-0"
              leaveActiveClass="transition duration-100 ease-in"
              leaveFromClass="opacity-100 scale-100 translate-y-0"
              leaveToClass="opacity-0 scale-95 -translate-y-1"
            >
              <MenuItems class="absolute right-0 mt-2 w-[min(92vw,520px)] origin-top-right rounded-2xl bg-[var(--c-primary-100)] ring-1 ring-[var(--c-primary-300)] shadow-2xl backdrop-blur-xl focus:outline-none overflow-hidden z-50">

                {/* User header strip */}
                <div class="flex items-center gap-3 px-5 py-4 border-b border-[var(--c-primary-200)]">
                  <img
                    src={profileAvatar.value}
                    class="h-10 w-10 rounded-full object-cover ring-2 ring-[var(--c-primary-300)]"
                  />
                  <div class="min-w-0">
                    <p class="truncate text-sm font-semibold text-[var(--c-body-text-color)]">
                      {displayName.value}
                    </p>
                    <p class="truncate text-xs text-[var(--c-primary-900)]">
                      {currentUser.email}
                    </p>
                  </div>
                </div>

                {/* Two-column body */}
                <div class="flex flex-col sm:flex-row">

                  {/* Column: Mi cuenta */}
                  <div class="flex-1 px-3 py-3 sm:border-r border-[var(--c-primary-200)]">
                    <p class="px-2 pb-2 text-[10px] font-semibold uppercase tracking-widest text-[var(--c-primary-900)]">
                      Mi cuenta
                    </p>
                    <ul class="flex flex-col gap-0.5">
                      {visibleMenuItems.value.map(item => (
                        <li key={item.text}>
                          {item.href ? (
                            <router-link
                              to={item.href}
                              class="flex items-center gap-2.5 rounded-lg px-2 py-2 text-sm text-[var(--c-body-text-color)] transition-colors hover:bg-[var(--c-primary-200)] hover:text-[var(--c-tertiary-color)]"
                            >
                              <c-icon icon={item.icon} size={16} class="shrink-0 opacity-60" />
                              {item.text}
                            </router-link>
                          ) : (
                            <button
                              onClick={item.onClick}
                              class="flex w-full items-center gap-2.5 rounded-lg px-2 py-2 text-left text-sm text-[var(--c-body-text-color)] transition-colors hover:bg-[var(--c-primary-200)] hover:text-[var(--c-tertiary-color)]"
                            >
                              <c-icon icon={item.icon} size={16} class="shrink-0 opacity-60" />
                              {item.text}
                            </button>
                          )}
                        </li>
                      ))}

                      {/* Divider + Logout */}
                      <li class="mt-1 pt-1 border-t border-[var(--c-primary-200)]">
                        <button
                          onClick={handleLogout}
                          class="flex w-full items-center gap-2.5 rounded-lg px-2 py-2 text-left text-sm text-rose-400 transition-colors hover:bg-rose-500/10"
                        >
                          <LogOut size={16} class="shrink-0" />
                          Cerrar sesión
                        </button>
                      </li>
                    </ul>
                  </div>

                  {/* Column: Perfiles */}
                  <div class="flex-1 px-3 py-3 border-t sm:border-t-0 border-[var(--c-primary-200)]">
                    <p class="px-2 pb-2 text-[10px] font-semibold uppercase tracking-widest text-[var(--c-primary-900)]">
                      Perfiles
                    </p>
                    <ul class="flex flex-col gap-0.5">
                      {currentUser.profiles?.map((profile: any) => (
                        <li key={profile.id}>
                          <button
                            onClick={() => handleProfileSelect(profile)}
                            aria-label={`Seleccionar perfil ${profile.name}`}
                            class="flex w-full items-center gap-2.5 rounded-lg px-2 py-2 text-sm text-[var(--c-body-text-color)] transition-colors hover:bg-[var(--c-primary-200)] hover:text-[var(--c-tertiary-color)]"
                          >
                            <img
                              src={avatarUrl(profile.avatar_id)}
                              class="h-6 w-6 rounded-full object-cover ring-1 ring-[var(--c-primary-300)]"
                            />
                            <span class="truncate font-medium">{profile.name}</span>
                          </button>
                        </li>
                      ))}

                      {currentUser.profiles?.length < 5 && (
                        <li>
                          <button
                            onClick={handleProfileSwitch}
                            class="flex w-full items-center gap-2.5 rounded-lg px-2 py-2 text-sm text-[var(--c-primary-900)] transition-colors hover:bg-[var(--c-primary-200)] hover:text-[var(--c-body-text-color)]"
                          >
                            <span class="flex h-6 w-6 items-center justify-center rounded-full bg-[var(--c-primary-300)]">
                              <Plus size={13} />
                            </span>
                            Añadir perfil
                          </button>
                        </li>
                      )}
                    </ul>

                    {/* Secondary links */}
                    <ul class="mt-1 pt-1 border-t border-[var(--c-primary-200)] flex flex-col gap-0.5">
                      <li>
                        <router-link
                          to="/profiles/edit"
                          class="flex items-center gap-2.5 rounded-lg px-2 py-2 text-sm text-[var(--c-body-text-color)] transition-colors hover:bg-[var(--c-primary-200)] hover:text-[var(--c-tertiary-color)]"
                        >
                          <Pencil size={16} class="shrink-0 opacity-60" />
                          Editar perfiles
                        </router-link>
                      </li>
                      <li>
                        <router-link
                          to="/info"
                          class="flex items-center gap-2.5 rounded-lg px-2 py-2 text-sm text-[var(--c-body-text-color)] transition-colors hover:bg-[var(--c-primary-200)] hover:text-[var(--c-tertiary-color)]"
                        >
                          <Info size={16} class="shrink-0 opacity-60" />
                          Más información
                        </router-link>
                      </li>
                    </ul>
                  </div>

                </div>
              </MenuItems>
            </transition>
          </Menu>
        ) : (
          <div class="flex items-center gap-2">
            {siteSettings.allow_registration && (
              <button
                onClick={openSignupModal}
                aria-label="Registrarse"
                class="rounded-lg border border-[var(--c-primary-300)] bg-transparent px-4 py-1.5 text-sm font-medium text-[var(--c-body-text-color)] transition-colors hover:bg-[var(--c-primary-200)]"
              >
                Sign up
              </button>
            )}
            <button
              onClick={openLoginModal}
              aria-label="Iniciar sesión"
              class="flex items-center gap-2 rounded-lg bg-[var(--c-tertiary-color)] px-4 py-1.5 text-sm font-semibold text-white transition-colors hover:bg-[var(--c-tertiary-100)]"
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