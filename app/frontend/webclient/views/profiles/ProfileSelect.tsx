import { defineComponent, ref, onMounted, inject } from 'vue';
import { PlusCircleIcon, PencilIcon, Trash2Icon } from 'lucide-vue-next';
import CreateProfileModal from '../../components/modals/create-profile.modal.vue';
import { Howl } from 'howler';
import { ajax } from '../../lib/Ajax';
import CIcon from "../../components/c-icon.vue";

interface Profile {
    id: number;
    name: string;
    avatar_id?: string;
    profile_type?: string;
}

export default defineComponent({
    name: 'ProfileSelect',
    setup() {
        const currentUser = inject<any>('currentUser');
        const SiteSettings = inject<any>('SiteSettings');
        const createProfileModal = ref<any>(null);
        const editMode = ref(false);
        const avatarList = ref<string[]>([]);
        const loadingProfile = ref(false);
        const profileSelected = ref<Profile | null>(null);

        const buttonClickedSound = new Howl({
            src: ['/assets/audio/profile-selected.mp3'],
            volume: 0.5,
        });

        const handleKeyDown = (e: KeyboardEvent, profile: Profile) => {
            if (e.key === 'Enter') {
                selectProfile(profile);
            }
        };

        const deleteProfile = (profile: Profile) => {
            if (!confirm(`¿Estás seguro de que quieres eliminar el perfil ${profile.name}?`)) return;
            ajax.delete(`/user/profiles/${profile.id}`).then(() => {
                window.location.reload();
            }).catch(console.log);
        };

        const userLogout = () => {
            ajax.delete('/logout.json').then(() => {
                window.location.href = '/';
            }).catch(console.log);
        };

        const getProfileAvatar = (avatar?: string) => {
            const defaultAvatarList = ['coolCat', 'cuteCat'];
            if (!avatar) avatar = 'default';
            if (avatar === 'default') {
                const randomAvatar = defaultAvatarList[Math.floor(Math.random() * defaultAvatarList.length)];
                return `/assets/default/avatars/${randomAvatar}.png`;
            }
            return `/assets/default/avatars/${avatar}.png`;
        };

        const selectProfile = (profile: Profile) => {
            if (editMode.value) return;
            profileSelected.value = profile;
            loadingProfile.value = true;
            buttonClickedSound.play();
            setTimeout(() => {
                ajax.post('/session/select-profile.json', {
                    profile_id: profile.id
                }).then(() => {
                    window.location.href = '/';
                }).catch(console.log);
            }, 1500);
        };

        const createProfile = () => {
            createProfileModal.value?.setIsOpen(true);
        };

        const toggleEditMode = () => {
            editMode.value = !editMode.value;
        };

        const fetchAvatars = () => {
            ajax.get('/user/default-avatars.json')
                .then((response: any) => {
                    avatarList.value = response.data.profiles;
                })
                .catch(console.log);
        };

        onMounted(() => {
            fetchAvatars();
        });

        return () => (
            <div id="profile-selector">
                <div class="h-screen flex flex-col items-center justify-center">
                    <img src={SiteSettings.site_logo} class="h-8" />
                    <h1 class="text-2xl font-bold mt-6 mb-16" v-emoji>
                        ¿Quién eres? 🍿
                    </h1>
                    <div class="mt-4 mb-12 md:mb-32 grid grid-cols-2 gap-4 place-items-center md:flex md:flex-wrap md:justify-center md:gap-6">
                        {currentUser.profiles.map((profile: Profile) => (
                            <div
                                class={`profile-card ${editMode.value ? ' editing' : ''}`}
                                tabindex={0}
                                role="button"
                                aria-label={`Seleccionar perfil ${profile.name}`}
                                onKeydown={e => handleKeyDown(e as KeyboardEvent, profile)}
                                onClick={() => selectProfile(profile)}
                            >
                                <img src={getProfileAvatar(profile.avatar_id)} class="profile-avatar" alt={`Avatar de perfil ${profile.name}`} />
                                <h2 class="profile-name">{profile.name}</h2>
                                {editMode.value && (
                                    <div class="flex flex-row space-x-2 relative top-0 mt-2 right-0">
                                        {profile.profile_type !== 'OWNER' && (
                                            <button class="button" onClick={() => deleteProfile(profile)}>
                                                <CIcon icon="trash-2" size={16} class="icon text-white mr-2" />
                                                <Trash2Icon size={16} class="icon text-white mr-2" />
                                                Eliminar
                                            </button>
                                        )}
                                    </div>
                                )}
                            </div>
                        ))}
                        {currentUser.profiles.length < 5 && (
                            <div class="profile-card" onClick={createProfile}>
                                <PlusCircleIcon size={32} class="icon text-white" />
                                <h2 class="profile-name">Crear perfil</h2>
                            </div>
                        )}
                        <CreateProfileModal avatar-list={avatarList.value} ref={createProfileModal} />
                    </div>
                    <div class="flex flex-row space-x-8 items-center justify-center">
                        <button class="button" onClick={userLogout}>Cerrar sesión</button>
                        <button class="button" onClick={toggleEditMode}>
                            <PencilIcon size={16} class="icon text-white mr-2" />
                            {editMode.value ? 'Guardar cambios' : 'Modificar perfiles'}
                        </button>
                    </div>
                </div>
                {loadingProfile.value && profileSelected.value && (
                    <div class="loading-overlay">
                        <div class="overlay-content">
                            <img src={getProfileAvatar(profileSelected.value.avatar_id)} class="profile-avatar" alt={`Avatar de perfil ${profileSelected.value.name}`} />
                            <h2 class="profile-name">{profileSelected.value.name}</h2>
                            Cargando perfil...
                            <c-spinner />
                        </div>
                    </div>
                )}
            </div>
        );
    }
});

