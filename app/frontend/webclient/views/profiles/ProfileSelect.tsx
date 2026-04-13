import { defineComponent, ref, onMounted, inject } from 'vue';
import { PlusCircleIcon, PencilIcon, Trash2Icon, Loader2 } from 'lucide-vue-next';
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
            if (!confirm(`Are you sure you want to delete the profile ${profile.name}?`)) return;
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
                <div class="h-screen flex flex-col items-center justify-center px-4">
                    {/* Site logo */}
                    <div class="mb-12">
                        <img
                            src={SiteSettings.site_logo}
                            alt={`${SiteSettings.site_name} logo`}
                            class="h-8 md:h-10 w-auto"
                        />
                    </div>

                    {/* Title */}
                    <h1 class="text-2xl md:text-3xl font-semibold mb-16 text-[var(--c-body-text-color)]" v-emoji>
                        ¿Quién eres? 🍿
                    </h1>

                    {/* Profile grid */}
                    <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4 md:gap-6 mb-12 md:mb-32">
                        {currentUser.profiles.map((profile: Profile) => (
                            <div class="profile-card-wrapper" key={profile.id}>
                                <div
                                    class={`profile-card ${editMode.value ? ' editing' : ''}`}
                                    tabindex={0}
                                    role="button"
                                    aria-label={`Seleccionar perfil ${profile.name}`}
                                    onKeydown={e => handleKeyDown(e as KeyboardEvent, profile)}
                                    onClick={() => selectProfile(profile)}
                                >
                                    {/* Avatar */}
                                    <img
                                        src={getProfileAvatar(profile.avatar_id)}
                                        class="profile-avatar"
                                        alt={`Avatar de perfil ${profile.name}`}
                                    />

                                    {/* Profile name */}
                                    <h2 class="profile-name">{profile.name}</h2>
                                </div>

                                {/* Edit mode actions */}
                                {editMode.value && profile.profile_type !== 'OWNER' && (
                                    <button
                                        class="profile-edit-btn delete"
                                        onClick={() => deleteProfile(profile)}
                                    >
                                        <Trash2Icon size={16} />
                                        Eliminar
                                    </button>
                                )}
                            </div>
                        ))}

                        {/* Create new profile card */}
                        {currentUser.profiles.length < 5 && (
                            <div class="profile-card-wrapper">
                                <div
                                    class="profile-card create-profile"
                                    onClick={createProfile}
                                >
                                    <PlusCircleIcon size={32} class="create-profile-icon" />
                                    <h2 class="profile-name">Crear perfil</h2>
                                </div>
                            </div>
                        )}

                        {/* Create profile modal */}
                        <CreateProfileModal avatar-list={avatarList.value} ref={createProfileModal} />
                    </div>

                    {/* Footer actions */}
                    <div class="flex flex-row gap-4 items-center">
                        <button class="profile-footer-btn" onClick={userLogout}>
                            Cerrar sesión
                        </button>
                        <button class="profile-footer-btn edit" onClick={toggleEditMode}>
                            <PencilIcon size={16} />
                            {editMode.value ? 'Guardar cambios' : 'Modificar perfiles'}
                        </button>
                    </div>
                </div>

                {/* Loading overlay */}
                {loadingProfile.value && profileSelected.value && (
                    <div class="loading-overlay">
                        <div class="overlay-content">
                            <img
                                src={getProfileAvatar(profileSelected.value.avatar_id)}
                                class="profile-avatar-lg"
                                alt={`Avatar de perfil ${profileSelected.value.name}`}
                            />
                            <h2 class="profile-name-lg">{profileSelected.value.name}</h2>
                            <p class="text-sm mt-4">Cargando perfil...</p>
                            <c-spinner />
                        </div>
                    </div>
                )}
            </div>
        );
    }
});
