import { defineComponent, ref, onMounted, PropType, nextTick, watch } from 'vue';
import { Uppy } from '@uppy/core';
import Dashboard from '@uppy/dashboard';
import XHRUpload from '@uppy/xhr-upload';
import '@uppy/core/dist/style.css';
import '@uppy/dashboard/dist/style.css';
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

        // Uppy setup
        const uppyDashboard = ref<HTMLDivElement | null>(null);
        const uppyInstance = ref<Uppy | null>(null);

        const setupUppy = () => {
            if (!uppyDashboard.value) return;

            // Cleanup existing instance
            if (uppyInstance.value) {
                uppyInstance.value.destroy();
                uppyInstance.value = null;
            }

            const endpoint = getApiBase();
            if (!endpoint) return;

            const instance = new Uppy({
                restrictions: {
                    maxNumberOfFiles: 1,
                    allowedFileTypes: ['video/*'],
                    maxFileSize: 500 * 1024 * 1024 // 500MB
                },
                autoProceed: false,
                locale: {
                    strings: {
                        dropHereOr: 'Arrastra tu video aquí o %{browse}',
                        browse: 'selecciona',
                        uploadComplete: 'Carga completada',
                        uploadFailed: 'Carga fallida',
                        retry: 'Reintentar',
                        cancel: 'Cancelar'
                    }
                }
            })
                .use(Dashboard, {
                    inline: true,
                    target: uppyDashboard.value,
                    showProgressDetails: true,
                    proudlyDisplayPoweredByUppy: false,
                    height: 350,
                    theme: 'dark',
                    fileManagerSelectionType: 'files',
                    note: 'Sube videos de hasta 500MB. Formatos soportados: MP4, AVI, MOV, MKV'
                })
                .use(XHRUpload, {
                    endpoint,
                    fieldName: 'video_source[file]',
                    formData: true,
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest',
                    },
                });

            // Event handlers
            instance.on('upload', () => {
                uploading.value = true;
                uploadError.value = null;
                uploadProgress.value = 0;
            });

            instance.on('upload-progress', (file, progress) => {
                uploadProgress.value = Math.round((progress.bytesUploaded / progress.bytesTotal) * 100);
            });

            instance.on('complete', async (result) => {
                uploading.value = false;
                uploadProgress.value = 0;

                if (result.failed.length > 0) {
                    uploadError.value = result.failed[0]?.error?.message || 'Error al subir el archivo';
                } else {
                    creating.value = false;
                    await fetchVideoSources();
                    instance.reset();
                }
            });

            instance.on('upload-error', (file, error) => {
                uploadError.value = error.message || 'Error al subir el archivo';
                uploading.value = false;
                uploadProgress.value = 0;
            });

            uppyInstance.value = instance;
        };

        const formatFileSize = (bytes: number) => {
            if (bytes === 0) return '0 Bytes';
            const k = 1024;
            const sizes = ['Bytes', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
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

            nextTick(() => {
                if (sourceType.value === 'file' && uppyDashboard.value) {
                    setupUppy();
                }
            });
        });

        watch(sourceType, (newType) => {
            nextTick(() => {
                if (newType === 'file' && uppyDashboard.value) {
                    setupUppy();
                } else if (uppyInstance.value) {
                    uppyInstance.value.destroy();
                    uppyInstance.value = null;
                }
            });
        });

        return () => (
            <div class="videoable-manager space-y-6">
                {/* Header */}
                <div class="flex items-center justify-between">
                    <h2 class="text-xl font-semibold text-gray-100">
                        Fuentes de Video
                        <span class="ml-2 text-sm text-gray-400">
                            ({videoSources.value.length})
                        </span>
                    </h2>
                </div>

                {/* Empty State */}
                {videoSources.value.length === 0 && !creating.value && (
                    <div class="text-center py-12 bg-gray-800/30 rounded-xl border border-gray-700/50">
                        <div class="w-16 h-16 mx-auto mb-4 bg-gray-700/50 rounded-full flex items-center justify-center">
                            <span class="icon-video text-2xl text-gray-400" />
                        </div>
                        <h3 class="text-lg font-medium text-gray-300 mb-2">
                            No hay fuentes de video
                        </h3>
                        <p class="text-gray-500 mb-6">
                            Agrega tu primera fuente de video para comenzar
                        </p>
                        <CButton
                            onClick={() => creating.value = true}
                            icon="plus"
                            class="bg-blue-600 hover:bg-blue-700"
                        >
                            Agregar fuente de video
                        </CButton>
                    </div>
                )}

                {/* Video Sources List */}
                {videoSources.value.length > 0 && (
                    <div class="space-y-3">
                        <h3 class="text-sm font-medium text-gray-400 uppercase tracking-wider">
                            Fuentes disponibles
                        </h3>
                        {videoSources.value.map((vs) => (
                            <div
                                key={vs.id}
                                class="group bg-gray-800/50 hover:bg-gray-800/70 rounded-xl p-4 border border-gray-700/50 hover:border-gray-600/50 transition-all duration-200"
                            >
                                <div class="flex items-center gap-4">
                                    {/* Quality Badge */}
                                    <div class={`px-2 py-1 rounded text-xs font-medium text-white ${getQualityBadgeColor(vs.quality)}`}>
                                        {vs.quality || 'Unknown'}
                                    </div>

                                    {/* Format */}
                                    <span class="text-xs text-gray-400 font-mono uppercase">
                                        {vs.format || 'N/A'}
                                    </span>

                                    {/* URL/File Info */}
                                    <div class="flex-1 min-w-0 overflow-hidden">
                                        <div class="flex items-center gap-2 min-w-0">
                                            <span class="flex-shrink-0">
                                                {vs.storage_location === 'url' ? '🌐' : '📁'}
                                            </span>
                                            <span class="text-sm text-gray-300 truncate min-w-0 flex-1" title={vs.url}>
                                                {vs.url || 'Sin URL'}
                                            </span>
                                        </div>
                                    </div>

                                    {/* Status */}
                                    {vs.status && (
                                        <span class={`px-2 py-1 rounded-full text-xs ${vs.status === 'active' ? 'bg-green-900 text-green-300' :
                                            vs.status === 'processing' ? 'bg-yellow-900 text-yellow-300' :
                                                'bg-red-900 text-red-300'
                                            }`}>
                                            {vs.status}
                                        </span>
                                    )}

                                    {/* Actions */}
                                    <CButton
                                        icon="trash"
                                        size="sm"
                                        variant="ghost"
                                        class="opacity-0 group-hover:opacity-100 transition-opacity text-red-400 hover:text-red-300 hover:bg-red-900/20"
                                        onClick={() => removeVideoSource(vs.id!)}
                                        title="Eliminar fuente"
                                    />
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {/* Add New Source */}
                {creating.value ? (
                    <div class="bg-gray-800/30 rounded-xl border border-gray-700/50 p-6">
                        <div class="flex items-center gap-2 mb-6">
                            <span class="icon-plus text-blue-400" />
                            <h3 class="text-lg font-semibold text-gray-100">
                                Agregar fuente de video
                            </h3>
                        </div>

                        {/* Source Type Selection */}
                        <div class="flex gap-4 mb-6">
                            <label class="flex items-center gap-2 cursor-pointer">
                                <input
                                    type="radio"
                                    value="file"
                                    checked={sourceType.value === 'file'}
                                    onChange={() => sourceType.value = 'file'}
                                    class="text-blue-600 focus:ring-blue-500"
                                />
                                <span class="text-gray-300">📁 Subir archivo</span>
                            </label>
                            <label class="flex items-center gap-2 cursor-pointer">
                                <input
                                    type="radio"
                                    value="url"
                                    checked={sourceType.value === 'url'}
                                    onChange={() => sourceType.value = 'url'}
                                    class="text-blue-600 focus:ring-blue-500"
                                />
                                <span class="text-gray-300">🌐 URL externa</span>
                            </label>
                        </div>

                        {/* File Upload */}
                        {sourceType.value === 'file' && (
                            <div class="mb-6">
                                <div
                                    ref={uppyDashboard}
                                    class="uppy-dashboard-container rounded-lg overflow-hidden border border-gray-600/50"
                                />
                                {uploadProgress.value > 0 && uploadProgress.value < 100 && (
                                    <div class="mt-4">
                                        <div class="flex justify-between text-sm text-gray-400 mb-2">
                                            <span>Subiendo...</span>
                                            <span>{uploadProgress.value}%</span>
                                        </div>
                                        <div class="w-full bg-gray-700 rounded-full h-2">
                                            <div
                                                class="bg-blue-600 h-2 rounded-full transition-all duration-300"
                                                style={{ width: `${uploadProgress.value}%` }}
                                            />
                                        </div>
                                    </div>
                                )}
                            </div>
                        )}

                        {/* URL Input */}
                        {sourceType.value === 'url' && (
                            <div class="mb-6">
                                <label class="block text-sm font-medium text-gray-300 mb-2">
                                    URL del video
                                </label>
                                <div class="flex gap-3">
                                    <input
                                        type="url"
                                        class="flex-1 bg-gray-700/50 border border-gray-600/50 rounded-lg px-4 py-3 text-gray-100 placeholder-gray-400 focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors"
                                        placeholder="https://example.com/video.mp4"
                                        value={urlInput.value}
                                        onInput={e => urlInput.value = (e.target as HTMLInputElement).value}
                                        disabled={uploading.value}
                                    />
                                    <CButton
                                        onClick={addByUrl}
                                        loading={uploading.value}
                                        icon="plus"
                                        class="bg-blue-600 hover:bg-blue-700 px-6"
                                        disabled={!urlInput.value.trim() || uploading.value}
                                    >
                                        Agregar
                                    </CButton>
                                </div>
                            </div>
                        )}

                        {/* Error Message */}
                        {uploadError.value && (
                            <div class="mb-6 p-4 bg-red-900/20 border border-red-700/50 rounded-lg">
                                <div class="flex items-center gap-2 text-red-400">
                                    <span class="icon-alert-circle text-sm" />
                                    <span class="text-sm">{uploadError.value}</span>
                                </div>
                            </div>
                        )}

                        {/* Actions */}
                        <div class="flex gap-3">
                            <CButton
                                onClick={() => {
                                    creating.value = false;
                                    uploadError.value = null;
                                    if (uppyInstance.value) {
                                        uppyInstance.value.reset();
                                    }
                                }}
                                variant="ghost"
                                class="text-gray-400 hover:text-gray-300"
                                disabled={uploading.value}
                            >
                                Cancelar
                            </CButton>
                        </div>
                    </div>
                ) : videoSources.value.length > 0 && (
                    <div class="text-center">
                        <CButton
                            onClick={() => creating.value = true}
                            icon="plus"
                            class="bg-blue-600 hover:bg-blue-700"
                        >
                            Agregar otra fuente
                        </CButton>
                    </div>
                )}
            </div>
        );
    }
});