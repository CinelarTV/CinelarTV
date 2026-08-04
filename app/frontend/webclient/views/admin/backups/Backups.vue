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
                <c-button icon="refresh-cw" @click="openRestoreSummary(backup)" title="Restaurar"
                  :disabled="backup.status !== 'completed'" />
                <c-button icon="trash-2" variant="danger" @click="confirmDelete(backup)" title="Eliminar" />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </section>

    <!-- Restore Modal: Step 1 = Summary, Step 2 = Progress -->
    <c-modal v-model="showRestoreModal" :persistent="restoreStep === 'progress'" size="lg">
      <template #header>
        <div v-if="restoreStep === 'summary'">
          <h3 class="text-xl font-semibold tracking-tight text-[var(--c-body-text-color)]">
            Resumen del Backup
          </h3>
          <p class="mt-1 text-sm text-[var(--c-primary-100)]">
            Revisa los datos antes de confirmar la restauracion.
          </p>
        </div>
        <div v-else-if="restoreStep === 'progress'">
          <h3 class="text-xl font-semibold tracking-tight text-[var(--c-body-text-color)]">
            Restaurando Sistema
          </h3>
          <p class="mt-1 text-sm text-[var(--c-primary-100)]">
            {{ restoreProgress.message || 'Iniciando...' }}
          </p>
        </div>
      </template>

      <!-- Step 1: Summary -->
      <template v-if="restoreStep === 'summary'">
        <div v-if="summaryLoading" class="flex items-center justify-center py-8">
          <c-spinner />
        </div>
        <div v-else-if="summaryError" class="text-center py-8">
          <c-icon icon="alert-circle" :size="32" class="text-red-400 mx-auto mb-3" />
          <p class="text-red-400">{{ summaryError }}</p>
        </div>
        <div v-else-if="restoreSummary" class="backups-admin__summary">
          <div class="backups-admin__summary-filename">{{ restoreSummary.filename }}</div>

          <div class="backups-admin__summary-grid">
            <div class="backups-admin__summary-stat">
              <c-icon icon="database" :size="16" />
              <span class="backups-admin__summary-label">Base de datos</span>
              <strong>{{ restoreSummary.human_database_size }}</strong>
            </div>
            <div class="backups-admin__summary-stat">
              <c-icon icon="file" :size="16" />
              <span class="backups-admin__summary-label">Archivos</span>
              <strong>{{ restoreSummary.files_count }}</strong>
            </div>
            <div class="backups-admin__summary-stat">
              <c-icon icon="hard-drive" :size="16" />
              <span class="backups-admin__summary-label">Tamano archivos</span>
              <strong>{{ restoreSummary.human_files_total_size }}</strong>
            </div>
            <div class="backups-admin__summary-stat">
              <c-icon icon="shield" :size="16" />
              <span class="backups-admin__summary-label">Cifrado</span>
              <strong>{{ restoreSummary.encrypted ? 'Si' : 'No' }}</strong>
            </div>
          </div>

          <div v-if="restoreSummary.files?.length" class="backups-admin__summary-files">
            <p class="backups-admin__summary-files-title">
              Archivos incluidos ({{ restoreSummary.files.length }})
            </p>
            <div class="backups-admin__summary-files-list">
              <div v-for="(file, idx) in restoreSummary.files.slice(0, 20)" :key="idx"
                class="backups-admin__summary-file">
                <span class="backups-admin__summary-file-path">{{ file.path }}</span>
                <span class="backups-admin__summary-file-size">{{ formatBytes(file.size) }}</span>
              </div>
              <div v-if="restoreSummary.files.length > 20" class="backups-admin__summary-file backups-admin__summary-file--more">
                ... y {{ restoreSummary.files.length - 20 }} archivos mas
              </div>
            </div>
          </div>

          <div class="backups-admin__summary-warning">
            <c-icon icon="alert-triangle" :size="16" />
            <p>Esta accion <strong>reemplazara completamente</strong> la base de datos actual. Todos los datos actuales se perderan. Esta accion no se puede deshacer.</p>
          </div>

          <label class="backups-admin__toggle backups-admin__summary-option">
            <input type="checkbox" v-model="restoreOptions.force" />
            <span>Forzar restauracion (omitir configuracion allow_restore)</span>
          </label>
          <label class="backups-admin__toggle backups-admin__summary-option">
            <input type="checkbox" v-model="restoreOptions.restoreFiles" />
            <span>Incluir archivos subidos</span>
          </label>
        </div>
      </template>

      <!-- Step 2: Progress -->
      <template v-if="restoreStep === 'progress'">
        <div class="backups-admin__progress">
          <div class="backups-admin__progress-bar-track">
            <div
              class="backups-admin__progress-bar-fill"
              :style="{ width: `${restoreProgress.percent || 0}%` }"
              :class="{ 'backups-admin__progress-bar-fill--error': restoreProgress.type === 'failed' }"
            />
          </div>
          <div class="backups-admin__progress-info">
            <span class="backups-admin__progress-percent">{{ restoreProgress.percent || 0 }}%</span>
            <span class="backups-admin__progress-step">{{ restoreProgress.message || 'Esperando...' }}</span>
          </div>

          <div v-if="restoreProgress.type === 'completed'" class="backups-admin__progress-result backups-admin__progress-result--success">
            <c-icon icon="check-circle" :size="20" />
            <span>Restauracion completada exitosamente.</span>
          </div>
          <div v-else-if="restoreProgress.type === 'failed'" class="backups-admin__progress-result backups-admin__progress-result--error">
            <c-icon icon="x-circle" :size="20" />
            <span>{{ restoreProgress.message }}</span>
          </div>
        </div>
      </template>

      <template #footer>
        <div v-if="restoreStep === 'summary'" class="flex items-center justify-end gap-3">
          <c-button @click="showRestoreModal = false">Cancelar</c-button>
          <c-button variant="danger" icon="refresh-cw" :loading="restoring" @click="executeRestore">
            Restaurar Ahora
          </c-button>
        </div>
        <div v-else-if="restoreStep === 'progress'" class="flex items-center justify-end gap-3">
          <c-button v-if="restoreProgress.type === 'completed' || restoreProgress.type === 'failed'"
            @click="showRestoreModal = false">
            Cerrar
          </c-button>
        </div>
      </template>
    </c-modal>

    <!-- Delete Confirmation Modal -->
    <c-modal v-model="showDeleteModal" size="md">
      <template #header>
        <h3 class="text-xl font-semibold tracking-tight text-[var(--c-body-text-color)]">
          Confirmar Eliminacion
        </h3>
      </template>

      <p class="text-[var(--c-body-text-color)]">Estas seguro de que deseas eliminar este backup?</p>
      <p class="mt-2 text-sm font-mono text-[var(--c-primary-100)]">{{ deleteTarget?.filename }}</p>

      <template #footer>
        <div class="flex items-center justify-end gap-3">
          <c-button @click="showDeleteModal = false">Cancelar</c-button>
          <c-button variant="danger" icon="trash-2" :loading="deleting" @click="executeDelete">
            Eliminar
          </c-button>
        </div>
      </template>
    </c-modal>
  </div>
