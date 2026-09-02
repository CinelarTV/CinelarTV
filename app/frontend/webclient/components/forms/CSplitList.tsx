import { defineComponent, ref, computed, watch } from "vue"
import CIcon from "../c-icon.vue"

export default defineComponent({
    name: "CSplitList",
    props: {
        splitter: {
            type: String,
            default: ",",
            validator: (value: string) => value.length === 1
        },
        items: {
            type: String,
            default: ""
        }
    },
    emits: ["update:items"],
    setup(props, { emit }) {
        const list = computed(() =>
            props.items ? props.items.split(props.splitter).map(i => i.trim()).filter(Boolean) : []
        )

        const values = ref<string[]>(list.value.length ? [...list.value] : [""])

        watch(values, (val) => {
            emit("update:items", val.filter(v => v.trim() !== "").join(props.splitter))
        }, { deep: true })

        const onInput = (val: string, idx: number) => {
            if (val.includes(props.splitter)) {
                const parts = val.split(props.splitter).map(s => s.trim())
                values.value.splice(idx, 1, ...parts)
            } else {
                values.value[idx] = val
            }
            emit("update:items", values.value.filter(v => v.trim() !== "").join(props.splitter))
        }

        const removeAt = (idx: number) => {
            values.value.splice(idx, 1)
            if (values.value.length === 0) values.value = [""]
            emit("update:items", values.value.filter(v => v.trim() !== "").join(props.splitter))
        }

        const addItem = () => {
            values.value.push("")
        }

        return () => (
            <div class="c-split-list">
                <ul class="c-split-list__items">
                    {values.value.map((val, idx) => (
                        <li key={idx} class="c-split-list__item">
                            <input
                                type="text"
                                value={val}
                                onInput={e => onInput((e.target as HTMLInputElement).value, idx)}
                                onKeyup={e => {
                                    if ((e as KeyboardEvent).key === "Backspace" && val === "" && values.value.length > 1) {
                                        removeAt(idx)
                                    }
                                }}
                                class="c-input c-split-list__input"
                                placeholder="Elemento..."
                            />
                            {values.value.length > 1 && (
                                <button
                                    type="button"
                                    class="c-split-list__remove"
                                    onClick={() => removeAt(idx)}
                                    aria-label="Quitar elemento"
                                >
                                    <CIcon icon="x" size={14} />
                                </button>
                            )}
                        </li>
                    ))}
                </ul>
                <button
                    type="button"
                    class="c-split-list__add"
                    onClick={addItem}
                >
                    <CIcon icon="plus" size={14} />
                    <span>Añadir</span>
                </button>
            </div>
        )
    }
})
