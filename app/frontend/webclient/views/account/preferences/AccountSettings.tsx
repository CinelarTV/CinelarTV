import { defineComponent, ref, computed, inject, onMounted } from 'vue';
import { toast } from 'vue-sonner';
import CIcon from '@/components/c-icon.vue';
import { ajax } from '../../../lib/Ajax';

export default defineComponent({
  name: 'AccountSettings',
  components: {
    CIcon,
  },
  setup() {
    const currentUser = inject('currentUser');

    const activeSection = ref('email');
    const isSaving = ref(false);

    const emailForm = ref({
      new_email: '',
      current_password: '',
    });

    const passwordForm = ref({
      current_password: '',
      new_password: '',
      password_confirmation: '',
    });

    const linkedAccounts = ref([]);

    const fetchLinkedAccounts = async () => {
      try {
        const response = await ajax.get('/user/linked-accounts.json');
        linkedAccounts.value = response.data.accounts || [];
      } catch (error) {
        console.error('Failed to fetch linked accounts:', error);
      }
    };

    const handleEmailChange = async () => {
      if (!emailForm.value.new_email || !emailForm.value.current_password) {
        toast('Por favor completa todos los campos', {
          class: ['c-notifier', 'warning'],
        });
        return;
      }

      isSaving.value = true;
      try {
        await ajax.put('/user/update-email.json', {
          user: {
            email: emailForm.value.new_email,
            current_password: emailForm.value.current_password,
          },
        });
        toast('Email actualizado correctamente', {
          class: ['c-notifier', 'success'],
        });
        emailForm.value = { new_email: '', current_password: '' };
      } catch (error) {
        toast(error.response?.data?.error || 'Error al actualizar email', {
          class: ['c-notifier', 'error'],
        });
      } finally {
        isSaving.value = false;
      }
    };

    const handlePasswordChange = async () => {
      if (!passwordForm.value.current_password || !passwordForm.value.new_password || !passwordForm.value.password_confirmation) {
        toast('Por favor completa todos los campos', {
          class: ['c-notifier', 'warning'],
        });
        return;
      }

      if (passwordForm.value.new_password !== passwordForm.value.password_confirmation) {
        toast('Las contraseñas no coinciden', {
          class: ['c-notifier', 'warning'],
        });
        return;
      }

      isSaving.value = true;
      try {
        await ajax.put('/user/update-password.json', {
          user: {
            current_password: passwordForm.value.current_password,
            password: passwordForm.value.new_password,
            password_confirmation: passwordForm.value.password_confirmation,
          },
        });
        toast('Contraseña actualizada correctamente', {
          class: ['c-notifier', 'success'],
        });
        passwordForm.value = { current_password: '', new_password: '', password_confirmation: '' };
      } catch (error) {
        toast(error.response?.data?.error || 'Error al actualizar contraseña', {
          class: ['c-notifier', 'error'],
        });
      } finally {
        isSaving.value = false;
      }
    };

    onMounted(() => {
      fetchLinkedAccounts();
    });

    return () => (
      <div class="account-settings">
        <div class="account-settings__tabs">
          <button
            class={`account-settings__tab ${activeSection.value === 'email' ? 'account-settings__tab--active' : ''}`}
            onClick={() => activeSection.value = 'email'}
          >
            <CIcon icon="mail" size={16} />
            Cambiar email
          </button>
          <button
            class={`account-settings__tab ${activeSection.value === 'password' ? 'account-settings__tab--active' : ''}`}
            onClick={() => activeSection.value = 'password'}
          >
            <CIcon icon="lock" size={16} />
            Cambiar contraseña
          </button>
          <button
            class={`account-settings__tab ${activeSection.value === 'linked' ? 'account-settings__tab--active' : ''}`}
            onClick={() => activeSection.value = 'linked'}
          >
            <CIcon icon="link" size={16} />
            Cuentas vinculadas
          </button>
        </div>

        <div class="account-settings__content">
          {activeSection.value === 'email' && (
            <div class="account-settings__section">
              <h3 class="account-settings__section-title">Cambiar email</h3>
              <p class="account-settings__section-description">
                Actualiza la dirección de email asociada a tu cuenta.
              </p>
              <div class="account-settings__form">
                <div class="account-settings__field">
                  <label class="account-settings__label">Email actual</label>
                  <p class="account-settings__current-value">{currentUser?.email}</p>
                </div>
                <div class="account-settings__field">
                  <label class="account-settings__label">Nuevo email</label>
                  <input
                    type="email"
                    v-model={emailForm.value.new_email}
                    class="account-settings__input"
                    placeholder="nuevo@email.com"
                  />
                </div>
                <div class="account-settings__field">
                  <label class="account-settings__label">Contraseña actual</label>
                  <input
                    type="password"
                    v-model={emailForm.value.current_password}
                    class="account-settings__input"
                    placeholder="••••••••"
                  />
                </div>
                <button
                  class="account-settings__submit"
                  onClick={handleEmailChange}
                  disabled={isSaving.value}
                >
                  {isSaving.value ? 'Guardando...' : 'Actualizar email'}
                </button>
              </div>
            </div>
          )}

          {activeSection.value === 'password' && (
            <div class="account-settings__section">
              <h3 class="account-settings__section-title">Cambiar contraseña</h3>
              <p class="account-settings__section-description">
                Actualiza la contraseña de tu cuenta para mantenerla segura.
              </p>
              <div class="account-settings__form">
                <div class="account-settings__field">
                  <label class="account-settings__label">Contraseña actual</label>
                  <input
                    type="password"
                    v-model={passwordForm.value.current_password}
                    class="account-settings__input"
                    placeholder="••••••••"
                  />
                </div>
                <div class="account-settings__field">
                  <label class="account-settings__label">Nueva contraseña</label>
                  <input
                    type="password"
                    v-model={passwordForm.value.new_password}
                    class="account-settings__input"
                    placeholder="••••••••"
                  />
                </div>
                <div class="account-settings__field">
                  <label class="account-settings__label">Confirmar nueva contraseña</label>
                  <input
                    type="password"
                    v-model={passwordForm.value.password_confirmation}
                    class="account-settings__input"
                    placeholder="••••••••"
                  />
                </div>
                <button
                  class="account-settings__submit"
                  onClick={handlePasswordChange}
                  disabled={isSaving.value}
                >
                  {isSaving.value ? 'Guardando...' : 'Actualizar contraseña'}
                </button>
              </div>
            </div>
          )}

          {activeSection.value === 'linked' && (
            <div class="account-settings__section">
              <h3 class="account-settings__section-title">Cuentas vinculadas</h3>
              <p class="account-settings__section-description">
                Gestiona las cuentas externas vinculadas a tu cuenta.
              </p>
              <div class="account-settings__linked-accounts">
                {linkedAccounts.value.length === 0 ? (
                  <p class="account-settings__no-accounts">
                    No hay cuentas vinculadas actualmente.
                  </p>
                ) : (
                  linkedAccounts.value.map((account: any) => (
                    <div key={account.provider} class="account-settings__linked-item">
                      <div class="account-settings__linked-info">
                        <CIcon icon="link" size={16} />
                        <span class="account-settings__linked-provider">{account.provider}</span>
                        <span class="account-settings__linked-email">{account.email}</span>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    );
  },
});
