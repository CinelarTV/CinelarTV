import { ajax } from "../../lib/Ajax";
import RestModel from "./RestModel";
import type { EpisodeImages, ImageVariants } from "@/app/types/image";

export interface EpisodeData {
    id: string;
    title: string;
    description: string;
    thumbnail: string;
    thumbnail_resized?: string;
    images?: EpisodeImages;
    position: number;
    premium: boolean;
}

class Episode {
    private data: EpisodeData;

    constructor(data: EpisodeData) {
        this.data = data;
    }

    get id(): string {
        return this.data.id;
    }

    get title(): string {
        return this.data.title;
    }

    get description(): string {
        return this.data.description;
    }

    get thumbnail(): string {
        return this.data.thumbnail;
    }

    get thumbnailImages(): ImageVariants | undefined {
        return this.data.images?.episode_thumbnail;
    }

    get position(): number {
        return this.data.position;
    }

    get premium(): boolean {
        return this.data.premium || false;
    }
}

export default Episode;