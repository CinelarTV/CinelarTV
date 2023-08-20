<template>
    <div id="profile-selector">
        <div class="h-screen
         flex flex-col items-center justify-center">
            <img :src="SiteSettings.site_logo" class="h-8" />
            <h1 class="text-2xl font-bold mt-6 mb-16" v-emoji>
                ¿Quién eres? 🍿
            </h1>
            <div class="mt-4 mb-12 md:mb-32 grid grid-cols-2 space-x-4 md:flex md:flex-row md:space-x-8">
                <template v-for="profile in currentUser.profiles">
                    <div :class="`profile-card ${editMode ? 'editing' : ''}`" @keydown="e => handleKeyDown(e, profile)"
                        @click="selectProfile(profile)" tabindex="0" role="button"
                        aria-label="Seleccionar perfil {{ profile.name }}">
                        <img :src="getProfileAvatar(profile.avatar_id)" class="profile-avatar"
                            alt="Avatar de perfil {{ profile.name }}" />
                        <h2 class="profile-name">{{ profile.name }}</h2>
                        <div v-if="editMode" class="flex flex-row space-x-2 relative top-0 mt-2 right-0">
                            <button class="button" @click="deleteProfile(profile)" v-if="profile.profile_type !== 'OWNER'">
                                <Trash2Icon :size="16" class="icon text-white mr-2" />
                                Eliminar
                            </button>
                        </div>
                    </div>



                </template>
                <div class="profile-card" @click="createProfile" v-if="currentUser.profiles.length < 5">
                    <PlusCircleIcon :size="32" class="icon text-white" />
                    <h2 class="profile-name">Crear perfil</h2>
                </div>

                <CreateProfileModal :avatar-list="avatarList" ref="createProfileModal" />
            </div>

            <div class="flex flex-row space-x-8 items-center justify-center">
                <button class="button" @click="userLogout()">Cerrar sesión</button>
                <button class="button" @click="toggleEditMode">
                    <PencilIcon :size="16" class="icon text-white mr-2" />
                    {{ editMode ? 'Guardar cambios' : 'Modificar perfiles' }}
                </button>
            </div>
        </div>
    </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { SiteSettings, currentUser } from '../../pre-initializers/essentials-preload';
import { PlusCircleIcon } from 'lucide-vue-next'
import CreateProfileModal from '../../components/modals/create-profile.modal.vue'
import { PencilIcon, Trash2Icon } from 'lucide-vue-next';

const createProfileModal = ref(null)
const editMode = ref(false)
const avatarList = ref([])

const handleKeyDown = (e) => {
    if (e.key === 'Enter') {
        e.target.click();
    }
}

const deleteProfile = (profile) => {
    if (!confirm(`¿Estás seguro de que quieres eliminar el perfil ${profile.name}?`)) return;

    axios.delete(`/user/profiles/${profile.id}`).then((response) => {
        console.log(response);
        window.location.reload();
    }).catch((error) => {
        console.log(error);
    });
}

const userLogout = () => {
    axios.delete('/users/sign_out.json').then((response) => {
        window.location.href = '/';
    }).catch((error) => {
        console.log(error);
    });
}

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

const selectProfile = (profile) => {
    if (editMode.value) return; // Don't do anything if we're in edit mode
    console.log(profile);
    axios.post('/user/select-profile', {
        user: {
            selected_profile_id: profile.id
        }

    }).then((response) => {
        console.log(response);
        window.location.href = '/';
    }).catch((error) => {
        console.log(error);
    });
}

const createProfile = () => {
    createProfileModal.value.setIsOpen(true)
}

const toggleEditMode = () => {
    editMode.value = !editMode.value;
    // Reset any other variables or state if needed
}

const fetchAvatars = () => {
    axios.get('/user/default-avatars')
        .then((response) => {
            console.log(response)
            avatarList.value = response.data
        })
        .catch((error) => {
            console.log(error)
        })
}

onMounted(() => {
    fetchAvatars()
})
</script>