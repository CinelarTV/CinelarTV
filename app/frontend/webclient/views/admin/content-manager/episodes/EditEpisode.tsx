import { defineComponent, ref, onMounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import { toast } from "vue3-toastify";
import { ajax } from "@/lib/Ajax";
import CVideoableManager from "@/components/CVideoableManager";
import CSegmentManager from "@/components/CSegmentManager";
import CFormRow from "@/components/forms/CFormRow.tsx";

type EpisodeData = {
    title: string;
    description: string;
    thumbnail: string | File | null;
    thumbnailPreview: string | null;
    premium: boolean;
    segments?: any[];
    video_sources?: any[];
    season_id?: number;
    created_at?: string;
    updated_at?: string;
};

export default defineComponent({
    name: "EditEpisode",
    setup() {
        const router = useRouter();
        const route = useRoute();

        const loading = ref(true);
        const saving = ref(false);
        const isDragOver = ref(false);
        const fileInputRef = ref<HTMLInputElement | null>(null);

        const episodeData = ref<EpisodeData>({
            title: "",
            description: "",
            thumbnail: null,
            thumbnailPreview: null,
            premium: false,
        });

        const contentId = route.params.contentId?.toString() || "";
        const seasonId = route.params.seasonId?.toString() || "";
        const episodeId = route.params.episodeId?.toString() || "";

        const fetchEpisodeData = async () => {
            loading.value = true;
            try {
                const response = await ajax.get(
                    `/admin/content-manager/${contentId}/seasons/${seasonId}/episodes/${episodeId}/edit.json`
                );
                const ep = response.data.data.episode;
                episodeData.value = {
                    title: ep.title || "",
                    description: ep.description || "",
                    thumbnail: ep.thumbnail || null,
                    thumbnailPreview: ep.thumbnail || null,
                    premium: ep.premium || false,
                    segments: ep.segments || [],
                    video_sources: ep.video_sources || [],
                    season_id: ep.season_id,
                    created_at: ep.created_at,
                    updated_at: ep.updated_at,
                };
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
                formData.append("episode[title]", episodeData.value.title);
                formData.append("episode[description]", episodeData.value.description);
                formData.append("episode[premium]", String(episodeData.value.premium));
                if (episodeData.value.thumbnail instanceof File) {
                    formData.append("episode[thumbnail]", episodeData.value.thumbnail);
                }

                await ajax.put(
                    `/admin/content-manager/${contentId}/seasons/${seasonId}/episodes/${episodeId}/edit.json`,
                    formData,
                    { headers: { "Content-Type": "multipart/form-data" } }
                );

                toast.success("Episodio guardado correctamente");
                fetchEpisodeData();
            } catch (error) {
                toast.error("Hubo un error al guardar el episodio");
            } finally {
                saving.value = false;
            }
        };

        const handleFileSelect = (file: File) => {
            if (!file.type.startsWith("image/")) {
                toast.error("Solo se permiten archivos de imagen");
                return;
            }
            if (file.size > 10 * 1024 * 1024) {
                toast.error("El archivo no debe superar 10MB");
                return;
            }
            episodeData.value.thumbnail = file;
            episodeData.value.thumbnailPreview = URL.createObjectURL(file);
        };

        const handleDragOver = (e: DragEvent) => {
            e.preventDefault();
            isDragOver.value = true;
        };

        const handleDragLeave = () => {
            isDragOver.value = false;
        };

        const handleDrop = (e: DragEvent) => {
            e.preventDefault();
            isDragOver.value = false;
            const file = e.dataTransfer?.files[0];
            if (file) handleFileSelect(file);
        };

        const triggerFileInput = () => {
            fileInputRef.value?.click();
        };

        const handleFileInput = (e: Event) => {
            const input = e.target as HTMLInputElement;
            const file = input.files?.[0];
            if (file) handleFileSelect(file);
            input.value = "";
        };

        const removeThumbnail = () => {
            episodeData.value.thumbnail = null;
            episodeData.value.thumbnailPreview = null;
        };

        const backToEditor = () => {
            router.push({
                name: "admin.content.manager.manage-episodes",
                params: { contentId, seasonId },
            });
        };

        onMounted(() => {
            fetchEpisodeData();
        });

        return () => (
            <div class="max-w-5xl mx-auto px-4 sm:px-6 md:px-8 py-8">
                {loading.value ? (
                    <div class="flex items-center justify-center min-h-[400px]">
                        <div class="flex flex-col items-center gap-3">
                            <div class="animate-spin rounded-full h-12 w-12 border-2 border-white/30 border-t-[#00A8E1]" />
                            <p class="text-white/60 text-sm font-medium">Cargando...</p>
                        </div>
                    </div>
                ) : (
                    <>
                        {/* Header */}
                        <div class="mb-8">
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap-4">
                                    <button
                                        onClick={backToEditor}
                                        class="p-2 rounded-lg bg-white/5 hover:bg-white/10 transition-colors"
                                    >
                                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="w-5 h-5">
                                            <polyline points="15 18 9 12 15 6" />
                                        </svg>
                                    </button>
                                    <div>
                                        <h1 class="text-2xl md:text-3xl font-bold text-white">
                                            Editar episodio
                                        </h1>
                                        <p class="text-sm text-white/60 mt-1">
                                            {episodeData.value.title || "Sin titulo"}
                                        </p>
                                    </div>
                                </div>
                                <button
                                    onClick={saveEpisode}
                                    disabled={saving.value}
                                    class="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[var(--c-tertiary-color)] text-white font-semibold text-sm transition-all hover:bg-[var(--c-tertiary-100)] disabled:opacity-50 disabled:cursor-not-allowed"
                                >
                                    {saving.value ? (
                                        <div class="animate-spin rounded-full h-4 w-4 border-2 border-white/30 border-t-white" />
                                    ) : (
                                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                            <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z" />
                                            <polyline points="17 21 17 13 7 13 7 21" />
                                            <polyline points="7 3 7 8 15 8" />
                                        </svg>
                                    )}
                                    {saving.value ? "Guardando..." : "Guardar"}
                                </button>
                            </div>
                        </div>

                        {/* Content */}
                        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
                            {/* Main Column */}
                            <div class="lg:col-span-2 space-y-6">
                                {/* Basic Info */}
                                <div class="bg-white/5 rounded-xl p-6 ring-1 ring-white/10">
                                    <h2 class="text-lg font-semibold text-white mb-4">
                                        Informacion basica
                                    </h2>
                                    <div class="space-y-4">
                                        <CFormRow label="Titulo del episodio" for="ep-title">
                                            <input
                                                id="ep-title"
                                                class="c-input"
                                                value={episodeData.value.title}
                                                onInput={(e: InputEvent) => {
                                                    episodeData.value.title = (e.target as HTMLInputElement).value;
                                                }}
                                                placeholder="Titulo del episodio"
                                            />
                                        </CFormRow>

                                        <CFormRow label="Descripcion" for="ep-desc">
                                            <textarea
                                                id="ep-desc"
                                                class="c-input min-h-[100px] resize-y"
                                                value={episodeData.value.description}
                                                onInput={(e: InputEvent) => {
                                                    episodeData.value.description = (e.target as HTMLTextAreaElement).value;
                                                }}
                                                placeholder="Descripcion del episodio"
                                                rows={4}
                                            />
                                            <p class="text-xs text-white/40 mt-1">
                                                {(episodeData.value.description || "").length} caracteres
                                            </p>
                                        </CFormRow>
                                    </div>
                                </div>

                                {/* Segments */}
                                <div class="bg-white/5 rounded-xl p-6 ring-1 ring-white/10">
                                    <h2 class="text-lg font-semibold text-white mb-4">
                                        Segmentos
                                    </h2>
                                    <CSegmentManager
                                        initialSegments={episodeData.value.segments || []}
                                        episodeId={episodeId}
                                    />
                                </div>

                                {/* Video Sources */}
                                <div class="bg-white/5 rounded-xl p-6 ring-1 ring-white/10">
                                    <h2 class="text-lg font-semibold text-white mb-4">
                                        Fuentes de video
                                    </h2>
                                    <CVideoableManager
                                        initialVideoSources={episodeData.value.video_sources || []}
                                        contentId={contentId}
                                        seasonId={seasonId}
                                        episodeId={episodeId}
                                    />
                                </div>
                            </div>

                            {/* Sidebar */}
                            <div class="space-y-6">
                                {/* Thumbnail */}
                                <div class="bg-white/5 rounded-xl p-6 ring-1 ring-white/10">
                                    <h2 class="text-lg font-semibold text-white mb-4">
                                        Miniatura
                                    </h2>

                                    <input
                                        ref={fileInputRef}
                                        type="file"
                                        accept="image/*"
                                        class="hidden"
                                        onChange={handleFileInput}
                                    />

                                    {episodeData.value.thumbnailPreview ? (
                                        <div class="space-y-3">
                                            <img
                                                src={episodeData.value.thumbnailPreview}
                                                alt="Miniatura"
                                                class="rounded-lg w-full max-h-48 object-contain ring-1 ring-white/10"
                                            />
                                            <div class="flex gap-2">
                                                <button
                                                    onClick={triggerFileInput}
                                                    class="flex-1 flex items-center justify-center gap-2 px-3 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-white/80 text-sm transition-colors ring-1 ring-white/10"
                                                >
                                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                                                        <polyline points="17 8 12 3 7 8" />
                                                        <line x1="12" y1="3" x2="12" y2="15" />
                                                    </svg>
                                                    Cambiar
                                                </button>
                                                <button
                                                    onClick={removeThumbnail}
                                                    class="flex items-center justify-center gap-2 px-3 py-2 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-400 text-sm transition-colors ring-1 ring-red-500/20"
                                                >
                                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                        <polyline points="3 6 5 6 21 6" />
                                                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                                                    </svg>
                                                    Eliminar
                                                </button>
                                            </div>
                                        </div>
                                    ) : (
                                        <div
                                            class={[
                                                "flex flex-col items-center justify-center p-6 rounded-lg border-2 border-dashed transition-colors cursor-pointer",
                                                isDragOver.value
                                                    ? "border-[var(--c-tertiary-color)] bg-[var(--c-tertiary-color)]/10"
                                                    : "border-white/20 hover:border-white/40 bg-white/5",
                                            ]}
                                            onDragover={handleDragOver}
                                            onDragleave={handleDragLeave}
                                            onDrop={handleDrop}
                                            onClick={triggerFileInput}
                                        >
                                            <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" class="text-white/40 mb-3">
                                                <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
                                                <circle cx="8.5" cy="8.5" r="1.5" />
                                                <polyline points="21 15 16 10 5 21" />
                                            </svg>
                                            <p class="text-white/60 text-sm font-medium mb-1">
                                                Arrastra una imagen aqui
                                            </p>
                                            <p class="text-white/40 text-xs">
                                                o haz clic para seleccionar
                                            </p>
                                            <p class="text-white/30 text-xs mt-2">
                                                JPG, PNG, WebP - Max 10MB
                                            </p>
                                        </div>
                                    )}
                                </div>

                                {/* Premium */}
                                <div class="bg-white/5 rounded-xl p-6 ring-1 ring-white/10">
                                    <h2 class="text-lg font-semibold text-white mb-4">
                                        Acceso
                                    </h2>
                                    <div class="flex items-center justify-between p-3 rounded-lg bg-yellow-500/10 border border-yellow-500/20">
                                        <div>
                                            <p class="text-xs font-bold text-white uppercase tracking-wider">
                                                Premium
                                            </p>
                                            <p class="text-[10px] text-white/40">
                                                Solo suscriptores
                                            </p>
                                        </div>
                                        <button
                                            onClick={() => {
                                                episodeData.value.premium = !episodeData.value.premium;
                                            }}
                                            class={[
                                                "relative inline-flex h-5 w-9 items-center rounded-full transition-colors focus:outline-none",
                                                episodeData.value.premium ? "bg-yellow-500" : "bg-white/20",
                                            ]}
                                        >
                                            <span
                                                class={[
                                                    "inline-block h-3 w-3 transform rounded-full bg-white transition-transform",
                                                    episodeData.value.premium ? "translate-x-5" : "translate-x-1",
                                                ]}
                                            />
                                        </button>
                                    </div>
                                </div>

                                {/* Info */}
                                <div class="bg-white/5 rounded-xl p-6 ring-1 ring-white/10">
                                    <h2 class="text-lg font-semibold text-white mb-4">
                                        Informacion
                                    </h2>
                                    <div class="space-y-3">
                                        <div class="flex justify-between items-center">
                                            <span class="text-sm text-white/60">Temporada</span>
                                            <span class="text-sm font-medium text-white">
                                                {episodeData.value.season_id || "-"}
                                            </span>
                                        </div>
                                        <div class="flex justify-between items-center">
                                            <span class="text-sm text-white/60">Creado</span>
                                            <span class="text-sm font-medium text-white">
                                                {episodeData.value.created_at
                                                    ? new Date(episodeData.value.created_at).toLocaleDateString("es-ES")
                                                    : "-"}
                                            </span>
                                        </div>
                                        <div class="flex justify-between items-center">
                                            <span class="text-sm text-white/60">Actualizado</span>
                                            <span class="text-sm font-medium text-white">
                                                {episodeData.value.updated_at
                                                    ? new Date(episodeData.value.updated_at).toLocaleDateString("es-ES")
                                                    : "-"}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </>
                )}
            </div>
        );
    },
});
