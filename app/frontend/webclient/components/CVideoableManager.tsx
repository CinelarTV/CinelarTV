import { defineComponent, ref, onMounted, PropType, nextTick } from 'vue';
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
        const videoSources = ref<VideoSource[]>(props.initialVideoSources && props.initialVideoSources.length > 0 ? props.initialVideoSources : []);
        const creating = ref(false);
        const sourceType = ref<'file' | 'url'>('file');
        const urlInput = ref('');
        const uppy = ref<Uppy | null>(null);
        const uploading = ref(false);
        const uploadError = ref<string | null>(null);
        const uploadProgress = ref(0);

        const getApiBase = () => {
            if (props.episodeId) return `/admin/episodes/${props.episodeId}/video_sources`;
            if (props.contentId) return `/admin/contents/${props.contentId}/video_sources`;
            return '';
        };

        const fetchVideoSources = async () => {
            const url = getApiBase();
            if (!url) return;
            const res = await fetch(url);
            const data = await res.json();
            videoSources.value = Array.isArray(data) ? data : (data.video_sources || []);
        };

        const addByUrl = async () => {
            if (!urlInput.value) return;
            uploading.value = true;
            uploadError.value = null;
            try {
                const url = getApiBase();
                if (!url) return;
                const res = await ajax.post(url, {
                    video_source: { url: urlInput.value, quality: '720p', format: 'mp4', storage_location: 'local' }
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
            const url = `/admin/video_sources/${id}`;
            await ajax(url, { method: 'DELETE' });
            await fetchVideoSources();
        };

        // Uppy setup
        const uppyDashboard = ref<HTMLDivElement | null>(null);
        onMounted(() => {
            nextTick(() => {
                const endpoint = getApiBase();
                uppy.value = new Uppy({
                    restrictions: { maxNumberOfFiles: 1, allowedFileTypes: ['video/*'] },
                    autoProceed: true,
                })
                    .use(Dashboard, {
                        inline: true,
                        target: uppyDashboard.value,
                        showProgressDetails: true,
                        proudlyDisplayPoweredByUppy: false,
                        height: 250,
                    })
                    .use(XHRUpload, {
                        endpoint,
                        fieldName: 'video_source[file]',
                        formData: true,
                        headers: {},
                    });
                uppy.value.on('upload', () => {
                    uploading.value = true;
                    uploadError.value = null;
                });
                uppy.value.on('upload-progress', (file, progress) => {
                    uploadProgress.value = progress.bytesUploaded / progress.bytesTotal * 100;
                });
                uppy.value.on('complete', async (result) => {
                    uploading.value = false;
                    if (result.failed.length > 0) {
                        uploadError.value = 'Error al subir el archivo';
                    } else {
                        creating.value = false;
                        await fetchVideoSources();
                    }
                });
                uppy.value.on('error', (err) => {
                    uploadError.value = err.message || 'Error desconocido';
                    uploading.value = false;
                });
            });
        });

        return () => (
            <div class="videoable-manager">
                {(videoSources.value.length === 0) && (
                    <div class="video-sources-empty">
                        <span class="icon-frown" style="font-size:48px" />
                        <p>Parece que no hay fuentes de video para este contenido.</p>
                    </div>
                )}
                <div class="video-sources-list">
                    {videoSources.value.length > 0 && videoSources.value.map((vs) => (
                        <div class="video-source-item flex items-center gap-2 bg-[#23232a] rounded p-2 mb-2" key={vs.id}>
                            <span class="font-mono text-xs">{vs.quality} {vs.format}</span>
                            <span class="truncate text-xs text-gray-400">{vs.url}</span>
                            <CButton icon="trash" class="ml-auto" onClick={() => removeVideoSource(vs.id!)} />
                        </div>
                    ))}
                </div>
                {creating.value ? (
                    <div class="videoable-create mt-4">
                        <h3 class="videoable-create-title mb-2">Agregar fuente de video</h3>
                        <div class="flex gap-4 mb-2">
                            <label><input type="radio" value="file" checked={sourceType.value === 'file'} onChange={() => sourceType.value = 'file'} /> Archivo</label>
                            <label><input type="radio" value="url" checked={sourceType.value === 'url'} onChange={() => sourceType.value = 'url'} /> URL</label>
                        </div>
                        {sourceType.value === 'file' && (
                            <div ref={uppyDashboard} class="uppy-dashboard mb-2" />
                        )}
                        {sourceType.value === 'url' && (
                            <div class="flex gap-2 mb-2">
                                <input type="text" class="input input-bordered w-full" placeholder="URL del video" value={urlInput.value} onInput={e => urlInput.value = (e.target as HTMLInputElement).value} />
                                <CButton onClick={addByUrl} loading={uploading.value} icon="plus">Agregar</CButton>
                            </div>
                        )}
                        {uploadError.value && <div class="text-red-500 text-xs mb-2">{uploadError.value}</div>}
                        <div class="flex gap-2 mt-2">
                            <CButton onClick={() => { creating.value = false; }} icon="x">Cancelar</CButton>
                        </div>
                    </div>
                ) : (
                    <footer class="video-sources-footer mt-4">
                        <CButton onClick={() => { creating.value = true; }} icon="plus">Agregar fuente de video</CButton>
                    </footer>
                )}
            </div>
        );
    }
});
