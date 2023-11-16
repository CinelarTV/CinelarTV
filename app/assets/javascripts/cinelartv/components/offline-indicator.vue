<template>
    <div class="offline-indicator" v-if="!online">
        <span>{{ i18n.t("js.offline_indicator.no_internet") }}</span>
        <div class="flex justify-center mt-2">
            <c-button @click="reloadPage" class="reload-button" icon="rotate-ccw">
                {{ i18n.t("js.offline_indicator.reload") }}
            </c-button>
        </div>
    </div>
</template>

<script setup>
import { inject, computed, onMounted } from 'vue';
import { useNetworkService } from '../app/services/network-service';

const i18n = inject('I18n');

const networkService = useNetworkService();

const online = computed(() => networkService.isOnline);

const reloadPage = () => {
    window.location.reload();
}

onMounted(() => {
    networkService.listenStatusChange();
})
</script>../app/services/network-service