import { defineComponent, ref, onMounted, PropType } from 'vue';
import CButton from './forms/c-button';
import CFormRow from './forms/CFormRow';
import CTranscodingProgress from './CTranscodingProgress.vue';
import { ajax } from "@/lib/Ajax";
import { isAxiosError } from "axios";

interface VideoSource {
    id?: string | number;
    url?: string;
    quality?: string;
    format?: string;
    storage_location?: string;
    status?: string;
}

export default defineComponent({
    name: 'CVideoableManager',
    props: {
        contentId: { type: String, required: true },
        seasonId: { type: String, required: false, default: null },
        episodeId: { type: String, required: false, default: null },
        initialVideoSources: { type: Array as PropType<VideoSource[]>, default: () => [] },
    },
    setup(props) {
        const videoSources = ref<VideoSource[]>(props.initialVideoSources || []);
        const creating = ref(false);
        const sourceType = ref<'file' | 'url'>('file');
        const urlInput = ref('');
        const uploading = ref(false);
        const uploadError = ref<string | null>(null);
        const uploadProgress = ref(0);
        const fileInput = ref<HTMLInputElement | null>(null);
        const selectedFile = ref<File | null>(null);
        const isDragOver = ref(false);

        const getApiBase = () => {
            if (props.episodeId) return `/admin/episodes/${props.episodeId}/video_sources`;
            if (props.contentId) return `/admin/contents/${props.contentId}/video_sources`;
            return '';
        };

        const fetchVideoSources = async () => {
            try {
                const url = getApiBase();
                if (!url) return;
                const res = await fetch(url);
                const data = await res.json();
                videoSources.value = Array.isArray(data) ? data : (data.video_sources || []);
            } catch (error) {
                console.error('Error fetching video sources:', error);
            }
        };

        const addByUrl = async () => {
            if (!urlInput.value.trim()) return;
            uploading.value = true;
            uploadError.value = null;

            try {
                const url = getApiBase();
                if (!url) return;
                const res = await ajax.post(url, {
                    video_source: {
                        url: urlInput.value.trim(),
                        quality: '720p',
                        format: 'mp4',
                        storage_location: 'external_url'
                    }
                });

                if (isAxiosError(res)) {
                    throw new Error(res.response?.data?.error || 'Error al agregar fuente');
                }

                urlInput.value = '';
                creating.value = false;
                await fetchVideoSources();
            } catch (e: any) {
                uploadError.value = e.message || 'Error desconocido';
            } finally {
                uploading.value = false;
            }
        };

        const removeVideoSource = async (id: string | number) => {
            if (!confirm('¿Estás seguro de que quieres eliminar esta fuente de video?')) return;
            try {
                await ajax(`/admin/video_sources/${id}`, { method: 'DELETE' });
                await fetchVideoSources();
            } catch (error) {
                console.error('Error removing video source:', error);
            }
        };

        const triggerFileInput = () => fileInput.value?.click();

        const handleFileChange = (event: Event) => {
            const file = (event.target as HTMLInputElement).files?.[0];
            if (file) selectedFile.value = file;
        };

        const handleDrop = (event: DragEvent) => {
            isDragOver.value = false;
            const file = event.dataTransfer?.files[0];
            if (file?.type.startsWith('video/')) {
                selectedFile.value = file;
            }
        };

        const uploadFile = async () => {
            if (!selectedFile.value) return;
            uploading.value = true;
            uploadError.value = null;
            uploadProgress.value = 0;

            try {
                const endpoint = getApiBase();
                if (!endpoint) return;

                const formData = new FormData();
                formData.append('video_source[file]', selectedFile.value);

                const xhr = new XMLHttpRequest();
                xhr.upload.addEventListener('progress', (e) => {
                    if (e.lengthComputable) {
                        uploadProgress.value = Math.round((e.loaded / e.total) * 100);
                    }
                });

                xhr.addEventListener('load', () => {
                    uploading.value = false;
                    uploadProgress.value = 0;
                    selectedFile.value = null;
                    creating.value = false;
                    fetchVideoSources();
                });

                xhr.addEventListener('error', () => {
                    uploadError.value = 'Error al subir el archivo';
                    uploading.value = false;
                    uploadProgress.value = 0;
                });

                xhr.open('POST', endpoint);
                xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
                const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
                if (csrfToken) xhr.setRequestHeader('X-CSRF-Token', csrfToken);
                xhr.send(formData);
            } catch {
                uploadError.value = 'Error al subir el archivo';
                uploading.value = false;
                uploadProgress.value = 0;
            }
        };

        const formatFileSize = (bytes: number) => {
            if (bytes === 0) return '0 Bytes';
            const k = 1024;
            const sizes = ['Bytes', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        };

        const getFileName = (url: string | undefined) => {
            if (!url) return 'Sin nombre';
            try {
                const pathname = new URL(url).pathname;
                return decodeURIComponent(pathname.split('/').pop() || 'video');
            } catch {
                const parts = url.split('/');
                return parts[parts.length - 1] || url;
            }
        };

        const getQualityBadgeColor = (quality?: string) => {
            switch (quality) {
                case '1080p': case 'HD': return 'bg-green-500/20 text-green-400';
                case '720p': return 'bg-blue-500/20 text-blue-400';
                case '480p': return 'bg-yellow-500/20 text-yellow-400';
                default: return 'bg-white/10 text-white/60';
            }
        };

        const resetForm = () => {
            creating.value = false;
            uploadError.value = null;
            selectedFile.value = null;
            urlInput.value = '';
        };

        onMounted(fetchVideoSources);

        return () => (
            <div class="space-y-4">
                {/* Header */}
                <div class="flex items-center justify-between">
                    <h2 class="text-lg font-semibold text-white">
                        Fuentes de Video
                        <span class="ml-2 text-sm font-normal text-white/50">
                            ({videoSources.value.length})
                        </span>
                    </h2>
                </div>

                {/* Video Sources List */}
                {videoSources.value.length > 0 && (
                    <div class="space-y-3">
                        {videoSources.value.map((vs) => (
                            <div
                                key={vs.id}
                                class="bg-white/5 rounded-xl p-4 ring-1 ring-white/10 hover:ring-white/20 transition-all"
                            >
                                <div class="flex items-start justify-between gap-4">
                                    <div class="flex items-start gap-3 flex-1 min-w-0">
                                        {/* Icon */}
                                        <div class="flex-shrink-0 w-10 h-10 bg-white/5 rounded-lg flex items-center justify-center">
                                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-white/40">
                                                <path d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                                            </svg>
                                        </div>

                                        {/* Info */}
                                        <div class="flex-1 min-w-0">
                                            <h4 class="text-sm font-medium text-white truncate mb-1" title={vs.url}>
                                                {getFileName(vs.url)}
                                            </h4>
                                            <div class="flex items-center gap-2 flex-wrap">
                                                <span class={`px-2 py-0.5 rounded text-xs font-medium ${getQualityBadgeColor(vs.quality)}`}>
                                                    {vs.quality || 'SD'}
                                                </span>
                                                <span class="text-xs text-white/50">
                                                    {vs.format?.toUpperCase() || 'MP4'}
                                                </span>
                                                <span class="text-xs text-white/30">•</span>
                                                <span class="text-xs text-white/50">
                                                    {vs.storage_location === 'url' ? 'Externa' : 'Local'}
                                                </span>
                                                {vs.status && (
                                                    <>
                                                        <span class="text-xs text-white/30">•</span>
                                                        <span class={`text-xs font-medium ${
                                                            vs.status === 'active' ? 'text-green-400' :
                                                            vs.status === 'processing' ? 'text-yellow-400' : 'text-red-400'
                                                        }`}>
                                                            {vs.status === 'active' ? 'Activo' :
                                                             vs.status === 'processing' ? 'Procesando' : vs.status}
                                                        </span>
                                                    </>
                                                )}
                                            </div>

                                            {/* Transcoding progress */}
                                            {vs.status === 'processing' && (
                                                <div class="mt-3">
                                                    <CTranscodingProgress
                                                        videoSourceId={vs.id!}
                                                        on-transcoding-completed={fetchVideoSources}
                                                    />
                                                </div>
                                            )}
                                        </div>
                                    </div>

                                    {/* Delete */}
                                    <button
                                        onClick={() => removeVideoSource(vs.id!)}
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

                {/* Empty State */}
                {videoSources.value.length === 0 && !creating.value && (
                    <div class="text-center py-12 bg-white/5 rounded-xl ring-1 ring-white/10">
                        <div class="w-12 h-12 mx-auto mb-4 bg-white/5 rounded-full flex items-center justify-center">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-white/40">
                                <path d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                            </svg>
                        </div>
                        <h3 class="text-base font-medium text-white mb-1">
                            No hay fuentes de video
                        </h3>
                        <p class="text-sm text-white/50 mb-4">
                            Agrega tu primera fuente de video para comenzar
                        </p>
                        <CButton onClick={() => creating.value = true} icon="plus">
                            Agregar fuente
                        </CButton>
                    </div>
                )}

                {/* Add Form */}
                {creating.value && (
                    <div class="bg-white/5 rounded-xl p-6 ring-1 ring-white/10">
                        <h3 class="text-base font-semibold text-white mb-4">
                            Agregar fuente de video
                        </h3>

                        {/* Source Type Toggle */}
                        <div class="flex gap-2 mb-6">
                            <button
                                onClick={() => sourceType.value = 'file'}
                                class={[
                                    "flex-1 flex items-center justify-center gap-2 px-4 py-3 rounded-lg text-sm font-medium transition-colors",
                                    sourceType.value === 'file'
                                        ? "bg-[var(--c-primary-color)]/20 text-[var(--c-primary-color)] ring-1 ring-[var(--c-primary-color)]/30"
                                        : "bg-white/5 text-white/60 hover:bg-white/10 ring-1 ring-white/10"
                                ]}
                            >
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                                    <polyline points="17 8 12 3 7 8" />
                                    <line x1="12" y1="3" x2="12" y2="15" />
                                </svg>
                                Subir archivo
                            </button>
                            <button
                                onClick={() => sourceType.value = 'url'}
                                class={[
                                    "flex-1 flex items-center justify-center gap-2 px-4 py-3 rounded-lg text-sm font-medium transition-colors",
                                    sourceType.value === 'url'
                                        ? "bg-[var(--c-primary-color)]/20 text-[var(--c-primary-color)] ring-1 ring-[var(--c-primary-color)]/30"
                                        : "bg-white/5 text-white/60 hover:bg-white/10 ring-1 ring-white/10"
                                ]}
                            >
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71" />
                                    <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71" />
                                </svg>
                                URL externa
                            </button>
                        </div>

                        {/* File Upload */}
                        {sourceType.value === 'file' && (
                            <div>
                                <input
                                    ref={fileInput}
                                    type="file"
                                    accept="video/*"
                                    onChange={handleFileChange}
                                    class="hidden"
                                />

                                {!selectedFile.value ? (
                                    <div
                                        onClick={triggerFileInput}
                                        onDragover={(e: DragEvent) => { e.preventDefault(); isDragOver.value = true; }}
                                        onDragleave={() => { isDragOver.value = false; }}
                                        onDrop={handleDrop}
                                        class={[
                                            "flex flex-col items-center justify-center p-8 rounded-lg border-2 border-dashed transition-colors cursor-pointer",
                                            isDragOver.value
                                                ? "border-[var(--c-primary-color)] bg-[var(--c-primary-color)]/5"
                                                : "border-white/20 hover:border-white/30 bg-white/5"
                                        ]}
                                    >
                                        <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" class="text-white/40 mb-3">
                                            <path d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                                        </svg>
                                        <p class="text-white/80 font-medium mb-1">Arrastra un video aqui</p>
                                        <p class="text-sm text-white/50">o haz clic para seleccionar</p>
                                        <p className="text-xs text-white/40 mt-2">MP4, AVI, MOV, MKV - Max 500MB</p>
                                    </div>
                                ) : (
                                    <div class="flex items-center gap-4 p-4 bg-white/5 rounded-lg ring-1 ring-white/10">
                                        <div class="flex-shrink-0 w-10 h-10 bg-white/10 rounded-lg flex items-center justify-center">
                                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-white/60">
                                                <path d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                                            </svg>
                                        </div>
                                        <div class="flex-1 min-w-0">
                                            <p class="text-sm font-medium text-white truncate">{selectedFile.value.name}</p>
                                            <p class="text-xs text-white/50">{formatFileSize(selectedFile.value.size)}</p>
                                        </div>
                                        <button
                                            onClick={() => selectedFile.value = null}
                                            class="p-2 rounded-lg text-white/40 hover:text-red-400 hover:bg-red-500/10 transition-colors"
                                        >
                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                                <line x1="18" y1="6" x2="6" y2="18" />
                                                <line x1="6" y1="6" x2="18" y2="18" />
                                            </svg>
                                        </button>
                                    </div>
                                )}

                                {/* Progress */}
                                {uploadProgress.value > 0 && uploadProgress.value < 100 && (
                                    <div class="mt-4">
                                        <div class="flex justify-between text-xs text-white/50 mb-1.5">
                                            <span>Subiendo...</span>
                                            <span>{uploadProgress.value}%</span>
                                        </div>
                                        <div class="w-full bg-white/10 rounded-full h-1.5">
                                            <div
                                                class="bg-[var(--c-primary-color)] h-1.5 rounded-full transition-all duration-300"
                                                style={{ width: `${uploadProgress.value}%` }}
                                            />
                                        </div>
                                    </div>
                                )}

                                {/* Upload Button */}
                                {selectedFile.value && !uploading.value && (
                                    <div class="mt-4">
                                        <CButton onClick={uploadFile} icon="upload" class="w-full justify-center">
                                            Subir video
                                        </CButton>
                                    </div>
                                )}
                            </div>
                        )}

                        {/* URL Input */}
                        {sourceType.value === 'url' && (
                            <CFormRow label="URL del video">
                                <div class="flex gap-3">
                                    <input
                                        type="url"
                                        class="c-input flex-1"
                                        placeholder="https://example.com/video.mp4"
                                        value={urlInput.value}
                                        onInput={(e: Event) => urlInput.value = (e.target as HTMLInputElement).value}
                                        disabled={uploading.value}
                                    />
                                    <CButton onClick={addByUrl} loading={uploading.value} icon="plus">
                                        Agregar
                                    </CButton>
                                </div>
                            </CFormRow>
                        )}

                        {/* Error */}
                        {uploadError.value && (
                            <div class="mt-4 p-3 bg-red-500/10 rounded-lg ring-1 ring-red-500/20">
                                <div class="flex items-center gap-2 text-red-400 text-sm">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <circle cx="12" cy="12" r="10" />
                                        <line x1="12" y1="8" x2="12" y2="12" />
                                        <line x1="12" y1="16" x2="12.01" y2="16" />
                                    </svg>
                                    {uploadError.value}
                                </div>
                            </div>
                        )}

                        {/* Cancel */}
                        <div class="mt-6">
                            <CButton onClick={resetForm} variant="ghost" class="text-white/60 hover:text-white">
                                Cancelar
                            </CButton>
                        </div>
                    </div>
                )}

                {/* Add Button (when sources exist) */}
                {!creating.value && videoSources.value.length > 0 && (
                    <button
                        onClick={() => creating.value = true}
                        class="w-full flex items-center justify-center gap-2 p-3 rounded-xl border-2 border-dashed border-white/10 hover:border-white/20 text-white/60 hover:text-white/80 text-sm font-medium transition-colors"
                    >
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <line x1="12" y1="5" x2="12" y2="19" />
                            <line x1="5" y1="12" x2="19" y2="12" />
                        </svg>
                        Agregar otra fuente
                    </button>
                )}
            </div>
        );
    }
});
