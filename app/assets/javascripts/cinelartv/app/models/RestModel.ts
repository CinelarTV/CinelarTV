import { ajax } from "../../lib/Ajax";
import { ref } from "vue";

class RestModel {
    isSaving = ref(false);
    isDeleting = ref(false);
    isFetching = ref(false);
    isUpdating = ref(false);
    isCreating = ref(false);

    constructor(public url: string) {}

    async update(data: any): Promise<void> {
        try {
            this.isUpdating.value = true;
            await ajax.put(this.url, data);
        } finally {
            this.isUpdating.value = false;
        }
    }

    async delete(): Promise<void> {
        try {
            this.isDeleting.value = true;
            await ajax.delete(this.url);
        } finally {
            this.isDeleting.value = false;
        }
    }
}

export default RestModel;