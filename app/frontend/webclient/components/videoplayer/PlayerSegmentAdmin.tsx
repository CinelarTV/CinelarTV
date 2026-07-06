import { defineComponent, ref, PropType } from 'vue';
import CIcon from '../c-icon.vue';
import { ajax } from "@/lib/Ajax";

interface Segment {
    id?: string | number;
    segment_type: string;
    start_time?: number;
    end_time?: number;
}

export default defineComponent({
    name: 'PlayerSegmentAdmin',
    props: {
        contentId: { type: String, required: false, default: null },
        episodeId: { type: String, required: false, default: null },
        currentTime: { type: Number, required: true }
    },
    setup(props) {
        const menuOpen = ref(false);
        const segments = ref<Segment[]>([]);
        const creating = ref(false);
        const segmentType = ref<string>('skip_intro');
        const startTime = ref<number>(0);
        const endTime = ref<number | null>(null);
        const saving = ref(false);
        const error = ref<string | null>(null);
        const loading = ref(false);

        const segmentTypes = [
            { value: 'skip_intro', label: 'Omitir Intro', isRange: true },
            { value: 'skip_resume', label: 'Omitir Resumen', isRange: true },
            { value: 'next_episode', label: 'Siguiente Episodio', isRange: false },
            { value: 'credits_start', label: 'Inicio Créditos', isRange: false },
        ];

        const getApiBase = () => {
            if (props.episodeId) return `/admin/episodes/${props.episodeId}/segments`;
            if (props.contentId) return `/admin/contents/${props.contentId}/segments`;
            return '';
        };

        const fetchSegments = async () => {
            loading.value = true;
            try {
                const url = getApiBase();
                if (!url) return;
                const res = await fetch(url);
                const data = await res.json();
                segments.value = Array.isArray(data) ? data : (data.segments || []);
            } catch (error) {
                console.error('Error fetching segments:', error);
            } finally {
                loading.value = false;
            }
        };

        fetchSegments();

        const formatTime = (seconds: number): string => {
            const mins = Math.floor(seconds / 60);
            const secs = Math.floor(seconds % 60);
            return `${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
        };

        const getSegmentTypeLabel = (type: string): string => {
            return segmentTypes.find(st => st.value === type)?.label || type;
        };

        const getSegmentTypeColor = (type: string): string => {
            switch (type) {
                case 'skip_intro': return 'bg-orange-500';
                case 'skip_resume': return 'bg-purple-500';
                case 'next_episode': return 'bg-green-500';
                case 'credits_start': return 'bg-blue-500';
                default: return 'bg-white/20';
            }
        };

        const captureStartTime = () => { startTime.value = props.currentTime; };
        const captureEndTime = () => { endTime.value = props.currentTime; };

        const createSegment = async () => {
            const selectedType = segmentTypes.find(st => st.value === segmentType.value);
            if (!selectedType) return;

            if (selectedType.isRange) {
                if (startTime.value === null || endTime.value === null) {
                    error.value = 'Se requieren tiempos de inicio y fin para este tipo de segmento';
                    return;
                }
                if (startTime.value >= endTime.value) {
                    error.value = 'El tiempo de inicio debe ser anterior al tiempo de fin';
                    return;
                }
            } else {
                if (startTime.value === null) {
                    error.value = 'Se requiere tiempo de inicio para este tipo de segmento';
                    return;
                }
            }

            saving.value = true;
            error.value = null;

            try {
                const url = getApiBase();
                if (!url) return;
                const segmentData: any = {
                    segment: { segment_type: segmentType.value, start_time: startTime.value }
                };
                if (selectedType.isRange && endTime.value !== null) {
                    segmentData.segment.end_time = endTime.value;
                }
                const res = await ajax.post(url, segmentData);
                if (res.data.error) throw new Error(res.data.error);
                startTime.value = 0;
                endTime.value = null;
                creating.value = false;
                await fetchSegments();
            } catch (e: any) {
                error.value = e.message || 'Error desconocido';
            } finally {
                saving.value = false;
            }
        };

        const removeSegment = async (id: string | number) => {
            if (!confirm('¿Estás seguro de que quieres eliminar este segmento?')) return;
            try {
                const url = `${getApiBase()}/${id}`;
                await ajax(url, { method: 'DELETE' });
                await fetchSegments();
            } catch (error) {
                console.error('Error removing segment:', error);
            }
        };

        const handleClickOutside = () => {
            menuOpen.value = false;
        };

        return () => (
            <div class="relative">
                {/* Trigger button — same style as other player controls */}
                <button
                    onClick={() => menuOpen.value = !menuOpen.value}
                    class="player-control-btn"
                    aria-label="Segmentos"
                >
                    <CIcon icon="clock" size={18} />
                </button>

                {/* Dropdown */}
                {menuOpen.value && (
                    <>
                        {/* Backdrop */}
                        <div
                            class="fixed inset-0 z-40"
                            onClick={handleClickOutside}
                        />

                        {/* Menu panel */}
                        <div class="absolute right-0 top-full mt-2 z-50 min-w-[300px] max-h-[440px] flex flex-col rounded-xl border border-white/[0.08] bg-black/80 backdrop-blur-2xl shadow-2xl shadow-black/50 overflow-hidden">
                            {/* Header */}
                            <div class="px-3.5 pt-3 pb-2 flex items-center justify-between flex-shrink-0">
                                <span class="text-[0.65rem] font-semibold uppercase tracking-wider text-white/40">
                                    Segmentos
                                </span>
                                <span class="text-[0.65rem] tabular-nums text-white/40">
                                    {formatTime(props.currentTime)}
                                </span>
                            </div>

                            {/* Content — scrollable */}
                            <div class="px-1.5 pb-1.5 overflow-y-auto overscroll-y-contain flex-1 min-h-0">
                                {creating.value ? (
                                    /* ── Create form ── */
                                    <div class="space-y-2.5 px-2 pt-1">
                                        <div class="flex flex-col gap-1.5">
                                            <label class="text-[0.65rem] font-semibold uppercase tracking-wider text-white/40">Tipo</label>
                                            <select
                                                class="w-full bg-white/[0.06] border border-white/[0.08] rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-white/20 transition-colors"
                                                value={segmentType.value}
                                                onInput={(e: any) => segmentType.value = e.target.value}
                                            >
                                                {segmentTypes.map((type) => (
                                                    <option key={type.value} value={type.value}>{type.label}</option>
                                                ))}
                                            </select>
                                        </div>

                                        <div class="grid grid-cols-2 gap-2">
                                            <div class="flex flex-col gap-1.5">
                                                <label class="text-[0.65rem] font-semibold uppercase tracking-wider text-white/40">Inicio</label>
                                                <div class="w-full bg-white/[0.06] border border-white/[0.08] rounded-lg px-3 py-2 text-center">
                                                    <span class="text-sm font-mono text-white">{formatTime(startTime.value)}</span>
                                                </div>
                                                <button
                                                    onClick={captureStartTime}
                                                    class="w-full px-3 py-1.5 bg-white/[0.08] hover:bg-white/[0.14] text-white text-xs font-medium rounded-lg transition-colors"
                                                >
                                                    Capturar
                                                </button>
                                            </div>

                                            {segmentTypes.find(st => st.value === segmentType.value)?.isRange && (
                                                <div class="flex flex-col gap-1.5">
                                                    <label class="text-[0.65rem] font-semibold uppercase tracking-wider text-white/40">Fin</label>
                                                    <div class="w-full bg-white/[0.06] border border-white/[0.08] rounded-lg px-3 py-2 text-center">
                                                        <span class="text-sm font-mono text-white">{endTime.value !== null ? formatTime(endTime.value) : '--:--'}</span>
                                                    </div>
                                                    <button
                                                        onClick={captureEndTime}
                                                        class="w-full px-3 py-1.5 bg-white/[0.08] hover:bg-white/[0.14] text-white text-xs font-medium rounded-lg transition-colors"
                                                    >
                                                        Capturar
                                                    </button>
                                                </div>
                                            )}
                                        </div>

                                        {error.value && (
                                            <div class="px-3 py-2 rounded-lg bg-white/[0.06] border border-white/[0.08]">
                                                <span class="text-red-400 text-xs">{error.value}</span>
                                            </div>
                                        )}

                                        <div class="flex gap-2 pt-1 pb-1">
                                            <button
                                                onClick={createSegment}
                                                disabled={saving.value}
                                                class="flex-1 px-3 py-2 bg-white/[0.10] hover:bg-white/[0.16] text-white text-xs font-medium rounded-lg transition-colors disabled:opacity-40"
                                            >
                                                {saving.value ? 'Guardando...' : 'Guardar'}
                                            </button>
                                            <button
                                                onClick={() => { creating.value = false; error.value = null; startTime.value = 0; endTime.value = null; }}
                                                class="px-3 py-2 bg-white/[0.04] hover:bg-white/[0.08] text-white/60 text-xs font-medium rounded-lg transition-colors"
                                            >
                                                Cancelar
                                            </button>
                                        </div>
                                    </div>
                                ) : (
                                    /* ── Segment list ── */
                                    <div class="space-y-0.5">
                                        {segments.value.length > 0 && segments.value.map((seg) => (
                                            <div
                                                key={seg.id}
                                                class="flex items-center justify-between px-2.5 py-2 rounded-lg hover:bg-white/[0.04] transition-colors group"
                                            >
                                                <div class="flex items-center gap-2.5 min-w-0">
                                                    <div class={`w-1.5 h-1.5 rounded-full flex-shrink-0 ${getSegmentTypeColor(seg.segment_type)}`} />
                                                    <div class="flex flex-col min-w-0">
                                                        <span class="text-xs font-medium text-white/80 truncate">
                                                            {getSegmentTypeLabel(seg.segment_type)}
                                                        </span>
                                                        <span class="text-[0.65rem] font-mono text-white/40 tabular-nums">
                                                            {formatTime(seg.start_time || 0)}
                                                            {seg.end_time != null ? ` — ${formatTime(seg.end_time)}` : ''}
                                                        </span>
                                                    </div>
                                                </div>
                                                <button
                                                    onClick={() => removeSegment(seg.id!)}
                                                    class="opacity-0 group-hover:opacity-100 text-white/30 hover:text-red-400 transition-all p-1 -mr-1"
                                                >
                                                    <CIcon icon="trash" size={14} />
                                                </button>
                                            </div>
                                        ))}

                                        {segments.value.length === 0 && !loading.value && (
                                            <div class="py-5 text-center">
                                                <span class="text-xs text-white/30">Sin segmentos</span>
                                            </div>
                                        )}

                                        <button
                                            onClick={() => creating.value = true}
                                            class="w-full flex items-center justify-center gap-2 px-3 py-2 mt-1 rounded-lg bg-white/[0.04] hover:bg-white/[0.08] text-white/50 hover:text-white/80 text-xs font-medium transition-colors"
                                        >
                                            <CIcon icon="plus" size={14} />
                                            <span>Agregar</span>
                                        </button>
                                    </div>
                                )}
                            </div>
                        </div>
                    </>
                )}
            </div>
        );
    }
});
