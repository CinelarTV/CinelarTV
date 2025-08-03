<template>
  <Menu as="div" class="relative inline-block text-left" v-if="currentUser">
    <MenuButton id="current-user">
      <p class="user-name">
        {{ currentUser?.current_profile?.name || currentUser.username || currentUser.email }}
      </p>
      <img class="avatar" :src="getProfileAvatar(currentUser?.current_profile?.avatar_id)"
        :title="currentUser?.current_profile?.name || currentUser.email" />
    </MenuButton>

    <transition enter-active-class="transition duration-100 ease-out" enter-from-class="transform scale-95 opacity-0"
      enter-to-class="transform scale-100 opacity-100" leave-active-class="transition duration-75 ease-out"
      leave-from-class="transform scale-100 opacity-100" leave-to-class="transform scale-95 opacity-0">
      <MenuItems class="user-menu-items">
        <div class="py-1">
          <MenuItem v-slot="{ active }" as="li" v-for="i in menuItems" :key="i.text">
            <template v-if="i.onClick">
              <button @click="i.onClick" class="menu-item" :class='{ "bg-white bg-opacity-10": active }'>
                <c-icon :icon="i.icon" :size="20" class="icon"></c-icon>
                <span class="whitespace-nowrap">{{ i.text }}</span>
              </button>
            </template>
            <template v-else-if="i.href">
              <router-link v-if="i.visible" class="menu-item" :class='{ "bg-white bg-opacity-10": active }' :to="i.href">
                <c-icon :icon="i.icon" :size="20" class="icon"></c-icon>
                <span class="whitespace-nowrap">{{ i.text }}</span>
              </router-link>
            </template>
          </MenuItem>

          <MenuItem as="li">
            <button @click="userLogout()" id="logout-button" class="menu-item">
              <c-icon icon="log-out" :size="20" class="icon"></c-icon>
              <span class="whitespace-nowrap">Cerrar sesión</span>
            </button>
          </MenuItem>
        </div>
      </MenuItems>
    </transition>
  </Menu>
  <div class="flex items-center space-x-2" v-else>
    <button @click="openSignupModal" class="button" v-if="siteSettings.allow_registration">
      <SignupModal ref="signupModal" />
      Sign up
    </button>
    <button @click="openLoginModal()" class="button">
      <LoginModal ref="loginModal" />
      <c-icon icon="user" :size="20" class="icon" />
      Login
    </button>
  </div>
</template>

<script setup lang="ts">
import { useSiteSettings } from '../../services/site-settings'
import { ref, onMounted } from 'vue'
import { Menu, MenuButton, MenuItems, MenuItem } from '@headlessui/vue'
import LoginModal from '../../../components/modals/login.modal.vue'
import SignupModal from '../../../components/modals/signup.modal.vue'
import { useRoute, useRouter } from 'vue-router'
import { useCurrentUser } from '../../services/current-user';
import { ajax } from '../../../lib/Ajax'

const { currentUser, isMainProfile } = useCurrentUser()
const { siteSettings } = useSiteSettings()

const loginModal = ref<any>(null)
const signupModal = ref<any>(null)

const getProfileAvatar = (avatar: string | undefined) => {
  const defaultAvatarList = ['coolCat', 'cuteCat']
  const selectedAvatar = avatar || 'default'
  const randomAvatar = defaultAvatarList[Math.floor(Math.random() * defaultAvatarList.length)]
  return `/assets/default/avatars/${selectedAvatar === 'default' ? randomAvatar : selectedAvatar}.png`
}

const menuItems = ref([
  {
    text: 'Mi Perfil',
    icon: 'user',
    href: '/profile',
    visible: true,
  },
  {
    text: 'Cambiar Perfil',
    icon: 'arrow-right-left',
    onClick: () => {
      ajax.post('/user/deassign-profile.json', {
        user: {
          selected_profile_id: null,
        },
      })
        .then(() => {
          window.location.href = '/profiles/select'
        })
        .catch((error) => {
          console.log(error)
        })
    },
    visible: true,
  },
  {
    text: 'Administrar suscripción',
    icon: 'credit-card',
    href: '/account/billing',
    visible: isMainProfile && siteSettings.enable_subscription,
  },
  {
    text: 'Administrar contenido',
    icon: 'clapperboard',
    href: '/admin/content-manager',
    visible: currentUser?.admin && isMainProfile
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
    visible: currentUser?.admin && isMainProfile
  },
  {
    text: 'Mis Tickets',
    icon: 'help-circle',
    href: '/tickets',
    visible: isMainProfile,
  },
])

const { openLoginModal, openSignupModal, userLogout, checkRenderModal } = createMethods()

onMounted(async () => {
  // Wait for route to be ready
  await checkRenderModal()
})

function createMethods() {
  const route = useRoute()
  const router = useRouter()

  const openLoginModal = () => {
    loginModal.value.setIsOpen(true)
  }

  const openSignupModal = () => {
    signupModal.value.setIsOpen(true)
  }

  const checkRenderModal = async () => {
    await router.isReady()
    if (route.redirectedFrom) {
      if(currentUser) return
      if (route.redirectedFrom.path === '/login') {
        openLoginModal()
      }
      if (route.redirectedFrom.path === '/signup') {
        openSignupModal()
      }
    }
  }

  const userLogout = () => {
    ajax.delete('/logout.json')
      .then(() => {
        window.location.href = '/'
      })
      .catch((error) => {
        console.log(error)
      })
  }

  return { openLoginModal, openSignupModal, userLogout, checkRenderModal }
}
</script>
