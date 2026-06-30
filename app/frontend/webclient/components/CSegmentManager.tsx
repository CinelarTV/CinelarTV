import { defineComponent, ref, onMounted, PropType } from 'vue';
import CButton from './forms/c-button';
import CFormRow from './forms/CFormRow';
import { ajax } from "@/lib/Ajax";

interface Segment {
    id?: string | number;
    segment_type: string;
    start_time?: number;
    end_time?: number;
}

export default defineComponent({
    name: 'CSegmentManager',
    props: {
        contentId: { type: String, required: false, default: null },
        episodeId: { type: String, required: false, default: null },
        initialSegments: { type: Array as PropType<Segment[]>, default: () => [] },
    },
    setup(props) {
        const segments = ref<Segment[]>(props.initialSegments || []);
        const creating = ref(false);
        const segmentType = ref<string>('skip_intro');
        const startTime = ref('');
        const endTime = ref('');
        const saving = ref(false);
        const error = ref<string | null>(null);

        const segmentTypes = [
            { value: 'skip_intro', label: 'Omitir Intro', isRange: true },
            { value: 'skip_resume', label: 'Omitir Resumen', isRange: true },
            { value: 'next_episode', label: 'Siguiente Episodio', isRange: false },
            { value: 'credits_start', label: 'Inicio Creditos', isRange: false },
        ];

        const getApiBase = () => {
            if (props.episodeId) return `/admin/episodes/${props.episodeId}/segments`;
            if (props.contentId) return `/admin/contents/${props.contentId}/segments`;
            return '';
        };

        const fetchSegments = async () => {
            try {
                const url = getApiBase();
                if (!url) return;
                const res = await ajax.get(url);
                const data = res.data;
                segments.value = Array.isArray(data) ? data : (data.segments || []);
            } catch (err) {
                console.error('Error fetching segments:', err);
            }
        };

        const formatTime = (seconds: number | null): string => {
            if (!seconds) return '';
            const mins = Math.floor(seconds / 60);
            const secs = Math.floor(seconds % 60);
            return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
        };

        const parseTime = (timeString: string): number | null => {
            if (!timeString) return null;
            const [mins, secs] = timeString.split(':').map(Number);
            return mins * 60 + secs;
        };

        const getSegmentTypeInfo = (type: string) => {
            return segmentTypes.find(st => st.value === type) || segmentTypes[0];
        };

        const getSegmentTypeColor = (type: string): string => {
            switch (type) {
                case 'skip_intro': return 'bg-orange-500/20 text-orange-400';
                case 'skip_resume': return 'bg-purple-500/20 text-purple-400';
                case 'next_episode': return 'bg-green-500/20 text-green-400';
                case 'credits_start': return 'bg-blue-500/20 text-blue-400';
                default: return 'bg-white/10 text-white/60';
            }
        };

        const createSegment = async () => {
            const selectedType = segmentTypes.find(st => st.value === segmentType.value);
            if (!selectedType) return;

            if (selectedType.isRange) {
                if (!startTime.value || !endTime.value) {
                    error.value = 'Se requieren tiempos de inicio y fin para este tipo de segmento';
                    return;
                }
            } else {
                if (!startTime.value) {
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
                        start_time: parseTime(startTime.value),
                    }
                };

                if (selectedType.isRange) {
                    segmentData.segment.end_time = parseTime(endTime.value);
                }

                const res = await ajax.post(url, segmentData);

                if (res.data.error) {
                    throw new Error(res.data.error);
                }

                startTime.value = '';
                endTime.value = '';
                creating.value = false;
                await fetchSegments();
            } catch (e: any) {
                error.value = e.message || 'Error desconocido';
            } finally {
                saving.value = false;
            }
        };

        const removeSegment = async (id: string | number) => {
            if (!confirm('Estas seguro de que quieres eliminar este segmento?')) return;
            try {
                await ajax(`${getApiBase()}/${id}`, { method: 'DELETE' });
                await fetchSegments();
            } catch (err) {
                console.error('Error removing segment:', err);
            }
        };

        const resetForm = () => {
            creating.value = false;
            error.value = null;
            startTime.value = '';
            endTime.value = '';
        };

        const selectedTypeInfo = () => segmentTypes.find(st => st.value === segmentType.value);

        onMounted(fetchSegments);

        return () => (
            <div class="space-y-4">
                {/* Header */}
                <div class="flex items-center justify-between">
                    <h2 class="text-lg font-semibold text-white">
                        Segmentos de Tiempo
                        <span class="ml-2 text-sm font-normal text-white/50">
                            ({segments.value.length})
                        </span>
                    </h2>
                </div>

                {/* Empty State */}
                {segments.value.length === 0 && !creating.value && (
                    <div class="text-center py-12 bg-white/5 rounded-xl ring-1 ring-white/10">
                        <div class="w-12 h-12 mx-auto mb-4 bg-white/5 rounded-full flex items-center justify-center">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-white/40">
                                <path d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                        </div>
                        <h3 class="text-base font-medium text-white mb-1">
                            No hay segmentos
                        </h3>
                        <p class="text-sm text-white/50 mb-4">
                            Agrega segmentos de tiempo para mejorar la experiencia
                        </p>
                        <CButton onClick={() => creating.value = true} icon="plus">
                            Agregar segmento
                        </CButton>
                    </div>
                )}

                {/* Segments List */}
                {segments.value.length > 0 && (
                    <div class="space-y-3">
                        {segments.value.map((seg) => (
                            <div
                                key={seg.id}
                                class="bg-white/5 rounded-xl p-4 ring-1 ring-white/10 hover:ring-white/20 transition-all"
                            >
                                <div class="flex items-center justify-between gap-4">
                                    <div class="flex items-center gap-4 flex-1 min-w-0">
                                        {/* Type Badge */}
                                        <span class={`flex-shrink-0 px-3 py-1.5 rounded-lg text-xs font-medium ${getSegmentTypeColor(seg.segment_type)}`}>
                                            {getSegmentTypeInfo(seg.segment_type).label}
                                        </span>

                                        {/* Time Info */}
                                        <div class="flex items-center gap-3 flex-1 min-w-0">
                                            <div class="flex-shrink-0 w-8 h-8 bg-white/5 rounded-lg flex items-center justify-center">
                                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-white/40">
                                                    <circle cx="12" cy="12" r="10" />
                                                    <polyline points="12 6 12 12 16 14" />
                                                </svg>
                                            </div>
                                            <div class="min-w-0">
                                                <p class="text-sm font-medium text-white font-mono">
                                                    {seg.start_time !== null && seg.start_time !== undefined
                                                        ? formatTime(seg.start_time)
                                                        : 'N/A'}
                                                    {seg.end_time !== null && seg.end_time !== undefined
                                                        ? ` - ${formatTime(seg.end_time)}`
                                                        : ''}
                                                </p>
                                                <p class="text-xs text-white/50">
                                                    {seg.end_time != null ? 'Rango de tiempo' : 'Punto especifico'}
                                                </p>
                                            </div>
                                        </div>
                                    </div>

                                    {/* Delete */}
                                    <button
                                        onClick={() => removeSegment(seg.id!)}
                                        class="p-2 rounded-lg text-white/40 hover:text-red-400 hover:bg-red-500/10 transition-colors"
                                    >
                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                            <polyline points="3 6 5 6 21 6" />
                                            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                                        </svg>
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {/* Create Form */}
                {creating.value && (
                    <div class="bg-white/5 rounded-xl p-6 ring-1 ring-white/10">
                        <h3 class="text-base font-semibold text-white mb-4">
                            Agregar segmento
                        </h3>

                        {/* Segment Type */}
                        <CFormRow label="Tipo de segmento">
                            <select
                                class="c-input w-full"
                                value={segmentType.value}
                                onInput={(e: Event) => segmentType.value = (e.target as HTMLSelectElement).value}
                            >
                                {segmentTypes.map((type) => (
                                    <option key={type.value} value={type.value}>
                                        {type.label}
                                    </option>
                                ))}
                            </select>
                        </CFormRow>

                        {/* Time Inputs */}
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mt-4">
                            <CFormRow label="Tiempo de inicio (MM:SS)">
                                <input
                                    type="text"
                                    class="c-input w-full font-mono"
                                    placeholder="00:00"
                                    value={startTime.value}
                                    onInput={(e: Event) => startTime.value = (e.target as HTMLInputElement).value}
                                />
                            </CFormRow>

                            {selectedTypeInfo()?.isRange && (
                                <CFormRow label="Tiempo de fin (MM:SS)">
                                    <input
                                        type="text"
                                        class="c-input w-full font-mono"
                                        placeholder="00:00"
                                        value={endTime.value}
                                        onInput={(e: Event) => endTime.value = (e.target as HTMLInputElement).value}
                                    />
                                </CFormRow>
                            )}
                        </div>

                        {/* Error */}
                        {error.value && (
                            <div class="mt-4 p-3 bg-red-500/10 rounded-lg ring-1 ring-red-500/20">
                                <div class="flex items-center gap-2 text-red-400 text-sm">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <circle cx="12" cy="12" r="10" />
                                        <line x1="12" y1="8" x2="12" y2="12" />
                                        <line x1="12" y1="16" x2="12.01" y2="16" />
                                    </svg>
                                    {error.value}
                                </div>
                            </div>
                        )}

                        {/* Actions */}
                        <div class="flex gap-3 mt-6">
                            <CButton onClick={createSegment} loading={saving.value} icon="plus">
                                Agregar
                            </CButton>
                            <CButton onClick={resetForm} variant="ghost" class="text-white/60 hover:text-white">
                                Cancelar
                            </CButton>
                        </div>
                    </div>
                )}

                {/* Add Button */}
                {!creating.value && segments.value.length > 0 && (
                    <button
                        onClick={() => creating.value = true}
                        class="w-full flex items-center justify-center gap-2 p-3 rounded-xl border-2 border-dashed border-white/10 hover:border-white/20 text-white/60 hover:text-white/80 text-sm font-medium transition-colors"
                    >
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <line x1="12" y1="5" x2="12" y2="19" />
                            <line x1="5" y1="12" x2="19" y2="12" />
                        </svg>
                        Agregar otro segmento
                    </button>
                )}
            </div>
        );
    }
});
