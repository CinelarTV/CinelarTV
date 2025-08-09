import { defineComponent, ref, onMounted, PropType } from 'vue';
import Uppy from '@uppy/core';
import Dashboard from '@uppy/dashboard';
import '@uppy/core/dist/style.min.css';
import '@uppy/dashboard/dist/style.min.css';

export default defineComponent({
    name: 'CImageUpload',
    props: {
        modelValue: File,
        label: { type: String, default: 'Selecciona una imagen' },
        accept: { type: String, default: 'image/*' },
        height: { type: Number, default: 300 },
        width: { type: [Number, String], default: '100%' },
    },
    emits: ['update:modelValue'],
    setup(props, { emit }) {
        const previewImage = ref<string | null>(null);
        const uploading = ref(false);
        const error = ref<string | null>(null);
        const uppyRef = ref<any>(null);

        const handleUppyComplete = (result: any) => {
            if (result.successful.length > 0) {
                const uploadedFile = result.successful[0];
                previewImage.value = uploadedFile.preview || URL.createObjectURL(uploadedFile.data);
                emit('update:modelValue', uploadedFile.data);
                error.value = null;
            } else {
                error.value = 'Error durante la carga de la imagen.';
            }
            uploading.value = false;
        };

        onMounted(() => {
            const uppy = new Uppy({
                autoProceed: true,
                restrictions: {
                    allowedFileTypes: [props.accept],
                },
                allowMultipleUploads: false,
            })
                .use(Dashboard, {
                    target: '#uppy-container',
                    inline: true,
                    height: props.height,
                    width: props.width,
                    showRemoveButtonAfterComplete: true,
                    proudlyDisplayPoweredByUppy: false,
                    note: 'Formatos permitidos: JPG, PNG, JPEG. Tamaño máximo: 5MB',
                });
            uppy.on('upload', () => { uploading.value = true; });
            uppy.on('complete', handleUppyComplete);
            uppyRef.value = uppy;
        });

        return () => (
            <div class="c-image-upload-tsx relative flex flex-col items-center gap-4 p-4 bg-white rounded-lg shadow-md border border-gray-200">
                <label class="block text-lg font-semibold text-gray-700 mb-2">{props.label}</label>
                <div id="uppy-container" class="w-full" style={{ minHeight: `${props.height}px` }}></div>
                {uploading.value && (
                    <div class="text-blue-600 font-medium animate-pulse">Subiendo imagen...</div>
                )}
                {error.value && (
                    <div class="text-red-500 font-medium">{error.value}</div>
                )}
                {previewImage.value && (
                    <div class="w-full flex flex-col items-center mt-2">
                        <span class="text-gray-500 text-sm mb-1">Previsualización:</span>
                        <img
                            src={previewImage.value}
                            alt="Vista previa"
                            class="rounded-lg shadow max-h-48 object-contain border border-gray-300"
                            style={{ maxWidth: '100%' }}
                        />
                    </div>
                )}
            </div>
        );
    },
});
