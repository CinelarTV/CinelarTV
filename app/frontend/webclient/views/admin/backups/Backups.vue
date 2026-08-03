<template>
  <div class="backups-panel">
    <div class="backups-header">
      <h2>Backup & Restore</h2>
      <div class="backups-actions">
        <button class="btn btn-primary" @click="createBackup" :disabled="creating">
          <CIcon v-if="!creating" icon="plus" />
          <span v-if="creating">Creating...</span>
          <span v-else>Create Backup</span>
        </button>
        <button class="btn btn-secondary" @click="syncBackups" :disabled="syncing">
          Sync Disk
        </button>
        <button class="btn btn-secondary" @click="cleanupExpired" :disabled="cleaning">
          Cleanup Expired
        </button>
      </div>
    </div>

    <div v-if="error" class="alert alert-error">{{ error }}</div>
    <div v-if="success" class="alert alert-success">{{ success }}</div>

    <div class="backup-settings card">
      <h3>Backup Settings</h3>
      <div class="settings-grid">
        <label class="setting-item">
          <input type="checkbox" v-model="settings.includeFiles" @change="saveSettings" />
          Include uploaded files
        </label>
        <label class="setting-item">
          <input type="checkbox" v-model="settings.encrypt" @change="saveSettings" />
          Encrypt backups
        </label>
        <div class="setting-item" v-if="settings.encrypt">
          <label>Encryption Password</label>
          <input type="password" v-model="settings.password" placeholder="Enter encryption password" />
        </div>
        <div class="setting-item">
          <label>Retention (days)</label>
          <input type="number" v-model.number="settings.retentionDays" min="1" max="365" @change="saveSettings" />
        </div>
      </div>
    </div>

    <div class="backups-list card">
      <h3>Backups ({{ backups.length }})</h3>
      <div v-if="loading" class="loading">Loading backups...</div>
      <div v-else-if="backups.length === 0" class="empty-state">No backups found</div>
      <table v-else class="backups-table">
        <thead>
          <tr>
            <th>File</th>
            <th>Size</th>
            <th>Type</th>
            <th>Status</th>
            <th>Encrypted</th>
            <th>Created</th>
            <th>Expires</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="backup in backups" :key="backup.id" :class="'status-' + backup.status">
            <td class="filename">{{ backup.filename }}</td>
            <td>{{ backup.human_size }}</td>
            <td><span class="badge" :class="'badge-' + backup.backup_type">{{ backup.backup_type }}</span></td>
            <td><span class="badge" :class="'badge-' + backup.status">{{ backup.status }}</span></td>
            <td>{{ backup.encrypted ? 'Yes' : 'No' }}</td>
            <td>{{ formatDate(backup.created_at) }}</td>
            <td>{{ backup.expires_at ? formatDate(backup.expires_at) : 'Never' }}</td>
            <td class="actions">
              <button class="btn btn-sm" @click="verifyBackup(backup)" title="Verify integrity">
                <CIcon icon="check-circle" />
              </button>
              <a :href="'/admin/backups/' + backup.id + '/download'" class="btn btn-sm" title="Download">
                <CIcon icon="download" />
              </a>
              <button class="btn btn-sm btn-warning" @click="confirmRestore(backup)" title="Restore"
                :disabled="backup.status !== 'completed'">
                <CIcon icon="refresh-cw" />
              </button>
              <button class="btn btn-sm btn-danger" @click="confirmDelete(backup)" title="Delete">
                <CIcon icon="trash-2" />
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Restore Confirmation Modal -->
    <div v-if="showRestoreModal" class="modal-overlay" @click.self="showRestoreModal = false">
      <div class="modal">
        <h3>Confirm Restore</h3>
        <p>This will <strong>completely replace</strong> the current database with:</p>
        <p class="backup-name">{{ restoreTarget?.filename }}</p>
        <p class="warning">This action cannot be undone. All current data will be lost.</p>
        <label class="setting-item">
          <input type="checkbox" v-model="restoreOptions.force" />
          Force restore (bypass allow_restore setting)
        </label>
        <label class="setting-item">
          <input type="checkbox" v-model="restoreOptions.restoreFiles" />
          Include file manifest
        </label>
        <div class="modal-actions">
          <button class="btn btn-secondary" @click="showRestoreModal = false">Cancel</button>
          <button class="btn btn-danger" @click="executeRestore" :disabled="restoring">
            {{ restoring ? 'Restoring...' : 'Restore Now' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div v-if="showDeleteModal" class="modal-overlay" @click.self="showDeleteModal = false">
      <div class="modal">
        <h3>Confirm Delete</h3>
        <p>Are you sure you want to delete this backup?</p>
        <p class="backup-name">{{ deleteTarget?.filename }}</p>
        <div class="modal-actions">
          <button class="btn btn-secondary" @click="showDeleteModal = false">Cancel</button>
          <button class="btn btn-danger" @click="executeDelete" :disabled="deleting">
            {{ deleting ? 'Deleting...' : 'Delete' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, inject } from 'vue'
import CIcon from "@/components/c-icon.vue"

const axios = inject('axios')

const backups = ref([])
const loading = ref(true)
const creating = ref(false)
const syncing = ref(false)
const cleaning = ref(false)
const restoring = ref(false)
const deleting = ref(false)
const error = ref('')
const success = ref('')

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

const formatDate = (dateStr) => {
  if (!dateStr) return ''
  return new Date(dateStr).toLocaleString()
}

const fetchBackups = async () => {
  loading.value = true
  try {
    const { data } = await axios.get('/admin/backups')
    backups.value = data.data
  } catch (e) {
    error.value = 'Failed to load backups'
  } finally {
    loading.value = false
  }
}

const createBackup = async () => {
  creating.value = true
  error.value = ''
  success.value = ''
  try {
    const { data } = await axios.post('/admin/backups', {
      notes: 'Manual backup',
      include_files: settings.value.includeFiles,
      encrypt: settings.value.encrypt
    })
    success.value = data.message
    await fetchBackups()
  } catch (e) {
    error.value = e.response?.data?.error || 'Failed to create backup'
  } finally {
    creating.value = false
  }
}

const syncBackups = async () => {
  syncing.value = true
  try {
    await axios.get('/admin/backups/sync')
    await fetchBackups()
  } catch (e) {
    error.value = 'Failed to sync'
  } finally {
    syncing.value = false
  }
}

const cleanupExpired = async () => {
  cleaning.value = true
  try {
    await axios.post('/admin/backups/cleanup')
    await fetchBackups()
  } catch (e) {
    error.value = 'Failed to cleanup'
  } finally {
    cleaning.value = false
  }
}

const verifyBackup = async (backup) => {
  try {
    const { data } = await axios.post(`/admin/backups/${backup.id}/verify`)
    if (data.valid) {
      success.value = `Backup ${backup.filename} integrity verified`
    } else {
      error.value = `Backup ${backup.filename} checksum FAILED`
    }
  } catch (e) {
    error.value = 'Verification failed'
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
    await axios.post(`/admin/backups/${restoreTarget.value.id}/restore`, {
      force: restoreOptions.value.force,
      restore_files: restoreOptions.value.restoreFiles
    })
    success.value = 'System restored successfully'
    showRestoreModal.value = false
  } catch (e) {
    error.value = e.response?.data?.error || 'Restore failed'
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
    await axios.delete(`/admin/backups/${deleteTarget.value.id}`)
    success.value = 'Backup deleted'
    showDeleteModal.value = false
    await fetchBackups()
  } catch (e) {
    error.value = 'Failed to delete'
  } finally {
    deleting.value = false
  }
}

onMounted(() => {
  fetchBackups()
})
</script>

<style scoped>
.backups-panel {
  padding: 1rem;
}
.backups-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}
.backups-actions {
  display: flex;
  gap: 0.5rem;
}
.card {
  background: var(--color-card);
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 1rem;
  margin-bottom: 1rem;
}
.settings-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 0.75rem;
  margin-top: 0.5rem;
}
.setting-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.9rem;
}
.setting-item input[type="number"],
.setting-item input[type="password"] {
  width: 120px;
}
.backups-table {
  width: 100%;
  border-collapse: collapse;
}
.backups-table th,
.backups-table td {
  padding: 0.5rem;
  text-align: left;
  border-bottom: 1px solid var(--color-border);
  font-size: 0.85rem;
}
.filename {
  font-family: monospace;
  font-size: 0.8rem;
}
.badge {
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  text-transform: uppercase;
}
.badge-manual { background: #3b82f620; color: #3b82f6; }
.badge-scheduled { background: #8b5cf620; color: #8b5cf6; }
.badge-completed { background: #22c55e20; color: #22c55e; }
.badge-running { background: #f59e0b20; color: #f59e0b; }
.badge-pending { background: #6b728020; color: #6b7280; }
.badge-failed { background: #ef444420; color: #ef4444; }
.actions {
  display: flex;
  gap: 0.25rem;
}
.btn {
  padding: 0.4rem 0.8rem;
  border-radius: 6px;
  border: 1px solid var(--color-border);
  background: var(--color-card);
  cursor: pointer;
  font-size: 0.85rem;
}
.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
.btn-primary { background: #3b82f6; color: white; border-color: #3b82f6; }
.btn-secondary { background: var(--color-card); }
.btn-warning { color: #f59e0b; }
.btn-danger { color: #ef4444; }
.btn-sm { padding: 0.25rem 0.5rem; font-size: 0.8rem; }
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
}
.modal {
  background: var(--color-card);
  border-radius: 8px;
  padding: 1.5rem;
  max-width: 500px;
  width: 90%;
}
.modal h3 { margin-bottom: 0.5rem; }
.modal .warning { color: #ef4444; font-weight: 600; }
.modal .backup-name { font-family: monospace; font-size: 0.9rem; background: var(--color-bg); padding: 0.5rem; border-radius: 4px; }
.modal-actions { display: flex; justify-content: flex-end; gap: 0.5rem; margin-top: 1rem; }
.alert { padding: 0.75rem; border-radius: 6px; margin-bottom: 1rem; }
.alert-error { background: #ef444420; color: #ef4444; border: 1px solid #ef444440; }
.alert-success { background: #22c55e20; color: #22c55e; border: 1px solid #22c55e40; }
.loading, .empty-state { text-align: center; padding: 2rem; color: var(--color-muted); }
</style>
