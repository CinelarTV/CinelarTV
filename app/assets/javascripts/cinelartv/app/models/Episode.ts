import { ajax } from "../../lib/Ajax";
import RestModel from "./RestModel";

export interface EpisodeData {
    id: string;
    title: string;
    description: string;
    thumbnail: string;
    position: number;
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

    get position(): number {
        return this.data.position;
    }
}

export default Episode;