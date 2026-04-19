import { defineComponent, ref, onMounted, inject } from 'vue';
import CreateProfileModal from '../../components/modals/create-profile.modal.vue';
import EditProfileModal from '../../components/modals/edit-profile.modal.vue';
import { ajax } from '../../lib/Ajax';
import CSpinner from '../../components/c-spinner';
import CIcon from '../../components/c-icon.vue';

interface Profile {
    id: number;
    name: string;
    avatar_id?: string;
    profile_type?: string;
}

interface AvatarOption {
    id: string;
    name: string;
    path: string;
}

export default defineComponent({
    name: 'ProfileSelect',
    setup() {
        const currentUser = inject<any>('currentUser');
        const SiteSettings = inject<any>('SiteSettings');
        const createProfileModal = ref<any>(null);
        const editProfileModal = ref<any>(null);
        const editMode = ref(false);
        const avatarList = ref<AvatarOption[]>([]);
        const loadingProfile = ref(false);
        const profileSelected = ref<Profile | null>(null);
        const profiles = ref<Profile[]>(Array.isArray(currentUser?.profiles) ? [...currentUser.profiles] : []);

        const buttonClickedSound = typeof Audio !== 'undefined'
            ? new Audio('/assets/audio/profile-select.mp3')
            : null;

        if (buttonClickedSound) {
            buttonClickedSound.volume = 0.5;
        }

        const handleKeyDown = (e: KeyboardEvent, profile: Profile) => {
            if (e.key === 'Enter') {
                selectProfile(profile);
            }
        };

        const deleteProfile = (profile: Profile) => {
            if (!confirm(`Are you sure you want to delete the profile ${profile.name}?`)) return;
            ajax.delete(`/user/profiles/${profile.id}.json`).then(() => {
                profiles.value = profiles.value.filter((item) => item.id !== profile.id);
            }).catch(console.log);
        };

        const openEditModal = (profile: Profile) => {
            editProfileModal.value?.openWithProfile(profile)
        }

        const handleProfileUpdated = (updated: Profile) => {
            profiles.value = profiles.value.map((p) => (p.id === updated.id ? updated : p));
        }

        const handleProfileCreated = (profile: Profile) => {
            profiles.value = [...profiles.value, profile];
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
            if (buttonClickedSound) {
                buttonClickedSound.currentTime = 0;
                buttonClickedSound.play().catch(() => { });
            }
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
                    avatarList.value = response?.data?.profiles || response?.data || [];
                })
                .catch(console.log);
        };

        onMounted(() => {
            fetchAvatars();
        });

        return () => (
            <div id="profile-selector">
                <div class="profile-selector__layout">
                    <div class="profile-selector__content">
                        {/* Site logo */}
                        <div class="profile-selector__logo-wrap">
                            <img
                                src={SiteSettings.site_logo}
                                alt={`${SiteSettings.site_name} logo`}
                                class="h-8 md:h-10 w-auto"
                            />
                        </div>

                        {/* Title */}
                        <h1 class="profile-selector__title" v-emoji>
                            ¿Quién eres? 🍿
                        </h1>
                        <p class="profile-selector__subtitle">
                            Elige un perfil para continuar donde te quedaste.
                        </p>

                        {/* Profile grid */}
                        <div class="profile-selector__grid">
                            {profiles.value.map((profile: Profile) => (
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
                                    {editMode.value && (
                                        <div class="profile-edit-actions">
                                            <button
                                                class="profile-edit-btn edit"
                                                onClick={(e) => { e.stopPropagation(); openEditModal(profile); }}
                                            >
                                                <CIcon icon="pencil" size={16} />
                                                Editar
                                            </button>

                                            {profile.profile_type !== 'OWNER' && (
                                                <button
                                                    class="profile-edit-btn delete"
                                                    onClick={(e) => { e.stopPropagation(); deleteProfile(profile); }}
                                                >
                                                    <CIcon icon="trash2" size={16} />
                                                    Eliminar
                                                </button>
                                            )}
                                        </div>
                                    )}
                                </div>
                            ))}

                            {/* Create new profile card */}
                            {profiles.value.length < 5 && (
                                <div class="profile-card-wrapper">
                                    <button
                                        type="button"
                                        class="profile-card create-profile"
                                        aria-label="Crear perfil"
                                        onClick={createProfile}
                                    >
                                        <CIcon icon="plus" size={32} class="create-profile-icon" />
                                        <h2 class="profile-name">Crear perfil</h2>
                                    </button>
                                </div>
                            )}

                            {/* Create profile modal */}
                            <CreateProfileModal
                                avatar-list={avatarList.value}
                                ref={createProfileModal}
                                onCreated={handleProfileCreated}
                            />

                            {/* Edit profile modal */}
                            <EditProfileModal
                                avatar-list={avatarList.value}
                                ref={editProfileModal}
                                onUpdated={handleProfileUpdated}
                            />
                        </div>

                        {/* Footer actions */}
                        <div class="profile-selector__footer">
                            <button class="profile-footer-btn" onClick={userLogout}>
                                Cerrar sesión
                            </button>
                            <button class={['profile-footer-btn', 'edit', editMode.value && 'is-active']} onClick={toggleEditMode}>
                                <CIcon icon="pencil" size={16} />
                                {editMode.value ? 'Guardar cambios' : 'Modificar perfiles'}
                            </button>
                        </div>
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
                            <p class="profile-loading-text">Cargando perfil...</p>
                            <CSpinner />
                        </div>
                    </div>
                )}
            </div>
        );
    }
});
