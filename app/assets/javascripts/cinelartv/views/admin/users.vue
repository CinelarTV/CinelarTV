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
                            <th>{{ $t('js.common.email') }}</th>
                            <th>{{ $t('js.common.role') }}</th>
                            <th>{{ $t('js.common.actions') }}</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="user in users" :key="user.id">
                            <td>{{ user.email }}</td>
                            <td>{{ user.role }}</td>
                            <td>
                                
                                <button class="btn btn-danger btn-sm" @click="deleteUser(user.id)">
                                    {{ $t('js.admin.actions.delete') }}
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
import { ajax } from '../../lib/axios-setup'

const SiteSettings = inject('SiteSettings')
const { $t } = getCurrentInstance().appContext.config.globalProperties

const users = ref([])
const router = useRouter()

const getUsers = () => {
    ajax.get('/admin/users.json').then((response) => {
        users.value = response.data.data
    }).catch((error) => {
        console.log(error);
    });
}

const deleteUser = (id) => {
    ajax.delete('/admin/users/' + id).then((response) => {
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