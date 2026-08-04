<template>
  <div class="backups-admin">
    <header class="backups-admin__hero">
      <div class="backups-admin__hero-copy">
        <p class="backups-admin__eyebrow">Admin Console</p>
        <h1 class="backups-admin__title">Backup &amp; Restore</h1>
        <p class="backups-admin__subtitle">
          Gestiona copias de seguridad del sistema, verifica integridad y restaura desde backups anteriores.
        </p>
      </div>
      <div class="backups-admin__hero-actions">
        <c-button icon="hard-drive" :loading="syncing" @click="syncBackups">
          Sync Disk
        </c-button>
        <c-button icon="plus" :loading="creating" @click="createBackup">
          Crear Backup
        </c-button>
      </div>
    </header>

    <section class="backups-admin__stats">
      <article class="backups-admin__stat-card">
        <c-icon icon="hard-drive" :size="20" class="backups-admin__stat-icon" />
        <span class="backups-admin__stat-label">Total Backups</span>
        <strong class="backups-admin__stat-value">{{ backups.length }}</strong>
      </article>
      <article class="backups-admin__stat-card">
        <c-icon icon="check-circle" :size="20" class="backups-admin__stat-icon backups-admin__stat-icon--success" />
        <span class="backups-admin__stat-label">Completados</span>
        <strong class="backups-admin__stat-value">{{ completedCount }}</strong>
      </article>
      <article class="backups-admin__stat-card">
        <c-icon icon="alert-circle" :size="20" class="backups-admin__stat-icon backups-admin__stat-icon--warning" />
        <span class="backups-admin__stat-label">Fallidos</span>
        <strong class="backups-admin__stat-value">{{ failedCount }}</strong>
      </article>
      <article class="backups-admin__stat-card">
        <c-icon icon="shield" :size="20" class="backups-admin__stat-icon backups-admin__stat-icon--info" />
        <span class="backups-admin__stat-label">Cifrado</span>
        <strong class="backups-admin__stat-value">{{ encryptedCount }}</strong>
      </article>
    </section>

    <section class="backups-admin__card">
      <div class="backups-admin__section-header">
        <div>
          <h2>Configuracion</h2>
          <p>Ajustes predeterminados para nuevas copias de seguridad.</p>
        </div>
      </div>

      <div class="backups-admin__settings-grid">
        <label class="backups-admin__toggle">
          <input type="checkbox" v-model="settings.includeFiles" @change="saveSettings" />
          <span>Incluir archivos subidos</span>
        </label>
        <label class="backups-admin__toggle">
          <input type="checkbox" v-model="settings.encrypt" @change="saveSettings" />
          <span>Cifrar backups</span>
        </label>
        <div class="backups-admin__field" v-if="settings.encrypt">
          <label class="backups-admin__field-label">Contrasena de cifrado</label>
          <c-input type="password" v-model="settings.password" placeholder="Ingresa la contrasena" />
        </div>
        <div class="backups-admin__field">
          <label class="backups-admin__field-label">Retencion (dias)</label>
          <c-input type="number" v-model.number="settings.retentionDays" min="1" max="365" @change="saveSettings" />
        </div>
      </div>
    </section>

    <section class="backups-admin__card">
      <div class="backups-admin__section-header">
        <div>
          <h2>Backups ({{ backups.length }})</h2>
          <p>Listado completo de copias de seguridad del sistema.</p>
        </div>
        <c-button variant="ghost" icon="trash-2" @click="cleanupExpired" :loading="cleaning">
          Limpiar expirados
        </c-button>
      </div>

      <div v-if="loading" class="backups-admin__loading">
        <c-spinner />
      </div>

      <div v-else-if="backups.length === 0" class="backups-admin__empty">
        <c-icon icon="hard-drive" :size="48" class="backups-admin__empty-icon" />
        <p class="backups-admin__empty-title">No hay backups</p>
        <p class="backups-admin__empty-description">Crea tu primer backup para empezar a proteger tu sistema.</p>
      </div>

      <table v-else class="admin-table">
        <thead>
          <tr>
            <th>Archivo</th>
            <th>Tamano</th>
            <th>Tipo</th>
            <th>Estado</th>
            <th>Cifrado</th>
            <th>Creado</th>
            <th>Expira</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="backup in backups" :key="backup.id">
            <td class="backups-admin__filename">{{ backup.filename }}</td>
            <td>{{ backup.human_size }}</td>
            <td>
              <span class="backups-admin__badge" :class="`backups-admin__badge--${backup.backup_type}`">
                {{ backup.backup_type }}
              </span>
            </td>
            <td>
              <span class="backups-admin__badge" :class="statusClass(backup.status)">
                {{ backup.status }}
              </span>
            </td>
            <td>{{ backup.encrypted ? 'Si' : 'No' }}</td>
            <td>{{ formatDate(backup.created_at) }}</td>
            <td>{{ backup.expires_at ? formatDate(backup.expires_at) : 'Nunca' }}</td>
            <td>
              <div class="backups-admin__actions">
                <c-button icon="check-circle" @click="verifyBackup(backup)" title="Verificar integridad" />
                <a :href="`/admin/backups/${backup.id}/download`" class="backups-admin__action-link">
                  <c-button icon="download" title="Descargar" />
                </a>
                <c-button icon="refresh-cw" @click="confirmRestore(backup)" title="Restaurar"
                  :disabled="backup.status !== 'completed'" />
                <c-button icon="trash-2" variant="danger" @click="confirmDelete(backup)" title="Eliminar" />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </section>

    <!-- Restore Confirmation Modal -->
    <Teleport to="body">
      <div v-if="showRestoreModal" class="backups-admin__modal-overlay" @click.self="showRestoreModal = false">
        <div class="backups-admin__modal">
          <div class="backups-admin__modal-header">
            <h3>Confirmar Restauracion</h3>
            <c-button icon="x" @click="showRestoreModal = false" />
          </div>
          <div class="backups-admin__modal-body">
            <p>Esto <strong>reemplazara completamente</strong> la base de datos actual con:</p>
            <p class="backups-admin__modal-filename">{{ restoreTarget?.filename }}</p>
            <p class="backups-admin__modal-warning">Esta accion no se puede deshacer. Todos los datos actuales se
              perderan.</p>

            <label class="backups-admin__toggle">
              <input type="checkbox" v-model="restoreOptions.force" />
              <span>Forzar restauracion (omitir configuracion allow_restore)</span>
            </label>
            <label class="backups-admin__toggle">
              <input type="checkbox" v-model="restoreOptions.restoreFiles" />
              <span>Incluir manifiesto de archivos</span>
            </label>
          </div>
          <div class="backups-admin__modal-footer">
            <c-button @click="showRestoreModal = false">Cancelar</c-button>
            <c-button variant="danger" icon="refresh-cw" :loading="restoring" @click="executeRestore">
              Restaurar Ahora
            </c-button>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Delete Confirmation Modal -->
    <Teleport to="body">
      <div v-if="showDeleteModal" class="backups-admin__modal-overlay" @click.self="showDeleteModal = false">
        <div class="backups-admin__modal">
          <div class="backups-admin__modal-header">
            <h3>Confirmar Eliminacion</h3>
            <c-button icon="x" @click="showDeleteModal = false" />
          </div>
          <div class="backups-admin__modal-body">
            <p>Estas seguro de que deseas eliminar este backup?</p>
            <p class="backups-admin__modal-filename">{{ deleteTarget?.filename }}</p>
          </div>
          <div class="backups-admin__modal-footer">
            <c-button @click="showDeleteModal = false">Cancelar</c-button>
            <c-button variant="danger" icon="trash-2" :loading="deleting" @click="executeDelete">
              Eliminar
            </c-button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useHead } from 'unhead'
