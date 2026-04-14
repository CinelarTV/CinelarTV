import { defineComponent, ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { ajax } from '@/lib/Ajax';
import { useSiteSettings } from '@/app/services/site-settings';
import { useHead } from 'unhead';
import { toast } from 'vue-sonner';

import CSpinner from '@/components/c-spinner';
import CIcon from '@/components/c-icon.vue';

interface LiveChannel {
    id: string;
    name: string;
    description: string | null;
    logo_url: string | null;
    stream_url: string;
    stream_format: string;
    is_active: boolean;
    xmltv_channel_id: string | null;
    current_program: {
        id: string;
        title: string;
        description: string | null;
        start_time: string;
        end_time: string;
        icon_url: string | null;
        category: string | null;
    } | null;
    upcoming_programs: Array<{
        id: string;
        title: string;
        description: string | null;
        start_time: string;
        end_time: string;
    }>;
}

export default defineComponent({
    name: 'LiveTvIndex',
    setup() {
        const { siteSettings } = useSiteSettings();
        const router = useRouter();
        const channels = ref<LiveChannel[]>([]);
        const isLoading = ref(true);
        const error = ref<string | null>(null);

        const sectionTitle = computed(() =>
            siteSettings?.live_tv_section_title || 'Live TV'
        );

        useHead({ title: sectionTitle.value });

        async function fetchChannels() {
            try {
                isLoading.value = true;
                error.value = null;
                const { data } = await ajax.get('/live_tv.json');
                channels.value = data.live_tv_channels || [];
            } catch (err: any) {
                const errorMsg = err?.response?.data?.error || 'Error al cargar los canales en vivo.';
                error.value = errorMsg;
                toast.error(errorMsg);
            } finally {
                isLoading.value = false;
            }
        }

        function watchChannel(channelId: string) {
            router.push({ name: 'live_tv.watch', params: { id: channelId } });
        }

        function viewGuide(channelId: string) {
            router.push({ name: 'live_tv.guide', params: { id: channelId } });
        }

        onMounted(fetchChannels);

        return () => {
            if (isLoading.value) {
                return (
                    <div class="live-tv-index live-tv-index--loading">
                        <div class="live-tv-index__state live-tv-index__state--loading">
                            <CSpinner class="live-tv-index__spinner" />
                        </div>
                    </div>
                );
            }

            if (error.value && channels.value.length === 0) {
                return (
                    <div class="live-tv-index live-tv-index--error">
                        <div class="live-tv-index__state live-tv-index__state--error">
                            <CIcon icon="broadcast-off" size={48} class="live-tv-index__state-icon" />
                            <p class="live-tv-index__state-text">{error.value}</p>
                            <button
                                onClick={() => router.push('/')}
                                class="live-tv-index__back-btn"
                            >
                                Volver al inicio
                            </button>
                        </div>
                    </div>
                );
            }

            return (
                <div class="live-tv-index">
                    <div class="live-tv-index__container">
                        <div class="live-tv-index__header">
                            <div class="live-tv-index__header-mark">
                                <div class="live-tv-index__pulse"></div>
                                <CIcon icon="satellite-dish" size={22} class="live-tv-index__header-icon" />
                            </div>
                            <h1 class="live-tv-index__title">{sectionTitle.value}</h1>
                        </div>

                        {channels.value.length === 0 ? (
                            <div class="live-tv-index__state live-tv-index__state--empty">
                                <CIcon icon="broadcast-off" size={64} class="live-tv-index__state-icon" />
                                <h2 class="live-tv-index__state-title">No hay canales disponibles</h2>
                                <p class="live-tv-index__state-text">
                                    No se han configurado canales de televisión en vivo.
                                </p>
                            </div>
                        ) : (
                            <div class="live-tv-index__grid">
                                {channels.value.map((channel) => (
                                    <div
                                        key={channel.id}
                                        class="live-tv-index__card group"
                                        onClick={() => watchChannel(channel.id)}
                                    >
                                        {/* Channel Logo & Banner */}
                                        <div class="live-tv-index__card-media">
                                            {channel.logo_url ? (
                                                <img
                                                    src={channel.logo_url}
                                                    alt={channel.name}
                                                    class="live-tv-index__logo"
                                                    loading="lazy"
                                                />
                                            ) : (
                                                <div class="live-tv-index__logo-fallback">
                                                    <CIcon icon="tv" size={44} class="live-tv-index__logo-fallback-icon" />
                                                </div>
                                            )}

                                            {/* Live Badge */}
                                            <div class="live-tv-index__live-badge">
                                                <div class="live-tv-index__live-dot"></div>
                                                LIVE
                                            </div>
                                        </div>

                                        {/* Channel Info */}
                                        <div class="live-tv-index__card-body">
                                            <h3 class="live-tv-index__channel-name">{channel.name}</h3>

                                            {/* Current Program */}
                                            {channel.current_program ? (
                                                <div class="live-tv-index__program">
                                                    <p class="live-tv-index__program-title">
                                                        <span class="live-tv-index__program-kicker">Ahora:</span>{' '}
                                                        {channel.current_program.title}
                                                    </p>
                                                    {channel.current_program.description && (
                                                        <p class="live-tv-index__program-description line-clamp-2">
                                                            {channel.current_program.description}
                                                        </p>
                                                    )}
                                                    <div class="live-tv-index__program-time">
                                                        <CIcon icon="clock" size={12} class="live-tv-index__program-time-icon" />
                                                        <span>
                                                            {new Date(channel.current_program.start_time).toLocaleTimeString('es-ES', {
                                                                hour: '2-digit',
                                                                minute: '2-digit'
                                                            })}
                                                            {' - '}
                                                            {new Date(channel.current_program.end_time).toLocaleTimeString('es-ES', {
                                                                hour: '2-digit',
                                                                minute: '2-digit'
                                                            })}
                                                        </span>
                                                    </div>
                                                </div>
                                            ) : (
                                                <p class="live-tv-index__program-empty">Sin programación actual</p>
                                            )}

                                            {/* Action Buttons */}
                                            <div class="live-tv-index__actions">
                                                <button
                                                    onClick={(e) => {
                                                        e.stopPropagation();
                                                        watchChannel(channel.id);
                                                    }}
                                                    class="live-tv-index__watch-btn"
                                                >
                                                    <CIcon icon="play" size={14} />
                                                    Ver ahora
                                                </button>
                                                {channel.upcoming_programs.length > 0 && (
                                                    <button
                                                        onClick={(e) => {
                                                            e.stopPropagation();
                                                            viewGuide(channel.id);
                                                        }}
                                                        class="live-tv-index__guide-btn"
                                                    >
                                                        <CIcon icon="calendar" size={14} />
                                                    </button>
                                                )}
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </div>
            );
        };
    }
});
