// ContinueWatching.ts

import { ajax } from "../../lib/Ajax";

export interface ContinueWatchingData {
    id: number;
    profile_id: string;
    content_id: string;
    episode_id: string;
    progress: number;
    duration: number;
    last_watched_at: string;
    finished: boolean;
    created_at: string;
    updated_at: string;
}

class ContinueWatching {
    private data: ContinueWatchingData;

    constructor(data: ContinueWatchingData) {
        this.data = data;
    }

    get id(): number {
        return this.data.id;
    }

    get profileId(): string {
        return this.data.profile_id;
    }

    get contentId(): string {
        return this.data.content_id;
    }

    get episodeId(): string {
        return this.data.episode_id;
    }

    get progress(): number {
        return this.data.progress;
    }

    get duration(): number {
        return this.data.duration;
    }

    get lastWatchedAt(): string {
        return this.data.last_watched_at;
    }

    get finished(): boolean {
        return this.data.finished;
    }

    get createdAt(): string {
        return this.data.created_at;
    }

    get updatedAt(): string {
        return this.data.updated_at;
    }

    static async getById(id: number): Promise<ContinueWatching | null> {
        try {
            const response = await ajax.get(`/continue_watchings/${id}.json`);
            return new ContinueWatching(response.data.continue_watching);
        } catch (error) {
            console.error(error);
            return null;
        }
    }
}

export default ContinueWatching;
