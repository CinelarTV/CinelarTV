<template>
    <div class="content-manager-page">
        <!-- Header -->
        <div class="content-manager-header">
            <div class="content-manager-header__left">
                <h1 class="content-manager-header__title">
                    {{ $t("js.admin.content_manager.title") || "Content Manager" }}
                </h1>
                <p class="content-manager-header__subtitle">
                    {{ content.length }} {{ $t("js.admin.content_manager.total_items") || "items" }}
                </p>
            </div>
            <c-button @click="createContent" class="content-manager-header__btn">
                <PlusIcon :size="16" />
                {{ $t("js.admin.content_manager.create_content") || "Add Content" }}
            </c-button>
        </div>

        <!-- Filters bar -->
        <div class="content-manager-filters">
            <div class="content-manager-filters__search">
                <SearchIcon :size="16" class="content-manager-filters__search-icon" />
                <input v-model="searchQuery" type="text"
                    :placeholder="$t('js.admin.content_manager.search') || 'Search content...'"
                    class="content-manager-filters__input" />
            </div>
            <div class="content-manager-filters__group">
                <select v-model="typeFilter" class="content-manager-filters__select">
                    <option value="">{{ $t("js.admin.content_manager.all_types") || "All types" }}</option>
                    <option value="MOVIE">{{ $t("js.admin.content_manager.content_types.MOVIE") || "Movies" }}</option>
                    <option value="TVSHOW">{{ $t("js.admin.content_manager.content_types.TVSHOW") || "Series" }}
                    </option>
                </select>
                <select v-model="sortBy" class="content-manager-filters__select">
                    <option value="newest">{{ $t("js.admin.content_manager.sort.newest") || "Newest first" }}</option>
                    <option value="oldest">{{ $t("js.admin.content_manager.sort.oldest") || "Oldest first" }}</option>
                    <option value="title">{{ $t("js.admin.content_manager.sort.title") || "Title A-Z" }}</option>
                </select>
            </div>
        </div>

        <!-- Loading state -->
        <div v-if="loading" class="content-manager-loading">
            <c-spinner />
        </div>

        <!-- Empty state -->
        <div v-else-if="filteredContent.length === 0" class="content-manager-empty">
            <ClapperboardIcon :size="48" class="content-manager-empty__icon" />
            <h3 class="content-manager-empty__title">
                {{ $t("js.admin.content_manager.no_content") || "No content yet" }}
            </h3>
            <p class="content-manager-empty__subtitle">
                {{
                    $t("js.admin.content_manager.no_content_description")
                    || "Start by adding your first piece of content" }}
            </p>
            <c-button @click="createContent" class="content-manager-empty__btn">
                <PlusIcon :size="16" />
                {{ $t("js.admin.content_manager.create_content") || "Add Content" }}
            </c-button>
        </div>

        <!-- Content grid -->
        <div v-else class="content-manager-grid">
            <RouterLink v-for="item in filteredContent" :key="item.id" class="content-manager-card"
                :to="{ name: 'admin.content.manager.edit', params: { id: item.id } }">
                <div class="content-manager-card__image">
                    <img :src="item.cover || item.banner" :alt="item.title" loading="lazy" />
                    <div class="content-manager-card__type">
                        {{ $t(`js.admin.content_manager.content_types.${item.content_type}`) || item.content_type }}
                    </div>
                </div>
                <div class="content-manager-card__body">
                    <h3 class="content-manager-card__title">{{ item.title }}</h3>
                    <p class="content-manager-card__meta">
                        <span>ID: {{ item.id.slice(0, 8) }}</span>
                        <span v-if="item.year">· {{ item.year }}</span>
                    </p>
                </div>
                <div class="content-manager-card__actions">
                    <button class="content-manager-card__edit" @click.stop="editContent(item)">
                        <Edit3Icon :size="14" />
                        {{ $t("js.admin.actions.edit") || "Edit" }}
                    </button>
                </div>
            </RouterLink>
        </div>

        <CreateContentModal ref="createContentModalRef" @content-created="fetchContent" />
    </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { PlusIcon, SearchIcon, Edit3Icon, ClapperboardIcon } from 'lucide-vue-next';
import { ajax } from '../../../lib/Ajax';
import CreateContentModal from '../../../components/modals/create-content.modal.vue';

const router = useRouter();
const loading = ref(true);
const content = ref([]);
const searchQuery = ref('');
const typeFilter = ref('');
const sortBy = ref('newest');
const createContentModalRef = ref(null);

const filteredContent = computed(() => {
    let result = [...content.value];

    // Search filter
    if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase();
        result = result.filter(item =>
            item.title?.toLowerCase().includes(query) ||
            item.id?.toLowerCase().includes(query)
        );
    }

    // Type filter
    if (typeFilter.value) {
        result = result.filter(item => item.content_type === typeFilter.value);
    }

    // Sort
    switch (sortBy.value) {
        case 'newest':
            result.sort((a, b) => new Date(b.created_at || 0) - new Date(a.created_at || 0));
            break;
        case 'oldest':
            result.sort((a, b) => new Date(a.created_at || 0) - new Date(b.created_at || 0));
            break;
        case 'title':
            result.sort((a, b) => (a.title || '').localeCompare(b.title || ''));
            break;
    }

    return result;
});

const editContent = (item) => {
    router.push({
        name: 'admin.content.manager.edit',
        params: { id: item.id }
    });
};

const createContent = () => {
    createContentModalRef.value?.setIsOpen(true);
};

const fetchContent = async () => {
    loading.value = true;
    try {
        const response = await ajax.get('/admin/content-manager/all.json');
        content.value = response.data.data || [];
    } catch (error) {
        console.error('Failed to fetch content:', error);
    }
    loading.value = false;
};

onMounted(() => {
    fetchContent();
});
</script>
