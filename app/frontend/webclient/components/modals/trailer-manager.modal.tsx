import { ref, computed, defineComponent, watch } from 'vue';
import {
    TransitionRoot,
    TransitionChild,
    Dialog,
    DialogPanel,
    DialogTitle,
} from '@headlessui/vue';
import { ajax } from '../../lib/Ajax';
import CButton from '../forms/c-button';
import CInput from '../forms/c-input.vue';

interface TrailerSource {
    id: number | string;
    url: string;
    quality?: string;
    format?: string;
    storage_location?: string;
}

export default defineComponent({
    name: 'TrailerManagerModal',

    props: {
        contentId: {
            type: String,
            required: true,
        },
    },

    emits: ['updated'],

    setup(props, { expose, emit }) {
        const isOpen = ref(false);
        const trailerSources = ref<TrailerSource[]>([]);
        const loading = ref(false);
        const sourceType = ref<'file' | 'url'>('file');
        const urlInput = ref('');
        const selectedFile = ref<File | null>(null);
        const uploading = ref(false);
        const uploadProgress = ref(0);
        const uploadError = ref('');
        const fileInput = ref<HTMLInputElement | null>(null);
        const isDragOver = ref(false);

        const setIsOpen = (value: boolean) => {
            isOpen.value = value;
            if (value) {
                fetchTrailerSources();
            } else {
                resetForm();
            }
        };

        const resetForm = () => {
            sourceType.value = 'file';
            urlInput.value = '';
            selectedFile.value = null;
            uploading.value = false;
            uploadProgress.value = 0;
            uploadError.value = '';
            isDragOver.value = false;
        };

        const getApiBase = () => {
            return `/admin/contents/${props.contentId}/video_sources`;
        };

        const fetchTrailerSources = async () => {
            loading.value = true;
            try {
                const res = await ajax.get(`${getApiBase()}?trailer=true`);
                trailerSources.value = Array.isArray(res.data) ? res.data : [];
            } catch (error) {
                console.error('Error fetching trailer sources:', error);
                trailerSources.value = [];
            } finally {
                loading.value = false;
            }
        };

        const detectFormat = (url: string): string => {
            if (url.match(/\.m3u8/i)) return 'm3u8';
            if (url.match(/\.webm/i)) return 'mp4';
            return 'mp4';
        };

        const addByUrl = async () => {
            if (!urlInput.value.trim()) return;
            uploading.value = true;
            uploadError.value = '';

            try {
                const detectedFormat = detectFormat(urlInput.value.trim());
                const res = await ajax.post(getApiBase(), {
                    video_source: {
                        url: urlInput.value.trim(),
                        quality: '720p',
                        format: detectedFormat,
                        storage_location: 'external_url',
                        trailer: true,
                    },
                });

                urlInput.value = '';
                await fetchTrailerSources();
                emit('updated');
            } catch (e: any) {
                uploadError.value = e.response?.data?.error || e.message || 'Error adding URL';
            } finally {
                uploading.value = false;
            }
        };

        const removeSource = async (id: number | string) => {
            if (!confirm('Remove this trailer source?')) return;
            try {
                await ajax(`/admin/video_sources/${id}`, { method: 'DELETE' });
                await fetchTrailerSources();
                emit('updated');
            } catch (error) {
                console.error('Error removing trailer source:', error);
            }
        };

        const triggerFileInput = () => fileInput.value?.click();

        const handleFileChange = (event: Event) => {
            const file = (event.target as HTMLInputElement).files?.[0];
            if (file) selectedFile.value = file;
        };

        const handleDragOver = (e: DragEvent) => {
            e.preventDefault();
            isDragOver.value = true;
        };

        const handleDragLeave = () => {
            isDragOver.value = false;
        };

        const handleDrop = (event: DragEvent) => {
            event.preventDefault();
            isDragOver.value = false;
            const file = event.dataTransfer?.files[0];
            if (file?.type.startsWith('video/')) {
                selectedFile.value = file;
            }
        };

        const uploadFile = async () => {
            if (!selectedFile.value) return;
            uploading.value = true;
            uploadError.value = '';
            uploadProgress.value = 0;

            try {
                const formData = new FormData();
                formData.append('video_source[file]', selectedFile.value);
                formData.append('video_source[trailer]', 'true');

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
                    fetchTrailerSources();
                    emit('updated');
                });

                xhr.addEventListener('error', () => {
                    uploadError.value = 'Error uploading file';
                    uploading.value = false;
                    uploadProgress.value = 0;
                });

                xhr.open('POST', getApiBase());
                xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
                const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
                if (csrfToken) xhr.setRequestHeader('X-CSRF-Token', csrfToken);
                xhr.send(formData);
            } catch {
                uploadError.value = 'Error uploading file';
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

        expose({ setIsOpen });

        return () => (
            <>
                <TransitionRoot appear show={isOpen.value} as="template">
                    <Dialog as="div" onClose={() => setIsOpen(false)} class="relative z-100">
                        <TransitionChild
                            as="template"
                            enter="duration-300 ease-out"
                            enterFrom="opacity-0"
                            enterTo="opacity-100"
                            leave="duration-200 ease-in"
                            leaveFrom="opacity-100"
                            leaveTo="opacity-0"
                        >
                            <div class="fixed inset-0 bg-black/60 backdrop-blur-sm" />
                        </TransitionChild>

                        <div class="fixed inset-0 flex items-center justify-center p-4">
                            <TransitionChild
                                as="template"
                                enter="duration-300 ease-out"
                                enterFrom="opacity-0 scale-95 translate-y-2"
                                enterTo="opacity-100 scale-100 translate-y-0"
                                leave="duration-200 ease-in"
                                leaveFrom="opacity-100 scale-100 translate-y-0"
                                leaveTo="opacity-0 scale-95 translate-y-2"
                            >
                                <DialogPanel class="w-full max-w-lg rounded-2xl overflow-hidden shadow-2xl ring-1 ring-[var(--c-primary-400)] bg-[var(--c-primary-600)]">
                                    <div class="bg-[var(--c-primary-color)] px-8 pt-8 pb-6 text-center border-b border-[var(--c-primary-400)]">
                                        <DialogTitle as="h2" class="text-xl font-semibold tracking-tight text-[var(--c-body-text-color)]">
                                            Manage Trailer
                                        </DialogTitle>
                                        <p class="mt-1 text-sm text-[var(--c-body-text-color)]">
                                            Upload a video file or add an external URL
                                        </p>
                                    </div>

                                    <div class="px-8 py-6 space-y-6">
                                        {loading.value ? (
                                            <div class="flex items-center justify-center py-8">
                                                <div class="animate-spin rounded-full h-8 w-8 border-2 border-white/30 border-t-[#00A8E1]"></div>
                                            </div>
                                        ) : (
                                            <>
                                                {trailerSources.value.length > 0 && (
                                                    <div>
                                                        <label class="block text-xs font-medium uppercase tracking-widest text-[var(--c-body-text-color)] mb-2">
                                                            Current Trailer
                                                        </label>
                                                        <div class="space-y-2">
                                                            {trailerSources.value.map((vs) => (
                                                                <div key={vs.id} class="flex items-center justify-between bg-white/5 rounded-lg px-4 py-3 ring-1 ring-white/10">
                                                                    <div class="flex items-center gap-3 min-w-0">
                                                                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0 text-white/40">
                                                                            <polygon points="5 3 19 12 5 21 5 3" />
                                                                        </svg>
                                                                        <div class="min-w-0">
                                                                            <p class="text-sm text-white truncate">{vs.url}</p>
                                                                            <p class="text-xs text-white/40">
                                                                                {(vs.format?.toUpperCase() || 'MP4')} · {vs.quality || 'N/A'} · {vs.storage_location || 'local'}
                                                                            </p>
                                                                        </div>
                                                                    </div>
                                                                    <button
                                                                        onClick={() => removeSource(vs.id)}
                                                                        class="shrink-0 p-1.5 rounded-lg text-red-400 hover:bg-red-500/20 transition-colors"
                                                                        title="Remove"
                                                                    >
                                                                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                                            <polyline points="3 6 5 6 21 6" />
                                                                            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                                                                        </svg>
                                                                    </button>
                                                                </div>
                                                            ))}
                                                        </div>
                                                    </div>
                                                )}

                                                <div>
                                                    <label class="block text-xs font-medium uppercase tracking-widest text-[var(--c-body-text-color)] mb-3">
                                                        {trailerSources.value.length > 0 ? 'Replace with' : 'Add Trailer'}
                                                    </label>

                                                    <div class="flex rounded-lg overflow-hidden ring-1 ring-white/10 mb-4">
                                                        <button
                                                            onClick={() => { sourceType.value = 'file'; uploadError.value = ''; }}
                                                            class={[
                                                                'flex-1 px-4 py-2 text-sm font-medium transition-colors',
                                                                sourceType.value === 'file'
                                                                    ? 'bg-[#00A8E1] text-white'
                                                                    : 'bg-white/5 text-white/60 hover:bg-white/10',
                                                            ]}
                                                        >
                                                            Upload Video
                                                        </button>
                                                        <button
                                                            onClick={() => { sourceType.value = 'url'; uploadError.value = ''; }}
                                                            class={[
                                                                'flex-1 px-4 py-2 text-sm font-medium transition-colors',
                                                                sourceType.value === 'url'
                                                                    ? 'bg-[#00A8E1] text-white'
                                                                    : 'bg-white/5 text-white/60 hover:bg-white/10',
                                                            ]}
                                                        >
                                                            External URL
                                                        </button>
                                                    </div>

                                                    {sourceType.value === 'file' ? (
                                                        <div class="space-y-3">
                                                            {!selectedFile.value ? (
                                                                <div
                                                                    onDragover={(e: DragEvent) => { e.preventDefault(); isDragOver.value = true; }}
                                                                    onDragleave={() => { isDragOver.value = false; }}
                                                                    onDrop={handleDrop}
                                                                    onClick={triggerFileInput}
                                                                    class={[
                                                                        'border-2 border-dashed rounded-xl p-8 text-center cursor-pointer transition-colors',
                                                                        isDragOver.value
                                                                            ? 'border-[#00A8E1] bg-[#00A8E1]/10'
                                                                            : 'border-white/20 hover:border-white/40',
                                                                    ]}
                                                                >
                                                                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="mx-auto mb-3 text-white/40">
                                                                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                                                                        <polyline points="17 8 12 3 7 8" />
                                                                        <line x1="12" y1="3" x2="12" y2="15" />
                                                                    </svg>
                                                                    <p class="text-sm text-white/60">
                                                                        Drop a video file here or click to browse
                                                                    </p>
                                                                    <input
                                                                        ref={fileInput}
                                                                        type="file"
                                                                        accept="video/*"
                                                                        onChange={handleFileChange}
                                                                        class="hidden"
                                                                    />
                                                                </div>
                                                            ) : (
                                                                <div class="bg-white/5 rounded-lg p-4 ring-1 ring-white/10">
                                                                    <div class="flex items-center justify-between mb-2">
                                                                        <div class="flex items-center gap-2 min-w-0">
                                                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0 text-white/40">
                                                                                <polygon points="5 3 19 12 5 21 5 3" />
                                                                            </svg>
                                                                            <span class="text-sm text-white truncate">{selectedFile.value.name}</span>
                                                                        </div>
                                                                        <button
                                                                            onClick={() => { selectedFile.value = null; }}
                                                                            class="text-xs text-white/40 hover:text-white/60"
                                                                        >
                                                                            Change
                                                                        </button>
                                                                    </div>
                                                                    <p class="text-xs text-white/40 mb-3">
                                                                        {formatFileSize(selectedFile.value.size)}
                                                                    </p>
                                                                    {uploading.value ? (
                                                                        <div>
                                                                            <div class="h-1.5 rounded-full bg-white/10 overflow-hidden">
                                                                                <div
                                                                                    class="h-full rounded-full bg-[#00A8E1] transition-all duration-300"
                                                                                    style={{ width: `${uploadProgress.value}%` }}
                                                                                />
                                                                            </div>
                                                                            <p class="text-xs text-white/40 mt-1">{uploadProgress.value}%</p>
                                                                        </div>
                                                                    ) : (
                                                                        <CButton onClick={uploadFile} class="w-full justify-center">
                                                                            Upload Trailer
                                                                        </CButton>
                                                                    )}
                                                                </div>
                                                            )}
                                                        </div>
                                                    ) : (
                                                        <div class="flex gap-2">
                                                            <CInput
                                                                modelValue={urlInput.value}
                                                                onUpdate:modelValue={(v: string) => { urlInput.value = v; uploadError.value = ''; }}
                                                                placeholder="https://example.com/trailer.mp4"
                                                                class="flex-1"
                                                            />
                                                            <CButton onClick={addByUrl} loading={uploading.value}>
                                                                Add URL
                                                            </CButton>
                                                        </div>
                                                    )}

                                                    {uploadError.value && (
                                                        <p class="mt-2 text-xs font-medium text-rose-400">{uploadError.value}</p>
                                                    )}
                                                </div>
                                            </>
                                        )}
                                    </div>

                                    <div class="px-8 py-4 bg-white/5 border-t border-[var(--c-primary-400)] flex justify-end">
                                        <CButton onClick={() => setIsOpen(false)} variant="ghost">
                                            Close
                                        </CButton>
                                    </div>
                                </DialogPanel>
                            </TransitionChild>
                        </div>
                    </Dialog>
                </TransitionRoot>
            </>
        );
    },
});