</template>

<script setup>
import { ref, computed, onUnmounted, watch } from 'vue'
import { useHead } from 'unhead'
import { toast } from 'vue3-toastify'
import { ajax } from '../../../lib/Ajax'
import { messageBus } from '../../../application'

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

const restoreStep = ref('summary')
const summaryLoading = ref(false)
const summaryError = ref('')
const restoreSummary = ref(null)

const restoreProgress = ref({
  type: '',
  step: '',
  percent: 0,
  message: '',
})

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

const formatBytes = (bytes) => {
  if (!bytes) return '0 B'
  const units = ['B', 'KB', 'MB', 'GB']
  let exp = Math.floor(Math.log(bytes) / Math.log(1024))
  exp = Math.min(exp, units.length - 1)
  return `${(bytes / Math.pow(1024, exp)).toFixed(1)} ${units[exp]}`
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

let restoreChannel = null
let restoreCallback = null

const openRestoreSummary = async (backup) => {
  restoreTarget.value = backup
  restoreStep.value = 'summary'
  summaryLoading.value = true
  summaryError.value = ''
  restoreSummary.value = null
  restoreOptions.value = { force: false, restoreFiles: true }
  showRestoreModal.value = true

  try {
    const { data } = await ajax.get(`/admin/backups/${backup.id}/summary.json`)
    restoreSummary.value = data.data
  } catch (e) {
    summaryError.value = e.response?.data?.error || 'No se pudo cargar el resumen del backup'
  } finally {
    summaryLoading.value = false
  }
}

const executeRestore = async () => {
  restoring.value = true
  try {
    const { data } = await ajax.post(`/admin/backups/${restoreTarget.value.id}/restore`, {
      force: restoreOptions.value.force,
      restore_files: restoreOptions.value.restoreFiles
    })

    restoreStep.value = 'progress'
    restoreProgress.value = { type: 'started', step: 'started', percent: 0, message: 'Iniciando restauracion...' }
    restoreChannel = data.channel

    restoreCallback = (msg) => {
      restoreProgress.value = {
        type: msg.type || 'progress',
        step: msg.step || '',
        percent: msg.percent || 0,
        message: msg.message || '',
      }

      if (msg.type === 'completed' || msg.type === 'failed') {
        unsubRestore()
        fetchBackups()
      }
    }

    messageBus.subscribe(restoreChannel, restoreCallback)
  } catch (e) {
    toast.error(e.response?.data?.error || 'Error al iniciar restauracion')
    showRestoreModal.value = false
  } finally {
    restoring.value = false
  }
}

const unsubRestore = () => {
  if (restoreCallback && restoreChannel) {
    messageBus.unsubscribe(restoreChannel, restoreCallback)
    restoreCallback = null
    restoreChannel = null
  }
}

watch(showRestoreModal, (val) => {
  if (!val) {
    unsubRestore()
  }
})

const confirmDelete = (backup) => {
  deleteTarget.value = backup
  showDeleteModal.value = true
}

const executeDelete = async () => {
  deleting.value = true
  try {
    await ajax.delete(`/admin/backups/${deleteTarget.value.id}.json`)
    toast.success('Backup eliminado')
    showDeleteModal.value = false
    await fetchBackups()
  } catch (e) {
    toast.error('Error al eliminar backup')
  } finally {
    deleting.value = false
  }
}

onUnmounted(() => {
  unsubRestore()
})

fetchBackups()
</script>
