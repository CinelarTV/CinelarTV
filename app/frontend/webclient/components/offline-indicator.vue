<template>
    <div class="offline-indicator" v-if="!online && !discarded">
        <span>{{ i18n.t("js.offline_indicator.no_internet") }}</span>
        <div class="flex justify-center mt-2">
            <CButton @click="reloadPage" class="reload-button" icon="rotate-ccw">
                {{ i18n.t("js.offline_indicator.reload") }}
            </CButton>

            <button @click="discarded = true">
                <CIcon icon="x" />
            </button>


        </div>
    </div>
</template>

<script setup>
import { inject, computed, onMounted, ref, watch } from 'vue';
import { useNetworkService } from '../app/services/network-service';
import CButton from "./forms/c-button";
import CIcon from "./c-icon.vue";

const discarded = ref(false)
const i18n = inject('I18n');

const networkService = useNetworkService();

const online = computed(() => networkService.isOnline);

watch(online, (value => {
    if (value) discarded.value = false
}))

const reloadPage = () => {
    window.location.reload();
}

onMounted(() => {
    networkService.listenStatusChange();
})
</script>../app/services/network-service