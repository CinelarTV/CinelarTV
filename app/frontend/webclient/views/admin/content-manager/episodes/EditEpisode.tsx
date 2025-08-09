import { defineComponent, ref, onMounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import { toast } from "vue3-toastify";
import CImageUpload from "@/components/forms/CImageUpload";
import { ajax } from "@/lib/Ajax";
import Episode, { EpisodeData } from "@/app/models/Episode";

// Extend Episode type to include timing fields
type ExtendedEpisode = Episode & {
    skip_intro_start?: number;
    skip_intro_end?: number;
    episode_end?: number;
};

function formatTime(seconds: number | null): string {
    if (!seconds) return "";
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
}

function parseTime(timeString: string): number | null {
    if (!timeString) return null;
    const [mins, secs] = timeString.split(":").map(Number);
    return mins * 60 + secs;
}

export default defineComponent({
    name: "EditEpisode",
    components: { CImageUpload },
    setup() {
        const router = useRouter();
        const route = useRoute();

        const loading = ref(false);
        const saving = ref(false);
        const dragActive = ref(false);

        const episodeData = ref<ExtendedEpisode | null>(null);

        const fetchEpisodeData = async () => {
            loading.value = true;
            try {
                const response = await ajax.get(`/admin/content-manager/${route.params.contentId}/seasons/${route.params.seasonId}/episodes/${route.params.episodeId}/edit.json`);
                episodeData.value = response.data.data.episode;
            } catch (error) {
                toast.error("Error al cargar los datos del episodio");
            } finally {
                loading.value = false;
            }
        };

        const saveEpisode = async () => {
            saving.value = true;
            try {
                const formData = new FormData();
                if (episodeData.value) {
                    formData.append('title', episodeData.value.title || '');
                    formData.append('description', episodeData.value.description || '');
                    formData.append('url', episodeData.value.url || '');
                    if (episodeData.value.thumbnail) {
                        formData.append('thumbnail', episodeData.value.thumbnail);
                    }
                    if (episodeData.value.skip_intro_start) {
                        formData.append('skip_intro_start', episodeData.value.skip_intro_start.toString());
                    }
                    if (episodeData.value.skip_intro_end) {
                        formData.append('skip_intro_end', episodeData.value.skip_intro_end.toString());
                    }
                    if (episodeData.value.episode_end) {
                        formData.append('episode_end', episodeData.value.episode_end.toString());
                    }
                }

                await ajax.put(`/admin/content-manager/${route.params.contentId}/seasons/${route.params.seasonId}/episodes/${route.params.episodeId}/edit.json`, formData, {
                    headers: { 'Content-Type': 'multipart/form-data' },
                });

                toast.success("Episodio guardado correctamente");
                fetchEpisodeData();
            } catch (error) {
                toast.error("Hubo un error al guardar el episodio");
            } finally {
                saving.value = false;
            }
        };

        const handleInputChange = (field: keyof ExtendedEpisode, value: any) => {
            if (episodeData.value) {
                episodeData.value = {
                    ...episodeData.value,
                    [field]: value,
                    updated_at: new Date().toISOString()
                };
            }
        };

        const handleTimeChange = (field: "skip_intro_start" | "skip_intro_end" | "episode_end", value: string) => {
            const seconds = parseTime(value);
            handleInputChange(field, seconds);
        };

        const handleImageUpload = (file: File) => {
            handleInputChange("thumbnail", file);
        };

        const backToEditor = () => {
            router.push({
                name: "admin.content.manager.manage-episodes",
                params: {
                    contentId: route.params.contentId?.toString(),
                    seasonId: route.params.seasonId?.toString(),
                },
            });
        };

        onMounted(() => {
            fetchEpisodeData();
        });

        return () => (
            <div class="max-w-5xl mx-auto py-8">
                {/* Header */}
                <div class="flex items-center justify-between mb-8">
                    <button class="flex items-center gap-2 px-3 py-2 rounded hover:bg-gray-100 text-gray-700" onClick={backToEditor}>
                        <svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
                        </svg>
                        Regresar
                    </button>
                    <button
                        class="flex items-center gap-2 px-4 py-2 rounded bg-blue-600 text-white font-semibold hover:bg-blue-700 transition"
                        onClick={saveEpisode}
                        disabled={saving.value}
                    >
                        <svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                        </svg>
                        {saving.value ? "Guardando..." : "Guardar"}
                    </button>
                </div>

                {loading.value ? (
                    <div class="flex justify-center py-12">
                        <span class="text-lg text-gray-500">Cargando...</span>
                    </div>
                ) : episodeData.value ? (
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
                        {/* Main Content */}
                        <div class="md:col-span-2 space-y-8">
                            <div class="bg-white/10 rounded-lg shadow p-6 space-y-6 border border-white/5">
                                <div>
                                    <label class="block text-sm font-medium text-gray-700 mb-1">Título del Episodio</label>
                                    <input
                                        class="w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                                        value={episodeData.value.title || ''}
                                        onInput={e => handleInputChange("title", (e.target as HTMLInputElement).value)}
                                        placeholder="Título"
                                    />
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-700 mb-1">Descripción</label>
                                    <textarea
                                        class="w-full px-3 py-2 border rounded min-h-[100px] focus:outline-none focus:ring-2 focus:ring-blue-500"
                                        value={episodeData.value.description || ''}
                                        onInput={e => handleInputChange("description", (e.target as HTMLTextAreaElement).value)}
                                        placeholder="Descripción"
                                    />
                                    <div class="text-xs text-gray-400 mt-1">{(episodeData.value.description || '').length}/500 caracteres</div>
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-700 mb-1">URL</label>
                                    <input
                                        class="w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                                        value={episodeData.value.url || ''}
                                        onInput={e => handleInputChange("url", (e.target as HTMLInputElement).value)}
                                        placeholder="URL"
                                    />
                                </div>
                                {/* Timing Controls */}
                                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                                    <div>
                                        <label class="flex items-center gap-2 text-sm font-medium text-gray-700 mb-1">
                                            <svg class="h-4 w-4 text-orange-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" d="M5 12h14M12 5l7 7-7 7" />
                                            </svg>
                                            Inicio Skip Intro
                                        </label>
                                        <input
                                            type="text"
                                            class="w-full px-3 py-2 border rounded font-mono"
                                            placeholder="00:00"
                                            value={formatTime(episodeData.value.skip_intro_start)}
                                            onInput={e => handleTimeChange("skip_intro_start", (e.target as HTMLInputElement).value)}
                                        />
                                    </div>
                                    <div>
                                        <label class="flex items-center gap-2 text-sm font-medium text-gray-700 mb-1">
                                            <svg class="h-4 w-4 text-orange-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                                                <path stroke-linecap="round" stroke-linejoin="round" d="M5 12h14M12 5l7 7-7 7" />
                                            </svg>
                                            Fin Skip Intro
                                        </label>
                                        <input
                                            type="text"
                                            class="w-full px-3 py-2 border rounded font-mono"
                                            placeholder="00:00"
                                            value={formatTime(episodeData.value.skip_intro_end)}
                                            onInput={e => handleTimeChange("skip_intro_end", (e.target as HTMLInputElement).value)}
                                        />
                                    </div>

                                </div>
                            </div>
                        </div>
                        {/* Sidebar */}
                        <div class="space-y-8">
                            <div class="bg-white/10 rounded-lg shadow p-6 border border-white/5">
                                <label class="block text-sm font-medium text-gray-700 mb-2">Miniatura</label>
                                <CImageUpload
                                    modelValue={episodeData.value.thumbnail}
                                    label="Sube una miniatura"
                                    accept="image/*"
                                    onUpdate:modelValue={handleImageUpload}
                                />
                                {typeof episodeData.value.thumbnail === "string" && episodeData.value.thumbnail && (
                                    <img
                                        src={episodeData.value.thumbnail}
                                        alt="Miniatura actual"
                                        class="rounded-lg mt-4 w-full max-h-48 object-contain border border-gray-200"
                                    />
                                )}
                            </div>
                            <div class="bg-white/10 rounded-lg shadow p-6 border border-white/5">
                                <div class="text-sm text-gray-500 mb-2">Información del Episodio</div>
                                <div class="flex justify-between items-center mb-1">
                                    <span class="text-xs text-gray-500">Temporada</span>
                                    <span class="text-xs font-medium">{episodeData.value.season_id}</span>
                                </div>
                                <div class="flex justify-between items-center mb-1">
                                    <span class="text-xs text-gray-500">Creado</span>
                                    <span class="text-xs font-medium">
                                        {episodeData.value.created_at ? new Date(episodeData.value.created_at).toLocaleDateString("es-ES") : "-"}
                                    </span>
                                </div>
                                <div class="flex justify-between items-center">
                                    <span class="text-xs text-gray-500">Actualizado</span>
                                    <span class="text-xs font-medium">
                                        {episodeData.value.updated_at ? new Date(episodeData.value.updated_at).toLocaleDateString("es-ES") : "-"}
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                ) : (
                    <div class="flex justify-center py-12">
                        <span class="text-lg text-gray-500">No se encontraron datos del episodio</span>
                    </div>
                )}
            </div>
        );
    },
});