import { toast } from 'vue3-toastify'
import { ajax } from '../../../lib/Ajax'
useHead({ title: 'Backups - Admin' })

const backups = ref([])
const loading = ref(true)
const creating = ref(false)
const syncing = ref(false)
const cleaning = ref(false)
const restoring = ref(false)
const deleting = ref(false)

const showRestoreModal = ref(false)
const showDeleteModal = ref(false)
const restoreTarget = ref(null)
const deleteTarget = ref(null)

const settings = ref({
  includeFiles: true,
  encrypt: false,
  password: '',
  retentionDays: 30
})

const restoreOptions = ref({
  force: false,
  restoreFiles: true
})

const completedCount = computed(() => backups.value.filter(b => b.status === 'completed').length)
const failedCount = computed(() => backups.value.filter(b => b.status === 'failed').length)
const encryptedCount = computed(() => backups.value.filter(b => b.encrypted).length)

const statusClass = (status) => {
  const map = {
    completed: 'backups-admin__badge--completed',
    running: 'backups-admin__badge--running',
    pending: 'backups-admin__badge--pending',
    failed: 'backups-admin__badge--failed'
  }
  return map[status] || ''
}

const formatDate = (dateStr) => {
  if (!dateStr) return ''
  return new Date(dateStr).toLocaleString()
}

