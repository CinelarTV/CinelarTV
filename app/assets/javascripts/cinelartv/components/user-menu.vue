<template>
    <Menu as="div" class="relative inline-block text-left" v-if="currentUser">
        <MenuButton id="current-user">
            <p class="user-name">
                {{ currentUser?.current_profile?.name || currentUser.display_name || currentUser.email }}
            </p>
            <img class="avatar" :src="getProfileAvatar(currentUser?.current_profile?.avatar_id)"
                :title="currentUser.display_name || currentUser.email" />
        </MenuButton>

        <!-- Use Vue's built-in <transition> element to add transitions. -->
        <transition enter-active-class="transition duration-100 ease-out" enter-from-class="transform scale-95 opacity-0"
            enter-to-class="transform scale-100 opacity-100" leave-active-class="transition duration-75 ease-out"
            leave-from-class="transform scale-100 opacity-100" leave-to-class="transform scale-95 opacity-0">
            <MenuItems class="user-menu-items">
                <div class="py-1">
                    <MenuItem v-slot="{ active }" as="li" v-for="i in menuItems" :key="i.text">
                    <template v-if="i.onClick">
                        <button @click="i.onClick" class="menu-item" :class='{ "bg-white bg-opacity-10": active }'>
                            <component :is="i.icon" :size="20" class="icon"></component>
                            <span class="ml-2 whitespace-nowrap">{{ i.text }}</span>
                        </button>
                    </template>
                    <template v-else-if="i.href">
                        <router-link v-if="i.visible" class="menu-item" :class='{ "bg-white bg-opacity-10": active }'
                            :to="i.href">
                            <component :is="i.icon" :size="20" class="icon"></component>
                            <span class="ml-2 whitespace-nowrap">{{ i.text }}</span>
                        </router-link>
                    </template>
                    </MenuItem>

                    <MenuItem as="li">
                    <button @click="userLogout()" id="logout-button" class="menu-item">
                        <LogOut :size="20" class="icon" />
                        <span class="ml-2 whitespace-nowrap">Cerrar sesión</span>
                    </button>
                    </MenuItem>
                </div>

                <!-- ... -->
            </MenuItems>
        </transition>
    </Menu>
    <div class="flex items-center space-x-2" v-else>
        <button @click="openSignupModal" class="button">
            <SignupModal ref="signupModal" />
            Sign up
        </button>
        <button @click="openLoginModal()" class="button">
            <LoginModal ref="loginModal" />
            <UserIcon :size="18" class="icon" />
            Login
        </button>
    </div>
</template>
  
  
<script setup>
import { inject, ref } from 'vue'
import { Menu, MenuButton, MenuItems, MenuItem } from '@headlessui/vue'
import LoginModal from './modals/login.modal.vue'
import { UserIcon, LogOut, CreditCardIcon, HelpCircleIcon } from 'lucide-vue-next'
import { WrenchIcon } from 'lucide-vue-next';
import { ClapperboardIcon } from 'lucide-vue-next';
import { ArrowRightLeftIcon } from 'lucide-vue-next';
import SignupModal from './modals/signup.modal.vue';

const currentUser = inject('currentUser')
const isMainProfile = ref(false)

isMainProfile.value = currentUser?.current_profile?.id === currentUser?.profiles[0]?.id

const getProfileAvatar = (avatar) => {
    const defaultAvatarList = [
        'coolCat',
        'cuteCat'
    ]

    if (!avatar) {
        avatar = 'default';
    }

    let avatarUrl;

    switch (avatar) {
        case 'default':
            let randomAvatar = defaultAvatarList[Math.floor(Math.random() * defaultAvatarList.length)];
            avatarUrl = `/assets/default/avatars/${randomAvatar}.png`;
            break;
        default:
            avatarUrl = `/assets/default/avatars/${avatar}.png`;
            break;
    }

    return avatarUrl;
}

const menuItems = ref([
    {
        text: 'Mi Perfil',
        icon: UserIcon,
        href: '/profile',
        visible: true
    },
    {
        text: 'Cambiar Perfil',
        icon: ArrowRightLeftIcon,
        onClick: () => {
            axios.post('/user/deassign-profile.json', {
                user: {
                    selected_profile_id: null
                }
            }).then((response) => {
                window.location.href = '/profiles/select';
            }).catch((error) => {
                console.log(error);
            });
        },
        visible: true
    },
    {
        text: 'Mis Suscripciones',
        icon: CreditCardIcon,
        href: '/subscriptions',
        visible: isMainProfile.value
    },
    {
        text: 'Administrar contenido',
        icon: ClapperboardIcon,
        href: '/admin/content-manager',
        visible: currentUser?.admin && isMainProfile.value
    },
    {
        text: 'Administrador',
        icon: WrenchIcon,
        href: '/admin',
        visible: currentUser?.admin && isMainProfile.value
    },
    {
        text: 'Mis Tickets',
        icon: HelpCircleIcon,
        href: '/tickets',
        visible: isMainProfile.value
    },
])

const loginModal = ref(null)
const signupModal = ref(null)


const openLoginModal = () => {
    loginModal.value.setIsOpen(true)
}

const openSignupModal = () => {
    signupModal.value.setIsOpen(true)
}

const userLogout = () => {
    axios.delete('/users/sign_out.json')
        .then(res => {
            window.location.href = '/'
        })
        .catch(err => {
            console.log(err)
        })
}


</script>