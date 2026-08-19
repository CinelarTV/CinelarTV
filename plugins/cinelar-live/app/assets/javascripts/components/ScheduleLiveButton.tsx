import { defineComponent, ref, computed } from "vue";
import CModal from "@/components/CModal.vue";
import CButton from "@/components/forms/c-button";
import { useSiteSettings } from "@/app/services/site-settings";

export default defineComponent({
  name: "ScheduleLiveButton",
  components: { CModal },
  props: {
    content: { type: Object, required: true },
    currentUser: { type: Object, default: null },
  },
  setup(props) {
    const { siteSettings } = useSiteSettings();
    const showModal = ref(false);
    const loading = ref(false);
    const error = ref("");
    const success = ref(false);
    const scheduledDate = ref("");
    const scheduledTime = ref("");
    const description = ref("");

    const isMovie = computed(() => props.content?.isMovie);
    const isLoggedIn = computed(() => !!props.currentUser);
    const schedulingRestricted = computed(
      () => siteSettings.cinelar_live_event_scheduling === "admins_only"
    );
    const isAdmin = computed(() => !!props.currentUser?.admin);
    const canSchedule = computed(
      () => isMovie.value && isLoggedIn.value && (!schedulingRestricted.value || isAdmin.value)
    );

    const startsAt = computed(() => {
      if (!scheduledDate.value || !scheduledTime.value) return null;
      return new Date(`${scheduledDate.value}T${scheduledTime.value}`);
    });

    const isValid = computed(() => {
      if (!startsAt.value) return false;
      const fiveMinFromNow = Date.now() + 5 * 60 * 1000;
      return startsAt.value.getTime() > fiveMinFromNow;
    });

    const isToday = computed(() => {
      return scheduledDate.value === new Date().toISOString().slice(0, 10);
    });

    const minTime = computed(() => {
      if (!isToday.value) return undefined;
      const now = new Date(Date.now() + 5 * 60 * 1000);
      return `${String(now.getHours()).padStart(2, "0")}:${String(now.getMinutes()).padStart(2, "0")}`;
    });

    const openModal = () => {
      showModal.value = true;
      error.value = "";
      success.value = false;
      scheduledDate.value = "";
      scheduledTime.value = "";
      description.value = "";
    };

    const handleSchedule = async () => {
      if (!isValid.value || !startsAt.value) return;

      loading.value = true;
      error.value = "";

      try {
        const res = await fetch("/community/events.json", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector<HTMLMetaElement>('[name="csrf-token"]')?.content || "",
          },
          body: JSON.stringify({
            content_id: props.content.id,
            starts_at: startsAt.value.toISOString(),
            description: description.value || undefined,
          }),
        });

        if (!res.ok) {
          const data = await res.json();
          throw new Error(data.error || "Error al programar el evento");
        }

        success.value = true;
        setTimeout(() => {
          showModal.value = false;
          success.value = false;
        }, 2000);
      } catch (e: any) {
        error.value = e.message;
      } finally {
        loading.value = false;
      }
    };

    if (!canSchedule.value) return () => null;

    return () => (
      <>
        <CButton
          onClick={openModal}
          class="flex items-center gap-2 px-4 py-2 rounded-lg bg-white/10 text-white/80 hover:bg-white/20 hover:text-white transition-all duration-200 text-sm font-medium"
        >
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
            />
          </svg>
          Programar en vivo
        </CButton>

        <CModal
          modelValue={showModal.value}
          onUpdate:modelValue={(v: boolean) => (showModal.value = v)}
          title="Programar en vivo"
          size="sm"
        >
          {success.value ? (
            <div class="text-center py-8">
              <div class="w-12 h-12 mx-auto mb-4 rounded-full bg-green-500/20 flex items-center justify-center">
                <svg class="w-6 h-6 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <p class="text-green-400 font-medium">Evento programado</p>
            </div>
          ) : (
            <>
              <div class="flex items-center gap-3 mb-5 p-3 rounded-lg bg-white/5">
                <div class="w-10 h-14 rounded overflow-hidden bg-black/40 flex-shrink-0">
                  {props.content.images?.poster ? (
                    <img
                      src={props.content.images.poster}
                      alt={props.content.title}
                      class="w-full h-full object-cover"
                    />
                  ) : (
                    <div class="w-full h-full flex items-center justify-center">
                      <svg class="w-6 h-6 text-white/20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                      </svg>
                    </div>
                  )}
                </div>
                <div>
                  <p class="text-sm font-medium text-white">{props.content.title}</p>
                  <p class="text-xs text-white/50">{props.content.year}</p>
                </div>
              </div>

              <div class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-white/70 mb-1.5">Fecha</label>
                  <input
                    type="date"
                    value={scheduledDate.value}
                    onInput={(e) => (scheduledDate.value = (e.target as HTMLInputElement).value)}
                    min={new Date().toISOString().slice(0, 10)}
                    class="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-red-500/50 focus:border-red-500/50"
                  />
                </div>

                <div>
                  <label class="block text-sm font-medium text-white/70 mb-1.5">Hora</label>
                  <input
                    type="time"
                    value={scheduledTime.value}
                    onInput={(e) => (scheduledTime.value = (e.target as HTMLInputElement).value)}
                    min={minTime.value}
                    class="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white text-sm focus:outline-none focus:ring-2 focus:ring-red-500/50 focus:border-red-500/50"
                  />
                </div>

                <div>
                  <label class="block text-sm font-medium text-white/70 mb-1.5">Descripción (opcional)</label>
                  <textarea
                    value={description.value}
                    onInput={(e) => (description.value = (e.target as HTMLTextAreaElement).value)}
                    rows={2}
                    placeholder="Ej: Viendo esta peli con la comunidad..."
                    class="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white text-sm placeholder-white/30 focus:outline-none focus:ring-2 focus:ring-red-500/50 focus:border-red-500/50 resize-none"
                  />
                </div>
              </div>

              {error.value && (
                <p class="mt-3 text-sm text-red-400">{error.value}</p>
              )}

              <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-white/10">
                <CButton
                  onClick={() => (showModal.value = false)}
                  class="px-4 py-2 text-sm text-white/60 hover:text-white transition-colors"
                >
                  Cancelar
                </CButton>
                <CButton
                  onClick={handleSchedule}
                  disabled={!isValid.value || loading.value}
                  loading={loading.value}
                  class={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
                    isValid.value && !loading.value
                      ? "bg-red-500 text-white hover:bg-red-600"
                      : "bg-white/10 text-white/30 cursor-not-allowed"
                  }`}
                >
                  {loading.value ? "Programando..." : "Programar"}
                </CButton>
              </div>
            </>
          )}
        </CModal>
      </>
    );
  },
});
