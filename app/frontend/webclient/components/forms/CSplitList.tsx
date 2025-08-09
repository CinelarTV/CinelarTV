import { defineComponent, defineExpose, ref, computed, watch, toRef } from "vue"
import CInput from "./c-input.vue";


export default defineComponent({
    name: "CSplitList",
    props: {
        splitter: {
            type: String,
            default: ",",
            validator: (value: string) => {
                // Ensure the splitter is a single character
                return value.length === 1;
            }
        },
        items: {
            type: String,
            required: true,
            validator: (value: string) => {
                return value.trim().length > 0;
            }
        }
    },
    emits: ["update:items"],
    setup(props, { emit }) {
        const inputValue = ref("");
        const list = computed(() => props.items.split(props.splitter).map(i => i.trim()).filter(Boolean));
        const editIndex = ref<number | null>(null);
        const editValue = ref("");

        // Nueva lógica: edición directa, inputs dinámicos, sin modo toggable
        const values = ref<string[]>(list.value.length ? [...list.value] : [""]);

        // Permite v-model:items
        defineExpose({});
        // Soporte para v-model:items
        const model = toRef(props, 'items');
        watch(values, (val) => {
            // Cuando cambian los inputs, actualiza el modelo
            emit('update:items', val.filter(v => v.trim() !== '').join(props.splitter));
        }, { deep: true });


        // Inicializa los valores solo una vez al montar
        values.value = list.value.length ? [...list.value] : [""];
        // Elimina cualquier watcher que sincronice con props.items después del montaje

        // Actualiza el array y emite el string unido
        const updateAndEmit = () => {
            // Elimina vacíos intermedios, pero NO añade ninguno extra
            let arr = values.value.filter((v) => v.trim() !== '');
            values.value = arr;
            emit("update:items", arr.join(props.splitter));
        };

        // Maneja cambios en cada input
        const onInput = (val: string, idx: number) => {
            // Si se escribe el splitter, separa automáticamente
            if (val.includes(props.splitter)) {
                const parts = val.split(props.splitter).map(s => s.trim());
                values.value.splice(idx, 1, ...parts);
            } else {
                values.value[idx] = val;
            }
            updateAndEmit();
        };

        // Elimina un campo
        const removeAt = (idx: number) => {
            values.value.splice(idx, 1);
            if (values.value.length === 0) values.value = [""];
            updateAndEmit();
        };



        return () => (
            <div class="c-split-list flex flex-col gap-2">
                <ul class="flex flex-col gap-4 mt-2">
                    {values.value.map((val, idx) => (
                        <li key={idx} class="flex">
                            <input
                                type="text"
                                value={val}
                                onInput={e => onInput((e.target as HTMLInputElement).value, idx)}
                                onKeyup={e => {
                                    if ((e as KeyboardEvent).key === 'Backspace' && val === '' && values.value.length > 1) removeAt(idx);
                                }}
                                class="c-input text-white px-2 py-1 w-24"
                                placeholder="Nuevo elemento..."
                                autofocus={idx === values.value.length - 1}
                            />
                            {values.value.length > 1 && (
                                <button
                                    class="ml-1 text-red-400 hover:text-red-600 focus:outline-none"
                                    onClick={() => removeAt(idx)}
                                    aria-label={`Quitar elemento`}
                                    type="button"
                                >
                                    ×
                                </button>
                            )}
                        </li>
                    ))}
                    {/* Botón para añadir manualmente un nuevo campo */}
                    <li>
                        <button
                            class="px-3 py-1 rounded bg-indigo-600 text-white font-semibold hover:bg-indigo-700 transition"
                            onClick={() => { values.value.push(""); }}
                            type="button"
                        >
                            + Añadir
                        </button>
                    </li>
                </ul>
                {values.value.join(props.splitter)}
            </div>
        )
    }
})

