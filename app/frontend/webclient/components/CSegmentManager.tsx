import { defineComponent, ref, onMounted, PropType } from 'vue';
import CButton from './forms/c-button';
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
            { value: 'credits_start', label: 'Inicio Créditos', isRange: false },
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

                const res = await fetch(url);
                const data = await res.json();
                segments.value = Array.isArray(data) ? data : (data.segments || []);
            } catch (error) {
                console.error('Error fetching segments:', error);
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
            if (!confirm('¿Estás seguro de que quieres eliminar este segmento?')) return;

            try {
                const url = `${getApiBase()}/${id}`;
                await ajax(url, { method: 'DELETE' });
                await fetchSegments();
            } catch (error) {
                console.error('Error removing segment:', error);
            }
        };

        onMounted(async () => {
            await fetchSegments();
        });

        return () => (
            <div class="segment-manager space-y-6">
                {/* Header */}
                <div class="flex items-center justify-between">
                    <h2 class="text-xl font-semibold text-[var(--c-body-text-color)]">
                        Segmentos de Tiempo
                        <span class="ml-2 text-sm text-[var(--c-primary-900)]">
                            ({segments.value.length})
                        </span>
                    </h2>
                </div>

                {/* Empty State */}
                {segments.value.length === 0 && !creating.value && (
                    <div class="text-center py-12 bg-[rgba(255,255,255,0.02)] rounded-xl border border-[rgba(255,255,255,0.12)]">
                        <div class="w-16 h-16 mx-auto mb-4 bg-[rgba(255,255,255,0.05)] rounded-full flex items-center justify-center">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-[var(--c-primary-900)]">
                                <path d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                        </div>
                        <h3 class="text-lg font-medium text-[var(--c-body-text-color)] mb-2">
                            No hay segmentos
                        </h3>
                        <p class="text-[var(--c-primary-900)] mb-6">
                            Agrega segmentos de tiempo para mejorar la experiencia de visualización
                        </p>
                        <CButton
                            onClick={() => creating.value = true}
                            icon="plus"
                        >
                            Agregar segmento
                        </CButton>
                    </div>
                )}

                {/* Segments List */}
                {segments.value.length > 0 && (
                    <div class="space-y-3">
                        <h3 class="text-sm font-medium text-[var(--c-primary-900)] uppercase tracking-wider">
                            Segmentos existentes
                        </h3>
                        <div class="space-y-3">
                            {segments.value.map((seg) => (
                                <div key={seg.id} class="bg-[var(--c-primary-100)] rounded-xl p-6 ring-1 ring-[var(--c-primary-200)]">
                                    <div class="flex items-center justify-between">
                                        <div class="flex items-center gap-4 flex-1 min-w-0">
                                            {/* Type Badge */}
                                            <div class={`px-3 py-1.5 rounded-lg text-xs font-semibold text-white ${getSegmentTypeColor(seg.segment_type)}`}>
                                                {getSegmentTypeLabel(seg.segment_type)}
                                            </div>

                                            {/* Time Info */}
                                            <div class="flex-1 min-w-0 overflow-hidden">
                                                <div class="flex items-center gap-3 min-w-0">
                                                    <div class="flex-shrink-0 w-8 h-8 bg-[var(--c-primary-200)] rounded-lg flex items-center justify-center">
                                                        <span class="text-sm">⏱️</span>
                                                    </div>
                                                    <div class="flex-1 min-w-0">
                                                        <p class="text-sm text-[var(--c-body-text-color)] font-medium">
                                                            {seg.start_time !== null && seg.start_time !== undefined ? formatTime(seg.start_time) : 'N/A'}
                                                            {seg.end_time !== null && seg.end_time !== undefined ? ` - ${formatTime(seg.end_time)}` : ''}
                                                        </p>
                                                        <p class="text-xs text-[var(--c-primary-900)] mt-0.5">
                                                            {seg.end_time !== null && seg.end_time !== undefined ? 'Rango de tiempo' : 'Punto específico'}
                                                        </p>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Actions */}
                                        <div class="flex items-center gap-3 flex-shrink-0">
                                            <CButton
                                                icon="trash"
                                                class="text-red-400 hover:text-red-300 hover:bg-red-900/20 transition-colors"
                                                onClick={() => removeSegment(seg.id!)}
                                            />
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}

                {/* Create Segment Form */}
                {creating.value && (
                    <div class="bg-[rgba(255,255,255,0.02)] rounded-xl border border-[rgba(255,255,255,0.12)] p-6">
                        <div class="flex items-center gap-2 mb-6">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-[var(--c-primary-300)]">
                                <path d="M12 5v14m-7-7h14" />
                            </svg>
                            <h3 class="text-lg font-semibold text-[var(--c-body-text-color)]">
                                Agregar segmento
                            </h3>
                        </div>

                        {/* Segment Type Selector */}
                        <div class="mb-6">
                            <label class="block text-sm font-medium text-[var(--c-body-text-color)] mb-2">
                                Tipo de segmento
                            </label>
                            <select
                                class="c-input w-full"
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

                        {/* Time Inputs */}
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                            <div>
                                <label class="block text-sm font-medium text-[var(--c-body-text-color)] mb-2">
                                    Tiempo de inicio (MM:SS)
                                </label>
                                <input
                                    type="text"
                                    class="c-input w-full font-mono"
                                    placeholder="00:00"
                                    value={startTime.value}
                                    onInput={(e: any) => startTime.value = e.target.value}
                                />
                            </div>
                            {segmentTypes.find(st => st.value === segmentType.value)?.isRange && (
                                <div>
                                    <label class="block text-sm font-medium text-[var(--c-body-text-color)] mb-2">
                                        Tiempo de fin (MM:SS)
                                    </label>
                                    <input
                                        type="text"
                                        class="c-input w-full font-mono"
                                        placeholder="00:00"
                                        value={endTime.value}
                                        onInput={(e: any) => endTime.value = e.target.value}
                                    />
                                </div>
                            )}
                        </div>

                        {/* Error Message */}
                        {error.value && (
                            <div class="mb-6 p-4 bg-red-900/20 border border-red-700/50 rounded-lg">
                                <div class="flex items-center gap-2 text-red-400">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <circle cx="12" cy="12" r="10" />
                                        <line x1="12" y1="8" x2="12" y2="12" />
                                        <line x1="12" y1="16" x2="12.01" y2="16" />
                                    </svg>
                                    <span class="text-sm">{error.value}</span>
                                </div>
                            </div>
                        )}

                        {/* Actions */}
                        <div class="flex gap-3">
                            <CButton onClick={createSegment} loading={saving.value} icon="plus">
                                Agregar segmento
                            </CButton>
                            <CButton onClick={() => { creating.value = false; error.value = null; startTime.value = ''; endTime.value = ''; }} variant="ghost" class="text-[var(--c-primary-900)] hover:text-[var(--c-body-text-color)]">
                                Cancelar
                            </CButton>
                        </div>
                    </div>
                )}

                {!creating.value && segments.value.length > 0 && (
                    <div class="text-center">
                        <CButton onClick={() => creating.value = true} icon="plus">
                            Agregar otro segmento
                        </CButton>
                    </div>
                )}
            </div>
        );
    }
});
