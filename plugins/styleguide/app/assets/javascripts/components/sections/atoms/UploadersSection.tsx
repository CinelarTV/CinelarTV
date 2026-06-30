import { defineComponent, ref } from 'vue';

export default defineComponent({
    name: 'UploadersSection',
    setup() {
        const dragOver1 = ref(false);
        const dragOver2 = ref(false);
        const file1 = ref<File | null>(null);
        const preview1 = ref<string | null>(null);
        const file2 = ref<File | null>(null);
        const preview2 = ref<string | null>(null);

        const handleDrop = (target: '1' | '2', e: DragEvent) => {
            e.preventDefault();
            if (target === '1') dragOver1.value = false;
            else dragOver2.value = false;

            const droppedFile = e.dataTransfer?.files[0];
            if (droppedFile && droppedFile.type.startsWith('image/')) {
                if (target === '1') {
                    file1.value = droppedFile;
                    preview1.value = URL.createObjectURL(droppedFile);
                } else {
                    file2.value = droppedFile;
                    preview2.value = URL.createObjectURL(droppedFile);
                }
            }
        };

        const handleFileInput = (target: '1' | '2', e: Event) => {
            const input = e.target as HTMLInputElement;
            const selectedFile = input.files?.[0];
            if (selectedFile) {
                if (target === '1') {
                    file1.value = selectedFile;
                    preview1.value = URL.createObjectURL(selectedFile);
                } else {
                    file2.value = selectedFile;
                    preview2.value = URL.createObjectURL(selectedFile);
                }
            }
            input.value = '';
        };

        const removeFile = (target: '1' | '2') => {
            if (target === '1') {
                file1.value = null;
                preview1.value = null;
            } else {
                file2.value = null;
                preview2.value = null;
            }
        };

        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Uploaders</h1>
                <p class="styleguide-section__description">
                    Componentes para carga de archivos con drag & drop y preview.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Image Upload - Empty</h2>
                    <div style={{ maxWidth: '400px' }}>
                        <div
                            class={[
                                "flex flex-col items-center justify-center p-8 rounded-lg border-2 border-dashed transition-colors cursor-pointer",
                                dragOver1.value
                                    ? "border-[var(--c-tertiary-color)] bg-[var(--c-tertiary-color)]/10"
                                    : "border-white/20 hover:border-white/40 bg-white/5",
                            ]}
                            onDragover={(e: DragEvent) => { e.preventDefault(); dragOver1.value = true; }}
                            onDragleave={() => { dragOver1.value = false; }}
                            onDrop={(e: DragEvent) => handleDrop('1', e)}
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
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Image Upload - With Preview</h2>
                    <div style={{ maxWidth: '400px' }}>
                        {preview1.value ? (
                            <div class="space-y-3">
                                <img
                                    src={preview1.value}
                                    alt="Preview"
                                    class="rounded-lg w-full max-h-48 object-contain ring-1 ring-white/10"
                                />
                                <div class="flex gap-2">
                                    <button class="flex-1 flex items-center justify-center gap-2 px-3 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-white/80 text-sm transition-colors ring-1 ring-white/10">
                                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                                            <polyline points="17 8 12 3 7 8" />
                                            <line x1="12" y1="3" x2="12" y2="15" />
                                        </svg>
                                        Cambiar
                                    </button>
                                    <button
                                        onClick={() => removeFile('1')}
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
                                    "flex flex-col items-center justify-center p-8 rounded-lg border-2 border-dashed transition-colors cursor-pointer",
                                    dragOver1.value
                                        ? "border-[var(--c-tertiary-color)] bg-[var(--c-tertiary-color)]/10"
                                        : "border-white/20 hover:border-white/40 bg-white/5",
                                ]}
                                onDragover={(e: DragEvent) => { e.preventDefault(); dragOver1.value = true; }}
                                onDragleave={() => { dragOver1.value = false; }}
                                onDrop={(e: DragEvent) => handleDrop('1', e)}
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
                            </div>
                        )}
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Landscape Upload (16:9)</h2>
                    <div style={{ maxWidth: '400px' }}>
                        {preview2.value ? (
                            <div class="space-y-3">
                                <img
                                    src={preview2.value}
                                    alt="Preview"
                                    class="rounded-lg w-full aspect-video object-cover ring-1 ring-white/10"
                                />
                                <button
                                    onClick={() => removeFile('2')}
                                    class="flex items-center justify-center gap-2 px-3 py-2 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-400 text-sm transition-colors ring-1 ring-red-500/20"
                                >
                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <polyline points="3 6 5 6 21 6" />
                                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                                    </svg>
                                    Eliminar
                                </button>
                            </div>
                        ) : (
                            <div
                                class={[
                                    "flex flex-col items-center justify-center p-6 rounded-lg border-2 border-dashed transition-colors cursor-pointer aspect-video",
                                    dragOver2.value
                                        ? "border-[var(--c-tertiary-color)] bg-[var(--c-tertiary-color)]/10"
                                        : "border-white/20 hover:border-white/40 bg-white/5",
                                ]}
                                onDragover={(e: DragEvent) => { e.preventDefault(); dragOver2.value = true; }}
                                onDragleave={() => { dragOver2.value = false; }}
                                onDrop={(e: DragEvent) => handleDrop('2', e)}
                            >
                                <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" class="text-white/40 mb-2">
                                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                                    <polyline points="17 8 12 3 7 8" />
                                    <line x1="12" y1="3" x2="12" y2="15" />
                                </svg>
                                <p class="text-white/60 text-sm font-medium">
                                    Banner 16:9
                                </p>
                                <p class="text-white/40 text-xs mt-1">
                                    Arrastra o haz clic
                                </p>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        );
    }
});
