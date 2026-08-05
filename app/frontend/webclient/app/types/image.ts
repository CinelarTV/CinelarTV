export interface ImageVariantSet {
  avif?: string;
  webp: string;
}

export interface ImageVariants {
  original: ImageVariantSet;
  thumbnail?: ImageVariantSet;
  small?: ImageVariantSet;
  medium?: ImageVariantSet;
  large?: ImageVariantSet;
  xlarge?: ImageVariantSet;
}

export interface ImageData {
  variants: ImageVariants;
}

export interface ContentImages {
  poster?: ImageVariants;
  backdrop?: ImageVariants;
  logo?: ImageVariants;
}

export interface EpisodeImages {
  episode_thumbnail?: ImageVariants;
}
