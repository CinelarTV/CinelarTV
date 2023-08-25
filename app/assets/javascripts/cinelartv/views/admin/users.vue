<template>
    <div class="panel manage-users">
        <div class="panel-header">
            <h2 class="panel-title">{{ $t('js.admin.users.title') }}</h2>
            
        </div>
        <div class="panel-body">
            <div class="table-responsive">
                <table class="table table-striped">
                    <thead>
                        <tr>
                            <th>{{ $t('js.admin.users.table.email') }}</th>
                            <th>{{ $t('js.admin.users.table.role') }}</th>
                            <th>{{ $t('js.admin.users.table.actions') }}</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="user in users" :key="user.id">
                            <td>{{ user.email }}</td>
                            <td>{{ user.role }}</td>
                            <td>
                                
                                <button class="btn btn-danger btn-sm" @click="deleteUser(user.id)">
                                    {{ $t('js.admin.users.table.delete') }}
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, inject } from 'vue'
import { useHead } from 'unhead'
import { useRoute, useRouter } from 'vue-router'
import { getCurrentInstance } from 'vue'
import { ClapperboardIcon, TvIcon } from 'lucide-vue-next'
import { ShapesIcon } from 'lucide-vue-next'
import { RouterIcon } from 'lucide-vue-next'
import { UserIcon } from 'lucide-vue-next'
import { Trash2Icon } from 'lucide-vue-next'
import { PencilIcon } from 'lucide-vue-next'

const SiteSettings = inject('SiteSettings')
const { $t } = getCurrentInstance().appContext.config.globalProperties

const users = ref([])
const router = useRouter()

const getUsers = () => {
    axios.get('/admin/users.json').then((response) => {
        users.value = response.data.data
    }).catch((error) => {
        console.log(error);
    });
}

const deleteUser = (id) => {
    axios.delete('/admin/users/' + id).then((response) => {
        getUsers()
    }).catch((error) => {
        console.log(error);
    });
}

onMounted(() => {
    getUsers()
})

useHead({
    title: $t('js.admin.users.title')
})

</script>