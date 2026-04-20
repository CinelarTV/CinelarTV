import { defineComponent, ref, onMounted, PropType, nextTick, watch } from 'vue';
import CButton from './forms/c-button';
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
                const url = `/admin/video_sources/${id}`;
                await ajax(url, { method: 'DELETE' });
                await fetchVideoSources();
            } catch (error) {
                console.error('Error removing video source:', error);
            }
        };

        // Custom file upload
        const fileInput = ref<HTMLInputElement | null>(null);
        const selectedFile = ref<File | null>(null);
        const isDragOver = ref(false);

        const triggerFileInput = () => {
            fileInput.value?.click();
        };

        const handleFileChange = (event: Event) => {
            const target = event.target as HTMLInputElement;
            const file = target.files?.[0];
            if (file) {
                selectedFile.value = file;
            }
        };

        const handleDragOver = () => {
            isDragOver.value = true;
        };

        const handleDragLeave = () => {
            isDragOver.value = false;
        };

        const handleDrop = (event: DragEvent) => {
            isDragOver.value = false;
            const files = event.dataTransfer?.files;
            if (files && files.length > 0) {
                const file = files[0];
                if (file.type.startsWith('video/')) {
                    selectedFile.value = file;
                }
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
                xhr.send(formData);
            } catch (error) {
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

        const truncateUrl = (url: string | undefined, maxLength: number = 50) => {
            if (!url) return 'Sin URL';
            if (url.length <= maxLength) return url;
            return url.substring(0, maxLength) + '...';
        };

        const getQualityBadgeColor = (quality?: string) => {
            switch (quality) {
                case '1080p': case 'HD': return 'bg-green-500';
                case '720p': return 'bg-blue-500';
                case '480p': return 'bg-yellow-500';
                default: return 'bg-gray-500';
            }
        };

        onMounted(async () => {
            await fetchVideoSources();
        });

        return () => (
            <div class="videoable-manager space-y-6">
                {/* Header */}
                <div class="flex items-center justify-between">
                    <h2 class="text-xl font-semibold text-[var(--c-body-text-color)]">
                        Fuentes de Video
                        <span class="ml-2 text-sm text-[var(--c-primary-900)]">
                            ({videoSources.value.length})
                        </span>
                    </h2>
                </div>

                {/* Empty State */}
                {videoSources.value.length === 0 && !creating.value && (
                    <div class="text-center py-12 bg-[rgba(255,255,255,0.02)] rounded-xl border border-[rgba(255,255,255,0.12)]">
                        <div class="w-16 h-16 mx-auto mb-4 bg-[rgba(255,255,255,0.05)] rounded-full flex items-center justify-center">
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-[var(--c-primary-900)]">
                                <path d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                            </svg>
                        </div>
                        <h3 class="text-lg font-medium text-[var(--c-body-text-color)] mb-2">
                            No hay fuentes de video
                        </h3>
                        <p class="text-[var(--c-primary-900)] mb-6">
                            Agrega tu primera fuente de video para comenzar
                        </p>
                        <CButton
                            onClick={() => creating.value = true}
                            icon="plus"
                        >
                            Agregar fuente de video
                        </CButton>
                    </div>
                )}

                {/* Video Sources List */}
                {videoSources.value.length > 0 && (
                    <div class="space-y-3">
                        <h3 class="text-sm font-medium text-[var(--c-primary-900)] uppercase tracking-wider">
                            Fuentes disponibles
                        </h3>
                        <div class="space-y-3">
                            {videoSources.value.map((vs) => (
                                <div key={vs.id} class="bg-[var(--c-primary-100)] rounded-xl p-6 ring-1 ring-[var(--c-primary-200)]">
                                    <div class="flex items-center justify-between">
                                        <div class="flex items-center gap-4 flex-1 min-w-0">
                                            {/* Quality Badge */}
                                            <div class={`px-3 py-1.5 rounded-lg text-xs font-semibold text-white ${getQualityBadgeColor(vs.quality)}`}>
                                                {vs.quality || 'Unknown'}
                                            </div>

                                            {/* Format */}
                                            <span class="text-xs text-[var(--c-primary-900)] font-mono uppercase bg-[var(--c-primary-200)] px-2 py-1 rounded">
                                                {vs.format || 'N/A'}
                                            </span>

                                            {/* URL/File Info */}
                                            <div class="flex-1 min-w-0 overflow-hidden">
                                                <div class="flex items-center gap-3 min-w-0">
                                                    <div class="flex-shrink-0 w-8 h-8 bg-[var(--c-primary-200)] rounded-lg flex items-center justify-center">
                                                        <span class="text-sm">
                                                            {vs.storage_location === 'url' ? '🌐' : '📁'}
                                                        </span>
                                                    </div>
                                                    <div class="flex-1 min-w-0">
                                                        <p class="text-sm text-[var(--c-body-text-color)] font-medium truncate" title={vs.url}>
                                                            {truncateUrl(vs.url)}
                                                        </p>
                                                        <p class="text-xs text-[var(--c-primary-900)] mt-0.5">
                                                            {vs.storage_location === 'url' ? 'URL externa' : 'Archivo local'}
                                                        </p>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Status & Actions */}
                                        <div class="flex items-center gap-3 flex-shrink-0">
                                            {vs.status && (
                                                <span class={`px-3 py-1.5 rounded-full text-xs font-medium ${vs.status === 'active' ? 'bg-green-900/50 text-green-300' :
                                                    vs.status === 'processing' ? 'bg-yellow-900/50 text-yellow-300' : 'bg-red-900/50 text-red-300'}`}>
                                                    {vs.status}
                                                </span>
                                            )}
                                            <CButton
                                                icon="trash"
                                                class="text-red-400 hover:text-red-300 hover:bg-red-900/20 transition-colors"
                                                onClick={() => removeVideoSource(vs.id!)}
                                            />
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}

                {creating.value && (
                    <div class="bg-[rgba(255,255,255,0.02)] rounded-xl border border-[rgba(255,255,255,0.12)] p-6">
                        <div class="flex items-center gap-2 mb-6">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-[var(--c-primary-300)]">
                                <path d="M12 5v14m-7-7h14" />
                            </svg>
                            <h3 class="text-lg font-semibold text-[var(--c-body-text-color)]">
                                Agregar fuente de video
                            </h3>
                        </div>

                        <div class="flex gap-4 mb-6">
                            <label class="flex items-center gap-2 cursor-pointer">
                                <input type="radio" value="file" checked={sourceType.value === 'file'} onChange={() => sourceType.value = 'file'} class="text-[var(--c-primary-300)] focus:ring-[var(--c-primary-300)]" />
                                <span class="text-[var(--c-body-text-color)]">📁 Subir archivo</span>
                            </label>
                            <label class="flex items-center gap-2 cursor-pointer">
                                <input type="radio" value="url" checked={sourceType.value === 'url'} onChange={() => sourceType.value = 'url'} class="text-[var(--c-primary-300)] focus:ring-[var(--c-primary-300)]" />
                                <span class="text-[var(--c-body-text-color)]">🌐 URL externa</span>
                            </label>
                        </div>

                        {sourceType.value === 'file' && (
                            <div class="mb-6">
                                <input ref={fileInput} type="file" accept="video/*" onChange={handleFileChange} class="hidden" />
                                {!selectedFile.value ? (
                                    <div class={`video-upload-area ${isDragOver.value ? 'drag-over' : ''}`} onClick={triggerFileInput} onDragover={handleDragOver} onDragleave={handleDragLeave} onDrop={handleDrop}>
                                        <div class="upload-content">
                                            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" class="text-[var(--c-primary-300)]">
                                                <path d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                                            </svg>
                                            <p class="text-[var(--c-body-text-color)] font-medium">Arrastra un video aquí</p>
                                            <p class="text-[var(--c-primary-900)]">o haz clic para seleccionar</p>
                                            <p class="text-xs text-[var(--c-primary-900)] mt-2">Formatos: MP4, AVI, MOV, MKV • Máx: 500MB</p>
                                        </div>
                                    </div>
                                ) : (
                                    <div class="selected-file bg-[rgba(255,255,255,0.02)] rounded-lg p-4 border border-[rgba(255,255,255,0.12)]">
                                        <div class="flex items-center justify-between">
                                            <div class="flex items-center gap-3">
                                                <div class="w-10 h-10 bg-[var(--c-primary-300)]/20 rounded-full flex items-center justify-center">
                                                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-[var(--c-primary-300)]">
                                                        <path d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                                                    </svg>
                                                </div>
                                                <div>
                                                    <p class="text-[var(--c-body-text-color)] font-medium">{selectedFile.value.name}</p>
                                                    <p class="text-xs text-[var(--c-primary-900)]">{formatFileSize(selectedFile.value.size)}</p>
                                                </div>
                                            </div>
                                            <CButton icon="trash" class="text-red-400 hover:text-red-300 hover:bg-red-900/20" onClick={() => selectedFile.value = null} />
                                        </div>
                                    </div>
                                )}
                                {uploadProgress.value > 0 && uploadProgress.value < 100 && (
                                    <div class="mt-4">
                                        <div class="flex justify-between text-sm text-[var(--c-primary-900)] mb-2">
                                            <span>Subiendo...</span>
                                            <span>{uploadProgress.value}%</span>
                                        </div>
                                        <div class="w-full bg-[rgba(255,255,255,0.1)] rounded-full h-2">
                                            <div class="bg-[var(--c-primary-300)] h-2 rounded-full transition-all duration-300" style={{ width: `${uploadProgress.value}%` }} />
                                        </div>
                                    </div>
                                )}
                                {selectedFile.value && !uploading.value && (
                                    <div class="mt-4">
                                        <CButton onClick={uploadFile} loading={uploading.value} icon="upload">
                                            Subir video
                                        </CButton>
                                    </div>
                                )}
                            </div>
                        )}

                        {sourceType.value === 'url' && (
                            <div class="mb-6">
                                <label class="block text-sm font-medium text-[var(--c-body-text-color)] mb-2">
                                    URL del video
                                </label>
                                <div class="flex gap-3">
                                    <input type="url" class="c-input flex-1" placeholder="https://example.com/video.mp4" value={urlInput.value} onInput={e => urlInput.value = (e.target as HTMLInputElement).value} disabled={uploading.value} />
                                    <CButton onClick={addByUrl} loading={uploading.value} icon="plus">
                                        Agregar
                                    </CButton>
                                </div>
                            </div>
                        )}

                        {uploadError.value && (
                            <div class="mb-6 p-4 bg-red-900/20 border border-red-700/50 rounded-lg">
                                <div class="flex items-center gap-2 text-red-400">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <circle cx="12" cy="12" r="10" />
                                        <line x1="12" y1="8" x2="12" y2="12" />
                                        <line x1="12" y1="16" x2="12.01" y2="16" />
                                    </svg>
                                    <span class="text-sm">{uploadError.value}</span>
                                </div>
                            </div>
                        )}

                        <div class="flex gap-3">
                            <CButton onClick={() => { creating.value = false; uploadError.value = null; selectedFile.value = null; urlInput.value = ''; }} variant="ghost" class="text-[var(--c-primary-900)] hover:text-[var(--c-body-text-color)]">
                                Cancelar
                            </CButton>
                        </div>
                    </div>
                )}

                {!creating.value && videoSources.value.length > 0 && (
                    <div class="text-center">
                        <CButton onClick={() => creating.value = true} icon="plus">
                            Agregar otra fuente
                        </CButton>
                    </div>
                )}
            </div>
        );
    }
});