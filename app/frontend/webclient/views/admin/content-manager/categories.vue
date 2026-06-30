<template>
    <div class="content-manager-page">
        <!-- Header -->
        <div class="content-manager-header">
            <div class="content-manager-header__left">
                <h1 class="content-manager-header__title">
                    {{ $t("js.admin.content_manager.categories") || "Categories" }}
                </h1>
                <p class="content-manager-header__subtitle">
                    {{ categories.length }} {{ $t("js.admin.content_manager.total_items") || "items" }}
                </p>
            </div>
            <div class="content-manager-header__right">
                <c-button v-if="SiteSettings.enable_category_auto_assignment" @click="populateFromTmdb" :loading="populating" class="content-manager-header__btn">
                    <RefreshCwIcon :size="16" />
                    {{ $t("js.admin.categories.populate_from_tmdb") || "Populate from TMDB" }}
                </c-button>
                <c-button @click="createCategory" class="content-manager-header__btn">
                    <PlusIcon :size="16" />
                    {{ $t("js.admin.content_manager.create_category") || "Add Category" }}
                </c-button>
            </div>
        </div>

        <!-- Filters bar -->
        <div class="content-manager-filters">
            <div class="content-manager-filters__search">
                <SearchIcon :size="16" class="content-manager-filters__search-icon" />
                <input v-model="searchQuery" type="text"
                    :placeholder="$t('js.admin.content_manager.search') || 'Search categories...'"
                    class="content-manager-filters__input" />
            </div>
        </div>

        <!-- Loading state -->
        <div v-if="loading" class="content-manager-loading">
            <c-spinner />
        </div>

        <!-- Empty state -->
        <div v-else-if="filteredCategories.length === 0" class="content-manager-empty">
            <ShapesIcon :size="48" class="content-manager-empty__icon" />
            <h3 class="content-manager-empty__title">
                {{ $t("js.admin.content_manager.no_categories") || "No categories yet" }}
            </h3>
            <p class="content-manager-empty__subtitle">
                {{
                    $t("js.admin.content_manager.no_categories_description")
                    || "Start by adding your first category" }}
            </p>
            <c-button @click="createCategory" class="content-manager-empty__btn">
                <PlusIcon :size="16" />
                {{ $t("js.admin.content_manager.create_category") || "Add Category" }}
            </c-button>
        </div>

        <!-- Categories grid -->
        <div v-else class="content-manager-grid">
            <div v-for="item in filteredCategories" :key="item.id" class="content-manager-card">
                <div class="content-manager-card__body">
                    <h3 class="content-manager-card__title">{{ item.name }}</h3>
                    <p class="content-manager-card__description">{{ item.description }}</p>
                    <p class="content-manager-card__meta">
                        <span>ID: {{ item.id }}</span>
                    </p>
                </div>
                <div class="content-manager-card__actions">
                    <button class="content-manager-card__edit" @click="editCategory(item)">
                        <Edit3Icon :size="14" />
                        {{ $t("js.admin.actions.edit") || "Edit" }}
                    </button>
                    <button class="content-manager-card__delete" @click="deleteCategory(item)">
                        <Trash2Icon :size="14" />
                        {{ $t("js.admin.actions.delete") || "Delete" }}
                    </button>
                </div>
            </div>
        </div>

        <CategoryModal ref="categoryModalRef" @category-saved="fetchCategories" />
    </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { PlusIcon, SearchIcon, Edit3Icon, Trash2Icon, ShapesIcon, RefreshCwIcon } from 'lucide-vue-next';
import { ajax } from '../../../lib/Ajax';
import CategoryModal from '../../../components/modals/category-modal.vue';
import { inject } from 'vue';

const SiteSettings = inject('SiteSettings');

const loading = ref(true);
const categories = ref([]);
const searchQuery = ref('');
const categoryModalRef = ref(null);
const populating = ref(false);

const filteredCategories = computed(() => {
    let result = [...categories.value];

    // Search filter
    if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase();
        result = result.filter(item =>
            item.name?.toLowerCase().includes(query) ||
            item.description?.toLowerCase().includes(query)
        );
    }

    return result;
});

const createCategory = () => {
    categoryModalRef.value?.setIsOpen(true);
};

const editCategory = (item) => {
    categoryModalRef.value?.setIsOpen(true, item);
};

const deleteCategory = async (item) => {
    if (!confirm(`Are you sure you want to delete "${item.name}"?`)) {
        return;
    }

    try {
        await ajax.delete(`/admin/categories/${item.id}.json`);
        fetchCategories();
    } catch (error) {
        console.error('Failed to delete category:', error);
    }
};

const populateFromTmdb = async () => {
    if (!confirm('This will populate categories from TMDB genres. Continue?')) {
        return;
    }

    populating.value = true;
    try {
        const response = await ajax.post('/admin/categories/populate_from_tmdb.json');
        alert(`Populated successfully: ${response.data.created} created, ${response.data.skipped} skipped`);
        fetchCategories();
    } catch (error) {
        console.error('Failed to populate from TMDB:', error);
        alert('Failed to populate categories from TMDB. Check console for details.');
    } finally {
        populating.value = false;
    }
};

const fetchCategories = async () => {
    loading.value = true;
    try {
        const response = await ajax.get('/admin/categories.json');
        categories.value = response.data.data || [];
    } catch (error) {
        console.error('Failed to fetch categories:', error);
    }
    loading.value = false;
};

onMounted(() => {
    fetchCategories();
});
</script>

<style scoped>
.content-manager-card__description {
    color: var(--c-primary-100);
    font-size: 0.875rem;
    line-height: 1.4;
    margin-bottom: 0.5rem;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
}

.content-manager-card__delete {
    background: rgba(239, 68, 68, 0.1);
    color: #ef4444;
}

.content-manager-card__delete:hover {
    background: rgba(239, 68, 68, 0.2);
}
</style>
