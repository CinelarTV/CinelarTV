import { ref, watch, onMounted, onBeforeUnmount } from 'vue';
import { ajax } from '@/lib/Ajax';

export interface ContinueWatchingOptions {
    contentId: string | number;
    episodeId?: string | number;
    initialProgress?: number;
    initialDuration?: number;
    enabled?: boolean;
    interval?: number; // ms
}

export function useContinueWatching(options: ContinueWatchingOptions) {
    const progress = ref(options.initialProgress || 0);
    const duration = ref(options.initialDuration || 0);
    const lastSent = ref(Date.now());
    const enabled = options.enabled !== false;
    const interval = options.interval || 5000;

    // Llama esto cuando el usuario avanza el video
    function updateProgress(newProgress: number, newDuration?: number) {
        progress.value = newProgress;
        if (typeof newDuration === 'number') duration.value = newDuration;
        maybeSendProgress();
    }

    // Envía el progreso al backend si corresponde
    async function maybeSendProgress(force = false) {
        if (!enabled) return;
        if (!options.contentId) return;
        if (!force && Date.now() - lastSent.value < interval) return;
        if (progress.value < 1) return;
        lastSent.value = Date.now();
        try {
            await ajax.put(`/watch/${options.contentId}/progress.json`, {
                progress: progress.value,
                duration: duration.value,
                episode_id: options.episodeId
            });
        } catch (e) {
            // Silenciar errores
        }
    }

    // Forzar envío al desmontar
    onBeforeUnmount(() => {
        maybeSendProgress(true);
    });

    // Permite forzar el guardado desde fuera
    function forceSave() {
        maybeSendProgress(true);
    }

    return {
        progress,
        duration,
        updateProgress,
        forceSave
    };
}
