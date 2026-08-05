import { defineComponent, PropType, ref, onMounted, onBeforeUnmount } from "vue";
import type { ImageVariants, ImageData, ContentImages, EpisodeImages } from "@/app/types/image";

interface Breakpoint {
  variant: keyof ImageVariants;
  min: number;
}

const BREAKPOINTS: Breakpoint[] = [
  { variant: "xlarge", min: 1400 },
  { variant: "large", min: 1024 },
  { variant: "medium", min: 768 },
  { variant: "small", min: 480 },
  { variant: "thumbnail", min: 0 },
];

const VARIANT_KEYS = new Set(["original", "thumbnail", "small", "medium", "large", "xlarge"]);

function isImageVariants(obj: any): boolean {
  if (!obj || typeof obj !== "object") return false;
  return Object.keys(obj).some((k) => VARIANT_KEYS.has(k));
}

function resolveVariants(
  images: ContentImages | EpisodeImages | ImageVariants | ImageData | undefined,
  type?: string
): ImageVariants | null {
  if (!images) return null;

  // ContentImages — poster/backdrop/logo are ImageVariants directly
  if ("poster" in images || "backdrop" in images || "logo" in images) {
    const ci = images as ContentImages;
    let chosen: ImageVariants | undefined;
    if (type === "poster") chosen = ci.poster;
    else if (type === "logo") chosen = ci.logo;
    else if (type === "backdrop") chosen = ci.backdrop;
    else chosen = ci.backdrop || ci.logo || ci.poster;
    if (chosen) return chosen;
  }

  // EpisodeImages — episode_thumbnail is ImageVariants directly
  if ("episode_thumbnail" in images) {
    const ei = images as EpisodeImages;
    if (ei.episode_thumbnail) return ei.episode_thumbnail;
  }

  // ImageData wrapper (has `variants` property)
  if ("variants" in images && typeof (images as any).variants === "object") {
    return (images as ImageData).variants;
  }

  // Already ImageVariants (has any known variant key)
  if (isImageVariants(images)) {
    return images as ImageVariants;
  }

  return null;
}

export default defineComponent({
  name: "ResponsiveImage",
  props: {
    images: {
      type: Object as PropType<ContentImages | EpisodeImages | ImageVariants | ImageData>,
      default: undefined,
    },
    type: {
      type: String as PropType<"poster" | "backdrop" | "episode_thumbnail" | "logo">,
      default: undefined,
    },
    fallback: {
      type: String,
      default: "",
    },
    alt: {
      type: String,
      default: "",
    },
    loading: {
      type: String as PropType<"lazy" | "eager">,
      default: "lazy",
    },
    class: {
      type: String,
      default: "",
    },
  },
  setup(props) {
    const viewportWidth = ref(typeof window !== "undefined" ? window.innerWidth : 0);

    const pickVariant = () => {
      const variants = resolveVariants(props.images, props.type);
      if (!variants) return null;

      for (const bp of BREAKPOINTS) {
        if (viewportWidth.value >= bp.min && variants[bp.variant]) {
          return bp.variant;
        }
      }
      // Viewport smaller than all breakpoints — pick smallest available
      for (const bp of [...BREAKPOINTS].reverse()) {
        if (variants[bp.variant]) return bp.variant;
      }
      return "original";
    };

    const onResize = () => {
      viewportWidth.value = window.innerWidth;
    };

    onMounted(() => {
      window.addEventListener("resize", onResize);
      viewportWidth.value = window.innerWidth;
    });

    onBeforeUnmount(() => {
      window.removeEventListener("resize", onResize);
    });

    return { viewportWidth, pickVariant };
  },
  render() {
    const variants = resolveVariants(this.images, this.type);

    if (!variants) {
      if (!this.fallback) return null;
      return (
        <img
          src={this.fallback}
          alt={this.alt}
          loading={this.loading}
          class={this.class}
        />
      );
    }

    // Pick the best available variant for the current viewport
    const chosenVariant = this.pickVariant();
    const chosenData = chosenVariant ? variants[chosenVariant] : null;

    const sources: any[] = [];

    // Add a <source> for each available variant
    for (const bp of BREAKPOINTS) {
      const variantData = variants[bp.variant];
      if (!variantData) continue;

      if (variantData.avif) {
        sources.push(
          <source
            srcSet={variantData.avif}
            type="image/avif"
            media={bp.min > 0 ? `(min-width: ${bp.min}px)` : undefined}
          />
        );
      }

      if (variantData.webp) {
        sources.push(
          <source
            srcSet={variantData.webp}
            type="image/webp"
            media={bp.min > 0 ? `(min-width: ${bp.min}px)` : undefined}
          />
        );
      }
    }

    // Fallback <img> uses the best available variant (or original)
    const fallbackSrc =
      (chosenData && (chosenData.webp || chosenData.avif)) ||
      variants.original?.webp ||
      variants.original?.avif ||
      "";

    return (
      <picture>
        {sources}
        <img src={fallbackSrc} alt={this.alt} loading={this.loading} class={this.class} />
      </picture>
    );
  },
});
