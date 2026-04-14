import { defineComponent, ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ajax } from '@/lib/Ajax';
import { useHead } from 'unhead';
import { toast } from 'vue-sonner';

import CSpinner from '@/components/c-spinner';
import CIcon from '@/components/c-icon.vue';

interface Program {
    id: string;
    title: string;
    description: string | null;
    start_time: string;
    end_time: string;
    icon_url: string | null;
    category: string | null;
    currently_playing: boolean;
}

interface ChannelGuide {
    live_tv_channel_id: string;
    channel_name: string;
    programs: Program[];
    start_time: string;
    end_time: string;
}

export default defineComponent({
    name: 'LiveTvGuide',
    setup() {
        const route = useRoute();
        const router = useRouter();
        const channelId = route.params.id as string;
        const guide = ref<ChannelGuide | null>(null);
        const isLoading = ref(true);

        useHead({ title: 'Program Guide' });

        async function fetchGuide() {
            try {
                isLoading.value = true;
                const now = new Date();
                const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
                const end = new Date(start);
                end.setDate(end.getDate() + 1);

                const params = new URLSearchParams({
                    start_time: start.toISOString(),
                    end_time: end.toISOString(),
                });

                const { data } = await ajax.get(`/live_tv/${channelId}/guide.json?${params}`);
                guide.value = data;
                useHead({ title: `${data.channel_name} - Program Guide` });
            } catch (err: any) {
                const errorMsg = err?.response?.data?.error || 'Error al cargar la guía de programación.';
                toast.error(errorMsg);
                router.replace({ name: 'live_tv.index' });
            } finally {
                isLoading.value = false;
            }
        }

        function formatTime(dateStr: string): string {
            return new Date(dateStr).toLocaleTimeString('es-ES', {
                hour: '2-digit',
                minute: '2-digit',
            });
        }

        function isCurrentlyPlaying(program: Program): boolean {
            return program.currently_playing;
        }

        function watchChannel() {
            router.push({ name: 'live_tv.watch', params: { id: channelId } });
        }

        function backToChannels() {
            router.push({ name: 'live_tv.index' });
        }

        onMounted(fetchGuide);

        return () => {
            if (isLoading.value) {
                return (
                    <div class="min-h-screen bg-[#0a0a0a]">
                        <div class="flex h-[60vh] items-center justify-center">
                            <CSpinner class="w-12 h-12 text-white" />
                        </div>
                    </div>
                );
            }

            if (!guide.value) {
                return (
                    <div class="min-h-screen bg-[#0a0a0a]">
                        <div class="flex h-[60vh] items-center justify-center">
                            <p class="text-white/60">No se pudo cargar la guía de programación.</p>
                        </div>
                    </div>
                );
            }

            return (
                <div class="min-h-screen bg-[#0a0a0a]">
                    <div class="mx-auto max-w-4xl px-4 py-8 sm:px-6 lg:px-8">
                        {/* Header */}
                        <div class="mb-6 flex items-center justify-between">
                            <div class="flex items-center gap-3">
                                <button
                                    onClick={backToChannels}
                                    class="rounded bg-white/10 p-2 text-white transition-colors hover:bg-white/20"
                                >
                                    <CIcon icon="chevron-left" size={20} />
                                </button>
                                <div>
                                    <h1 class="text-2xl font-bold text-white">{guide.value.channel_name}</h1>
                                    <p class="text-sm text-white/50">Guía de programación</p>
                                </div>
                            </div>
                            <button
                                onClick={watchChannel}
                                class="flex items-center gap-2 rounded bg-red-600 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-red-700"
                            >
                                <CIcon icon="play" size={16} />
                                Ver en vivo
                            </button>
                        </div>

                        {/* Programs List */}
                        <div class="space-y-2">
                            {guide.value.programs.length === 0 ? (
                                <div class="flex flex-col items-center justify-center py-16 text-center">
                                    <CIcon icon="calendar-off" size={48} class="mb-4 text-white/20" />
                                    <p class="text-white/60">No hay programación disponible para este canal.</p>
                                </div>
                            ) : (
                                guide.value.programs.map((program) => {
                                    const isPlaying = isCurrentlyPlaying(program);
                                    return (
                                        <div
                                            key={program.id}
                                            class={`rounded-lg border p-4 transition-colors ${isPlaying
                                                ? 'border-red-600 bg-red-600/10'
                                                : 'border-white/10 bg-white/5 hover:bg-white/10'
                                                }`}
                                        >
                                            <div class="flex items-start gap-4">
                                                {/* Time Column */}
                                                <div class="min-w-[80px] text-center">
                                                    <div class="text-sm font-medium text-white">
                                                        {formatTime(program.start_time)}
                                                    </div>
                                                    <div class="text-xs text-white/40">
                                                        {formatTime(program.end_time)}
                                                    </div>
                                                    {isPlaying && (
                                                        <div class="mt-2 flex items-center justify-center gap-1 text-xs font-bold uppercase text-red-500">
                                                            <div class="h-1.5 w-1.5 animate-pulse rounded-full bg-red-500"></div>
                                                            Ahora
                                                        </div>
                                                    )}
                                                </div>

                                                {/* Program Info */}
                                                <div class="flex-1">
                                                    {program.icon_url && (
                                                        <img
                                                            src={program.icon_url}
                                                            alt=""
                                                            class="mb-2 h-8 w-8 rounded object-contain"
                                                            loading="lazy"
                                                        />
                                                    )}
                                                    <h3 class="mb-1 text-lg font-semibold text-white">
                                                        {program.title}
                                                    </h3>
                                                    {program.description && (
                                                        <p class="mb-2 text-sm text-white/60 line-clamp-2">
                                                            {program.description}
                                                        </p>
                                                    )}
                                                    {program.category && (
                                                        <span class="inline-block rounded bg-white/10 px-2 py-0.5 text-xs text-white/60">
                                                            {program.category}
                                                        </span>
                                                    )}
                                                </div>

                                                {/* Duration */}
                                                <div class="text-right text-xs text-white/40">
                                                    {Math.round(
                                                        (new Date(program.end_time).getTime() -
                                                            new Date(program.start_time).getTime()) /
                                                        60000
                                                    )} min
                                                </div>
                                            </div>
                                        </div>
                                    );
                                })
                            )}
                        </div>
                    </div>
                </div>
            );
        };
    }
});
