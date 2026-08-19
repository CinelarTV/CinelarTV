import { ref, computed } from "vue";

export interface LiveEvent {
  id: number;
  title: string;
  description?: string;
  content?: {
    id: string;
    title: string;
    poster?: string;
    year?: number;
  };
  status: "scheduled" | "starting" | "live" | "ended" | "cancelled";
  starts_at: string;
  estimated_end_at?: string;
  attendee_count: number;
  is_attending: boolean;
  session_id?: number;
  organizer?: { username: string };
}

export interface LiveSession {
  id: number;
  content?: {
    id: string;
    title: string;
    poster?: string;
  };
  participant_count: number;
  playback_position: number;
  is_playing: boolean;
  last_activity_at?: string;
  activity_score: number;
}

const activeSessions = ref<LiveSession[]>([]);
const upcomingEvents = ref<LiveEvent[]>([]);
const currentEvent = ref<LiveEvent | null>(null);
const loading = ref(false);

function csrfToken(): string {
  const el = document.querySelector('[name="csrf-token"]') as HTMLMetaElement;
  return el?.content || "";
}

async function apiFetch<T>(url: string, options?: RequestInit): Promise<T> {
  const res = await fetch(url, {
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken(),
      ...options?.headers,
    },
    ...options,
  });
  if (!res.ok) throw new Error(`API error: ${res.status}`);
  return res.json();
}

export function useLiveService() {
  const fetchActiveSessions = async () => {
    try {
      const data = await apiFetch<{ active: LiveSession[] }>("/community/status.json");
      activeSessions.value = data.active;
    } catch (e) {
      console.error("[Live] Failed to fetch active sessions:", e);
    }
  };

  const fetchEvents = async () => {
    loading.value = true;
    try {
      const data = await apiFetch<{ active: LiveSession[]; upcoming: LiveEvent[] }>(
        "/community/events.json"
      );
      activeSessions.value = data.active;
      upcomingEvents.value = data.upcoming;
    } catch (e) {
      console.error("[Live] Failed to fetch events:", e);
    } finally {
      loading.value = false;
    }
  };

  const fetchEvent = async (eventId: number) => {
    loading.value = true;
    try {
      const data = await apiFetch<LiveEvent>(        `/community/events/${eventId}.json`);
      currentEvent.value = data;
      return data;
    } catch (e) {
      console.error("[Live] Failed to fetch event:", e);
      return null;
    } finally {
      loading.value = false;
    }
  };

  const attendEvent = async (eventId: number) => {
    try {
      const data = await apiFetch<{ attending: boolean; count: number }>(
        `/community/events/${eventId}/attend.json`,
        { method: "POST" }
      );
      if (currentEvent.value && currentEvent.value.id === eventId) {
        currentEvent.value.is_attending = data.attending;
        currentEvent.value.attendee_count = data.count;
      }
      const inList = upcomingEvents.value.find((e) => e.id === eventId);
      if (inList) {
        inList.is_attending = data.attending;
        inList.attendee_count = data.count;
      }
      return data;
    } catch (e) {
      console.error("[Live] Failed to attend event:", e);
      return null;
    }
  };

  const unattendEvent = async (eventId: number) => {
    try {
      const data = await apiFetch<{ attending: boolean; count: number }>(
        `/community/events/${eventId}/unattend.json`,
        { method: "DELETE" }
      );
      if (currentEvent.value && currentEvent.value.id === eventId) {
        currentEvent.value.is_attending = data.attending;
        currentEvent.value.attendee_count = data.count;
      }
      const inList = upcomingEvents.value.find((e) => e.id === eventId);
      if (inList) {
        inList.is_attending = data.attending;
        inList.attendee_count = data.count;
      }
      return data;
    } catch (e) {
      console.error("[Live] Failed to unattend event:", e);
      return null;
    }
  };

  return {
    activeSessions,
    upcomingEvents,
    currentEvent,
    loading,
    fetchActiveSessions,
    fetchEvents,
    fetchEvent,
    attendEvent,
    unattendEvent,
  };
}
