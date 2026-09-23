import { defineComponent, ref, onMounted, computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useHead } from "unhead";
import { ajax } from "@/lib/Ajax";
import CFormRow from "@/components/forms/CFormRow";
import CInput from "@/components/forms/c-input.vue";
import CButton from "@/components/forms/c-button";
import CSpinner from "@/components/c-spinner";
import CAlert from "@/components/CAlert";
import CIcon from "@/components/c-icon.vue";

export default defineComponent({
  name: "HouseAdForm",
  setup() {
    const route = useRoute();
    const router = useRouter();
    const isEdit = computed(() => !!route.params.id);

    useHead({ title: computed(() => isEdit.value ? "Edit House Ad — Admin" : "New House Ad — Admin") });

    const name = ref("");
    const html = ref("");
    const visibleToAnons = ref(true);
    const visibleToLoggedIn = ref(true);
    const categoryIds = ref<number[]>([]);
    const contentTypes = ref<string[]>([]);
    const loading = ref(false);
    const saving = ref(false);
    const error = ref("");
    const categories = ref<any[]>([]);

    const loadAd = async () => {
      if (!isEdit.value) return;
      loading.value = true;
      try {
        const result = await ajax(`/cinelar_ads/house_ads/${route.params.id}.json`);
        const data = result.data;
        name.value = data.name;
        html.value = data.html;
        visibleToAnons.value = data.visible_to_anons;
        visibleToLoggedIn.value = data.visible_to_logged_in_users;
        categoryIds.value = (data.categories || []).map((c: any) => c.id);
        contentTypes.value = data.content_types || [];
      } catch (e) {
        error.value = "Failed to load house ad.";
      } finally {
        loading.value = false;
      }
    };

    const loadCategories = async () => {
      try {
        const result = await ajax("/categories.json");
        categories.value = result.data?.category_list?.categories || [];
      } catch {
        categories.value = [];
      }
    };

    const save = async () => {
      saving.value = true;
      error.value = "";
      try {
        const payload = {
          name: name.value,
          html: html.value,
          visible_to_anons: visibleToAnons.value,
          visible_to_logged_in_users: visibleToLoggedIn.value,
          category_ids: categoryIds.value,
          content_types: contentTypes.value,
        };

        if (isEdit.value) {
          await ajax(`/cinelar_ads/house_ads/${route.params.id}.json`, {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            data: JSON.stringify(payload),
          });
        } else {
          await ajax("/cinelar_ads/house_ads.json", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            data: JSON.stringify(payload),
          });
        }

        router.push({ name: "admin.ads.house-ads" });
      } catch (e) {
        error.value = "Failed to save house ad.";
      } finally {
        saving.value = false;
      }
    };

    const toggleContentType = (type: string) => {
      if (contentTypes.value.includes(type)) {
        contentTypes.value = contentTypes.value.filter((t) => t !== type);
      } else {
        contentTypes.value = [...contentTypes.value, type];
      }
    };

    onMounted(() => {
      loadCategories();
      loadAd();
    });

    return () => (
      <div class="admin-house-ads-form">
        <header class="admin-house-ads-form__hero">
          <div class="admin-house-ads-form__hero-header">
            <div>
              <p class="admin-house-ads-form__eyebrow">Admin Console</p>
              <h1 class="admin-house-ads-form__title">
                <CIcon icon="ad" size={28} />
                {" "}{isEdit.value ? "Edit House Ad" : "New House Ad"}
              </h1>
            </div>
            <div class="admin-house-ads-form__hero-actions">
              <CButton
                variant="ghost"
                icon="arrow-left"
                onClick={() => router.push({ name: "admin.ads.house-ads" })}
              >
                Back to list
              </CButton>
            </div>
          </div>
        </header>

        <section class="admin-house-ads-form__card">
          {loading.value ? (
            <div class="admin-house-ads-form__loading">
              <CSpinner />
            </div>
          ) : (
            <form onSubmit={(e: Event) => { e.preventDefault(); save(); }}>
              {error.value && (
                <CAlert type="danger" title="Error" dismissible>
                  {error.value}
                </CAlert>
              )}

              <CFormRow label="Name" required hint="Letters, numbers, spaces, hyphens and underscores only">
                <CInput
                  modelValue={name.value}
                  onUpdate:modelValue={(v: string) => (name.value = v)}
                  placeholder="e.g. Summer Sale Banner"
                />
              </CFormRow>

              <CFormRow label="HTML Code" required hint="Script tags will be stripped for security">
                <textarea
                  class="c-input min-h-[160px] font-mono text-sm"
                  value={html.value}
                  onInput={(e: any) => (html.value = e.target.value)}
                  placeholder="<div class='my-ad'>Your ad HTML here</div>"
                />
              </CFormRow>

              <CFormRow label="Visibility">
                <div class="flex flex-col gap-2">
                  <label class="flex items-center gap-2 text-sm text-white/80 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={visibleToAnons.value}
                      onChange={(e: any) => (visibleToAnons.value = e.target.checked)}
                      class="rounded"
                    />
                    Visible to anonymous users
                  </label>
                  <label class="flex items-center gap-2 text-sm text-white/80 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={visibleToLoggedIn.value}
                      onChange={(e: any) => (visibleToLoggedIn.value = e.target.checked)}
                      class="rounded"
                    />
                    Visible to logged-in users
                  </label>
                </div>
              </CFormRow>

              <CFormRow label="Content Types" hint="Leave unchecked to show in all content types">
                <div class="flex flex-col gap-2">
                  <label class="flex items-center gap-2 text-sm text-white/80 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={contentTypes.value.includes("MOVIE")}
                      onChange={() => toggleContentType("MOVIE")}
                      class="rounded"
                    />
                    Movies
                  </label>
                  <label class="flex items-center gap-2 text-sm text-white/80 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={contentTypes.value.includes("TVSHOW")}
                      onChange={() => toggleContentType("TVSHOW")}
                      class="rounded"
                    />
                    TV Shows
                  </label>
                </div>
              </CFormRow>

              <CFormRow label="Categories" hint="Hold Ctrl/Cmd to select multiple. Leave empty for all categories.">
                <select
                  class="c-input"
                  multiple
                  value={categoryIds.value.map(String)}
                  onChange={(e: any) => {
                    const selected = Array.from(e.target.selectedOptions, (o: any) => Number(o.value));
                    categoryIds.value = selected;
                  }}
                >
                  {categories.value.map((cat: any) => (
                    <option key={cat.id} value={cat.id}>
                      {cat.name}
                    </option>
                  ))}
                </select>
              </CFormRow>

              <div class="flex gap-3 pt-4 border-t border-white/6">
                <CButton
                  nativeType="submit"
                  icon="check"
                  loading={saving.value}
                >
                  {saving.value ? "Saving..." : "Save"}
                </CButton>
                <CButton
                  variant="ghost"
                  onClick={() => router.push({ name: "admin.ads.house-ads" })}
                >
                  Cancel
                </CButton>
              </div>
            </form>
          )}
        </section>
      </div>
    );
  },
});
