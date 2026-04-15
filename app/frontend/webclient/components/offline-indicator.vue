<template>
    <Transition name="fade">
        <div class="offline-indicator" v-if="!online && !discarded">
            <div class="offline-indicator__content">
                <div class="offline-indicator__icon">
                    <CIcon icon="wifi-off" />
                </div>
                <span class="offline-indicator__message">
                    {{ i18n.t("js.offline_indicator.no_internet") }}
                </span>
                <div class="offline-indicator__actions">
                    <button class="offline-indicator__reload-btn" @click="reloadPage">
                        <CIcon icon="rotate-ccw" />
                        {{ i18n.t("js.offline_indicator.reload") }}
                    </button>
                    <button class="offline-indicator__close-btn" @click="discarded = true" title="Dismiss">
                        <CIcon icon="x" />
                    </button>
                </div>
            </div>
        </div>
    </Transition>
</template>

<script setup>
import { inject, computed, onMounted, ref, watch } from 'vue';
import { useNetworkService } from '../app/services/network-service';
import CIcon from './c-icon.vue';

const discarded = ref(false);
const i18n = inject('I18n');
const networkService = useNetworkService();
const online = computed(() => networkService.isOnline);

watch(online, (value) => {
    if (value) discarded.value = false;
});

const reloadPage = () => {
    window.location.reload();
};

onMounted(() => {
    networkService.listenStatusChange();
});
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
    opacity: 0;
}
</style>