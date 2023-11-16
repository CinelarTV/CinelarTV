import Episode, { EpisodeData } from "./Episode";

export interface SeasonData {
    id: number;
    title: string;
    description: string;
    position: number;
    episodes: EpisodeData[];
}

class Season {
    private data: SeasonData;

    constructor(data: SeasonData) {
        this.data = data;
    }

    get id(): number {
        return this.data.id;
    }

    get title(): string {
        return this.data.title;
    }

    get description(): string {
        return this.data.description;
    }

    get position(): number {
        return this.data.position;
    }

    get episodes(): Episode[] {
        return this.data.episodes.map((episodeData) => new Episode(episodeData));
    }
}

export default Season;