const fetchBackups = async () => {
  loading.value = true
  try {
    const { data } = await ajax.get('/admin/backups.json')
    backups.value = data.data
  } catch (e) {
    toast.error('No se pudieron cargar los backups')
  } finally {
    loading.value = false
  }
}

const createBackup = async () => {
  creating.value = true
  try {
    const { data } = await ajax.post('/admin/backups.json', {
      notes: 'Manual backup',
      include_files: settings.value.includeFiles,
      encrypt: settings.value.encrypt
    })
    toast.success(data.message || 'Backup creado correctamente')
    await fetchBackups()
  } catch (e) {
    toast.error(e.response?.data?.error || 'Error al crear backup')
  } finally {
    creating.value = false
  }
}

const syncBackups = async () => {
  syncing.value = true
  try {
    await ajax.get('/admin/backups/sync.json')
    toast.success('Backups sincronizados con disco')
    await fetchBackups()
  } catch (e) {
    toast.error('Error al sincronizar backups')
  } finally {
    syncing.value = false
  }
}

const cleanupExpired = async () => {
  cleaning.value = true
  try {
    const { data } = await ajax.post('/admin/backups/cleanup.json')
    toast.success(data.message || 'Limpieza completada')
    await fetchBackups()
  } catch (e) {
    toast.error('Error al limpiar backups expirados')
  } finally {
    cleaning.value = false
  }
}

const verifyBackup = async (backup) => {
  try {
    const { data } = await ajax.post(`/admin/backups/${backup.id}/verify.json`)
    if (data.valid) {
      toast.success(`Integridad verificada: ${backup.filename}`)
    } else {
      toast.error(`Verificacion fallida: ${backup.filename}`)
    }
  } catch (e) {
    toast.error('Error al verificar backup')
  }
}

const confirmRestore = (backup) => {
  restoreTarget.value = backup
  restoreOptions.value = { force: false, restoreFiles: true }
  showRestoreModal.value = true
}

const executeRestore = async () => {
  restoring.value = true
  try {
    await ajax.post(`/admin/backups/${restoreTarget.value.id}/restore`, {
      force: restoreOptions.value.force,
      restore_files: restoreOptions.value.restoreFiles
    })
    toast.success('Sistema restaurado correctamente')
    showRestoreModal.value = false
  } catch (e) {
    toast.error(e.response?.data?.error || 'Error al restaurar')
  } finally {
    restoring.value = false
  }
}

const confirmDelete = (backup) => {
  deleteTarget.value = backup
  showDeleteModal.value = true
}

const executeDelete = async () => {
  deleting.value = true
  try {
    const { data } = await ajax.delete(`/admin/backups/${deleteTarget.value.id}.json`)
    toast.success('Backup eliminado')
    showDeleteModal.value = false
    await fetchBackups()
  } catch (e) {
    toast.error('Error al eliminar backup')
  } finally {
    deleting.value = false
  }
}

onMounted(() => {
  fetchBackups()
})
</script>
