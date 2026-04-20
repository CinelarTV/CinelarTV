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

        // Fetch segments when component mounts
        fetchSegments();

        const formatTime = (seconds: number): string => {
            const mins = Math.floor(seconds / 60);
            const secs = Math.floor(seconds % 60);
            return `${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
        };

        const getSegmentTypeLabel = (type: string): string => {
            const segmentType = segmentTypes.find(st => st.value === type);
            return segmentType ? segmentType.label : type;
        };

        const getSegmentTypeColor = (type: string): string => {
            switch (type) {
                case 'skip_intro': return 'bg-orange-500';
                case 'skip_resume': return 'bg-purple-500';
                case 'next_episode': return 'bg-green-500';
                case 'credits_start': return 'bg-blue-500';
                default: return 'bg-gray-500';
            }
        };

        const captureStartTime = () => {
            startTime.value = props.currentTime;
        };

        const captureEndTime = () => {
            endTime.value = props.currentTime;
        };

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
                    segment: {
                        segment_type: segmentType.value,
                        start_time: startTime.value,
                    }
                };

                if (selectedType.isRange && endTime.value !== null) {
                    segmentData.segment.end_time = endTime.value;
                }

                const res = await ajax.post(url, segmentData);

                if (res.data.error) {
                    throw new Error(res.data.error);
                }

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

        return () => (
            <media-menu>
                <media-menu-button
                    class="group relative flex size-10 cursor-pointer items-center justify-center rounded-md outline-none ring-inset ring-[var(--c-player-accent-50)] hover:bg-white/20 data-[focus]:ring-4"
                    aria-label="Segmentos"
                >
                    <CIcon icon="clock" class="transform transition-transform duration-200 ease-out group-data-[open]:rotate-45" />
                </media-menu-button>
                <media-menu-items
                    class="flex h-[var(--menu-height)] max-h-[500px] min-w-[320px] flex-col overflow-y-auto overscroll-y-contain rounded-md border border-white/10 bg-black/95 p-2.5 font-sans text-[15px] font-medium outline-none backdrop-blur-sm transition-[height] duration-300 will-change-[height] animate-out fade-out slide-out-to-bottom-2 data-[resizing]:overflow-hidden data-[open]:animate-in data-[open]:fade-in data-[open]:slide-in-from-bottom-4"
                    placement="top"
                    offset="0"
                >
                    {/* Header */}
                    <div class="flex items-center justify-between px-3 py-2 border-b border-white/10 mb-2">
                        <span class="text-white/80 text-sm font-medium">Administrar Segmentos</span>
                    </div>

                    {/* Current Time Display */}
                    <div class="flex items-center justify-between px-3 py-2 bg-white/5 rounded-md mb-3">
                        <span class="text-white/60 text-sm">Tiempo actual:</span>
                        <span class="text-white font-mono font-semibold">{formatTime(props.currentTime)}</span>
                    </div>

                    {/* Create Segment Form */}
                    {creating.value ? (
                        <div class="space-y-3 px-1">
                            <div class="flex flex-col items-start gap-2">
                                <label class="text-white/80 text-sm">Tipo de segmento</label>
                                <select
                                    class="w-full bg-white/10 border border-white/20 rounded-md px-3 py-2 text-white text-sm focus:outline-none focus:border-white/40"
                                    value={segmentType.value}
                                    onInput={(e: any) => segmentType.value = e.target.value}
                                >
                                    {segmentTypes.map((type) => (
                                        <option key={type.value} value={type.value}>
                                            {type.label}
                                        </option>
                                    ))}
                                </select>
                            </div>

                            <div class="grid grid-cols-2 gap-2">
                                <div class="flex flex-col items-start gap-1">
                                    <label class="text-white/80 text-sm">Inicio</label>
                                    <div class="w-full bg-white/10 border border-white/20 rounded-md px-3 py-2 text-center">
                                        <span class="text-white font-mono">{formatTime(startTime.value)}</span>
                                    </div>
                                    <button
                                        onClick={captureStartTime}
                                        class="w-full px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded-md transition-colors"
                                    >
                                        Capturar
                                    </button>
                                </div>

                                {segmentTypes.find(st => st.value === segmentType.value)?.isRange && (
                                    <div class="flex flex-col items-start gap-1">
                                        <label class="text-white/80 text-sm">Fin</label>
                                        <div class="w-full bg-white/10 border border-white/20 rounded-md px-3 py-2 text-center">
                                            <span class="text-white font-mono">{endTime.value !== null ? formatTime(endTime.value) : '--:--'}</span>
                                        </div>
                                        <button
                                            onClick={captureEndTime}
                                            class="w-full px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded-md transition-colors"
                                        >
                                            Capturar
                                        </button>
                                    </div>
                                )}
                            </div>

                            {error.value && (
                                <div class="p-2 bg-red-900/30 border border-red-700/30 rounded-md">
                                    <span class="text-red-300 text-sm">{error.value}</span>
                                </div>
                            )}

                            <div class="flex gap-2 pt-2">
                                <button
                                    onClick={createSegment}
                                    disabled={saving.value}
                                    class="flex-1 px-4 py-2 bg-green-600 hover:bg-green-700 text-white text-sm font-medium rounded-md transition-colors disabled:opacity-50"
                                >
                                    {saving.value ? 'Guardando...' : 'Guardar'}
                                </button>
                                <button
                                    onClick={() => { creating.value = false; error.value = null; startTime.value = 0; endTime.value = null; }}
                                    class="px-4 py-2 bg-white/10 hover:bg-white/20 text-white text-sm font-medium rounded-md transition-colors"
                                >
                                    Cancelar
                                </button>
                            </div>
                        </div>
                    ) : (
                        <div class="space-y-2">
                            {/* Existing Segments */}
                            {segments.value.length > 0 && (
                                <div class="space-y-1">
                                    <div class="text-white/50 text-xs uppercase tracking-wider px-1 mb-2">Segmentos existentes</div>
                                    {segments.value.map((seg) => (
                                        <div
                                            key={seg.id}
                                            class="flex items-center justify-between p-2 bg-white/5 rounded-md hover:bg-white/10"
                                        >
                                            <div class="flex items-center gap-3">
                                                <div class={`px-2 py-0.5 rounded text-xs font-semibold text-white ${getSegmentTypeColor(seg.segment_type)}`}>
                                                    {getSegmentTypeLabel(seg.segment_type)}
                                                </div>
                                                <span class="text-white/80 text-sm font-mono">
                                                    {formatTime(seg.start_time || 0)}
                                                    {seg.end_time !== null && seg.end_time !== undefined ? ` - ${formatTime(seg.end_time)}` : ''}
                                                </span>
                                            </div>
                                            <button
                                                onClick={() => removeSegment(seg.id!)}
                                                class="text-red-400 hover:text-red-300 transition-colors p-1"
                                            >
                                                <CIcon icon="trash" size={16} />
                                            </button>
                                        </div>
                                    ))}
                                </div>
                            )}

                            {segments.value.length === 0 && !loading.value && (
                                <div class="justify-center py-6 text-center">
                                    <span class="text-white/40 text-sm">No hay segmentos</span>
                                </div>
                            )}

                            <div
                                class="mt-3 flex items-center justify-center px-4 py-2 bg-white/10 hover:bg-white/20 rounded-md cursor-pointer transition-colors"
                                onClick={() => creating.value = true}
                            >
                                <CIcon icon="plus" size={16} class="mr-2" />
                                <span>Agregar segmento</span>
                            </div>
                        </div>
                    )}
                </media-menu-items>
            </media-menu>
        );
    }
});
