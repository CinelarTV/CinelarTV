<template>
    <div v-if="showProgress"
        class="transcoding-progress bg-[var(--c-primary-100)] rounded-xl p-4 ring-1 ring-[var(--c-primary-200)]">
        <div class="flex items-center justify-between mb-3">
            <div class="flex items-center gap-2">
                <div class="w-2 h-2 rounded-full animate-pulse" :class="statusColor"></div>
                <span class="text-sm font-medium text-[var(--c-body-text-color)]">
                    {{ statusText }}
                </span>
            </div>
            <span class="text-xs text-[var(--c-primary-900)]">
                {{ overallProgress }}%
            </span>
        </div>

        <!-- Overall Progress Bar -->
        <div class="w-full bg-[rgba(255,255,255,0.1)] rounded-full h-2 mb-3">
            <div class="h-2 rounded-full transition-all duration-300" :class="progressBarColor"
                :style="{ width: `${overallProgress}%` }" />
        </div>

        <!-- Quality Progress -->
        <div v-if="currentQuality" class="space-y-2">
            <div class="flex items-center justify-between text-xs">
                <span class="text-[var(--c-primary-900)]">Calidad actual: {{ currentQuality }}p</span>
                <span class="text-[var(--c-primary-900)]">{{ qualityProgress }}%</span>
            </div>
            <div class="w-full bg-[rgba(255,255,255,0.1)] rounded-full h-1.5">
                <div class="h-1.5 rounded-full transition-all duration-300 bg-[var(--c-tertiary-300)]"
                    :style="{ width: `${qualityProgress}%` }" />
            </div>
        </div>

        <!-- Error Message -->
        <div v-if="error" class="mt-3 p-2 bg-red-900/20 border border-red-700/50 rounded-lg">
            <p class="text-xs text-red-400">{{ error }}</p>
        </div>

        <!-- Successful Qualities -->
        <div v-if="successfulQualities.length > 0" class="mt-3">
            <p class="text-xs text-[var(--c-primary-900)] mb-1">Calidades completadas:</p>
            <div class="flex flex-wrap gap-1">
                <span v-for="quality in successfulQualities" :key="quality"
                    class="px-2 py-0.5 rounded text-xs font-medium bg-green-900/50 text-green-300">
                    {{ quality }}p
                </span>
            </div>
        </div>
    </div>
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

const statusColor = computed(() => {
    switch (status.value) {
        case 'processing':
        case 'processing_quality':
        case 'started':
            return 'bg-yellow-400';
        case 'retrying':
            return 'bg-orange-400';
        case 'failed':
            return 'bg-red-400';
        default:
            return 'bg-green-400';
    }
});

const progressBarColor = computed(() => {
    switch (status.value) {
        case 'processing':
        case 'processing_quality':
        case 'started':
            return 'bg-[var(--c-primary-300)]';
        case 'retrying':
            return 'bg-orange-400';
        case 'failed':
            return 'bg-red-400';
        default:
            return 'bg-green-400';
    }
});

let messageBusCallback: ((data: any, globalId: number, messageId: number) => void) | null = null;

onMounted(() => {
    const channel = `/transcoding/${props.videoSourceId}`;

    messageBusCallback = (data: TranscodingData) => {
        console.log("Received data", data)
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
.transcoding-progress {
    animation: fadeIn 0.3s ease-in-out;
}

@keyframes fadeIn {
    from {
        opacity: 0;
        transform: translateY(-4px);
    }

    to {
        opacity: 1;
        transform: translateY(0);
    }
}
</style>
