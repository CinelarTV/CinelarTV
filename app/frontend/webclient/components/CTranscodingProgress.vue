<template>
    <Transition name="fade">
        <div v-if="showProgress"
            class="transcoding-progress bg-[var(--c-primary-100)] rounded-xl p-4 ring-1 ring-[var(--c-primary-200)]">

            <div class="flex items-center justify-between mb-3">
                <div class="flex items-center gap-2">
                    <div class="w-2 h-2 rounded-full animate-pulse" :class="statusColor"></div>
                    <span class="text-sm font-medium text-[var(--c-body-text-color)]">
                        {{ statusText }}
                    </span>
                </div>
                <span class="text-xs font-semibold text-[var(--c-primary-900)]">
                    {{ overallProgress }}%
                </span>
            </div>

            <div class="w-full bg-[rgba(255,255,255,0.15)] rounded-full h-2 mb-3 overflow-hidden" role="progressbar"
                :aria-valuenow="overallProgress" aria-valuemin="0" aria-valuemax="100">
                <div class="h-full rounded-full transition-all duration-500 ease-out" :class="progressBarColor"
                    :style="{ width: `${overallProgress}%` }" />
            </div>

            <div v-if="currentQuality" class="space-y-2">
                <div class="flex items-center justify-between text-xs">
                    <span class="text-[var(--c-primary-900)]">Calidad actual: {{ currentQuality }}p</span>
                    <span class="text-[var(--c-primary-900)]">{{ qualityProgress }}%</span>
                </div>
                <div class="w-full bg-[rgba(255,255,255,0.15)] rounded-full h-1.5 overflow-hidden" role="progressbar"
                    :aria-valuenow="qualityProgress" aria-valuemin="0" aria-valuemax="100">
                    <div class="h-full rounded-full transition-all duration-500 ease-out bg-[var(--c-tertiary-300)]"
                        :style="{ width: `${qualityProgress}%` }" />
                </div>
            </div>

            <div v-if="error" class="mt-3 p-2 bg-red-900/20 border border-red-700/50 rounded-lg">
                <p class="text-xs text-red-400">{{ error }}</p>
            </div>

            <div v-if="successfulQualities.length > 0" class="mt-3">
                <p class="text-xs text-[var(--c-primary-900)] mb-1">Calidades completadas:</p>
                <div class="flex flex-wrap gap-1">
                    <span v-for="quality in successfulQualities" :key="quality"
                        class="px-2 py-0.5 rounded text-xs font-medium bg-[var(--c-tertiary-900)] text-[var(--c-tertiary-300)] bg-opacity-30">
                        {{ quality }}p
                    </span>
                </div>
            </div>
        </div>
    </Transition>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, PropType } from 'vue';
import { messageBus } from '../application';

interface TranscodingData {
    status: string;
    video_source_id: string | number;
    quality?: string;
    progress?: number;
    quality_progress?: number;
    url?: string;
    successful_qualities?: string[];
    failed_qualities?: string[];
    retry_count?: number;
    max_retries?: number;
    error?: string;
    timestamp: number;
}

const props = defineProps({
    videoSourceId: {
        type: [String, Number] as PropType<string | number>,
        required: true
    }
});

const emit = defineEmits(['transcoding-completed']);

const status = ref<string>('idle');
const overallProgress = ref<number>(0);
const currentQuality = ref<string>('');
const qualityProgress = ref<number>(0);
const successfulQualities = ref<string[]>([]);
const failedQualities = ref<string[]>([]);
const error = ref<string>('');
const retryCount = ref<number>(0);
const maxRetries = ref<number>(0);

// Lógica de visibilidad
const showProgress = computed(() =>
    status.value !== 'idle' && status.value !== 'completed'
);

const statusText = computed(() => {
    switch (status.value) {
        case 'started': return 'Iniciando transcodificación...';
        case 'processing': return `Procesando calidades...`;
        case 'processing_quality': return `Transcodificando ${currentQuality.value}p...`;
        case 'retrying': return `Reintentando (${retryCount.value}/${maxRetries.value})...`;
        case 'failed': return 'Transcodificación fallida';
        default: return 'Transcodificando...';
    }
});

// Actualizado a paleta Tertiary
const statusColor = computed(() => {
    switch (status.value) {
        case 'processing':
        case 'processing_quality':
        case 'started':
            return 'bg-[var(--c-tertiary-400)]';
        case 'retrying':
            return 'bg-orange-400';
        case 'failed':
            return 'bg-red-400';
        default:
            return 'bg-green-400';
    }
});

// Actualizado a paleta Tertiary
const progressBarColor = computed(() => {
    switch (status.value) {
        case 'processing':
        case 'processing_quality':
        case 'started':
            return 'bg-[var(--c-tertiary-300)]';
        case 'retrying':
            return 'bg-orange-400';
        case 'failed':
            return 'bg-red-400';
        default:
            return 'bg-green-400';
    }
});

let messageBusCallback: ((data: TranscodingData, globalId?: number, messageId?: number) => void) | null = null;

onMounted(() => {
    const channel = `/transcoding/${props.videoSourceId}`;

    messageBusCallback = (data: TranscodingData) => {
        // console.log("Received data", data); // Opcional: comentar en producción

        switch (data.status) {
            case 'started':
                status.value = 'started';
                overallProgress.value = 0;
                successfulQualities.value = [];
                failedQualities.value = [];
                error.value = '';
                break;
            case 'processing':
                status.value = 'processing';
                overallProgress.value = data.progress || 0;
                break;
            case 'processing_quality':
                status.value = 'processing_quality';
                currentQuality.value = data.quality || '';
                qualityProgress.value = data.quality_progress || 0;
                break;
            case 'retrying':
                status.value = 'retrying';
                retryCount.value = data.retry_count || 0;
                maxRetries.value = data.max_retries || 0;
                error.value = data.error || '';
                break;
            case 'completed':
                status.value = 'completed';
                overallProgress.value = 100;
                successfulQualities.value = data.successful_qualities || [];
                failedQualities.value = data.failed_qualities || [];
                emit('transcoding-completed', data); // Considera emitir el evento aquí
                break;
            case 'failed':
                status.value = 'failed';
                error.value = data.error || '';
                break;
        }
    };

    messageBus.subscribe(channel, messageBusCallback);
});

onUnmounted(() => {
    if (messageBusCallback) {
        messageBus.unsubscribe(`/transcoding/${props.videoSourceId}`, messageBusCallback);
    }
});
</script>

<style scoped>
/* Transición nativa de Vue para reemplazar los @keyframes */
.fade-enter-active,
.fade-leave-active {
    transition: all 0.3s ease-in-out;
}

.fade-enter-from,
.fade-leave-to {
    opacity: 0;
    transform: translateY(-4px);
}
</style>