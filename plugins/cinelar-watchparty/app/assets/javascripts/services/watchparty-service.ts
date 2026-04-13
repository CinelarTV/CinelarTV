import { ref, computed } from 'vue';

export interface WatchPartyMessage {
    id: string;
    user: {
        id: number | string;
        name: string;
        avatar: string;
    };
    text: string;
    timestamp: Date;
    type: 'message' | 'system' | 'playback';
}

export interface WatchPartyUser {
    id: number | string;
    name: string;
    avatar: string;
    isHost: boolean;
    joinedAt: Date;
}

export interface WatchPartyState {
    sessionId: string | null;
    users: WatchPartyUser[];
    messages: WatchPartyMessage[];
    isHost: boolean;
    playbackState: {
        isPlaying: boolean;
        currentTime: number;
        duration: number;
    };
}

const state = ref<WatchPartyState>({
    sessionId: null,
    users: [],
    messages: [],
    isHost: false,
    playbackState: {
        isPlaying: false,
        currentTime: 0,
        duration: 0,
    },
});

const isConnected = computed(() => state.value.sessionId !== null);
const userCount = computed(() => state.value.users.length);
const messageList = computed(() => state.value.messages);

const csrfToken = (): string => {
    return (document.querySelector('[name="csrf-token"]') as HTMLMetaElement)?.content || '';
};

export function useWatchParty() {
    const addMessage = (text: string, type: 'message' | 'system' | 'playback' = 'message') => {
        const message: WatchPartyMessage = {
            id: `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            user: {
                id: 'current_user',
                name: 'You',
                avatar: '',
            },
            text,
            timestamp: new Date(),
            type,
        };
        state.value.messages.push(message);
    };

    const addSystemMessage = (text: string) => {
        const message: WatchPartyMessage = {
            id: `sys_${Date.now()}`,
            user: {
                id: 'system',
                name: 'System',
                avatar: '',
            },
            text,
            timestamp: new Date(),
            type: 'system',
        };
        state.value.messages.push(message);
    };

    // Send chat message via backend (MessageBus publish is server-side only)
    const sendMessage = async (text: string) => {
        if (!text.trim() || !state.value.sessionId) return;

        try {
            await fetch(`/watch_party/sessions/${state.value.sessionId}/chat.json`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': csrfToken(),
                },
                body: JSON.stringify({ text: text.trim() }),
            });
        } catch (error) {
            console.error('Failed to send chat message:', error);
        }
    };

    // Sync playback state via backend
    const syncPlayback = async (currentTime: number, isPlaying: boolean) => {
        if (!state.value.sessionId || !state.value.isHost) return;

        try {
            await fetch(`/watch_party/sessions/${state.value.sessionId}/sync.json`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': csrfToken(),
                },
                body: JSON.stringify({
                    current_time: currentTime,
                    is_playing: isPlaying,
                }),
            });
        } catch (error) {
            console.error('Failed to sync playback:', error);
        }
    };

    const createSession = async (contentId: string | number) => {
        try {
            const response = await fetch('/watch_party/sessions.json', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': csrfToken(),
                },
                body: JSON.stringify({ content_id: contentId }),
            });

            if (!response.ok) throw new Error('Failed to create session');

            const data = await response.json();
            state.value.sessionId = data.session_id;
            state.value.isHost = true;
            state.value.users = data.users || [];

            // Add session to URL for persistence and sharing
            updateSessionUrl(data.session_id);

            addSystemMessage('WatchParty session created. Share the link to invite others!');

            // Subscribe to MessageBus
            subscribeToSession(data.session_id);

            return data;
        } catch (error) {
            console.error('Error creating WatchParty session:', error);
            addSystemMessage('Failed to create WatchParty session');
            throw error;
        }
    };

    const joinSession = async (sessionId: string) => {
        try {
            const response = await fetch(`/watch_party/sessions/${sessionId}/join.json`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': csrfToken(),
                },
            });

            if (!response.ok) throw new Error('Failed to join session');

            const data = await response.json();
            state.value.sessionId = sessionId;
            state.value.isHost = data.is_host;
            state.value.users = data.users || [];

            // Add session to URL
            updateSessionUrl(sessionId);

            addSystemMessage(`Joined WatchParty session. Welcome!`);

            // Subscribe to MessageBus
            subscribeToSession(sessionId);

            return data;
        } catch (error) {
            console.error('Error joining WatchParty session:', error);
            addSystemMessage('Failed to join WatchParty session');
            throw error;
        }
    };

    const leaveSession = async () => {
        if (!state.value.sessionId) return;

        try {
            await fetch(`/watch_party/sessions/${state.value.sessionId}/leave.json`, {
                method: 'POST',
                headers: {
                    'X-CSRF-Token': csrfToken(),
                },
            });

            addSystemMessage('You left the WatchParty session');

            // Unsubscribe from MessageBus
            unsubscribeFromSession();

            // Clear URL
            clearSessionFromUrl();

            state.value.sessionId = null;
            state.value.users = [];
            state.value.isHost = false;
        } catch (error) {
            console.error('Error leaving WatchParty session:', error);
        }
    };

    // Fetch session data from backend (for restoring from URL param)
    const fetchSessionStatus = async (sessionId: string) => {
        try {
            const response = await fetch(`/watch_party/sessions/${sessionId}/status.json`);
            if (!response.ok) return false;

            const data = await response.json();
            state.value.sessionId = sessionId;
            state.value.isHost = data.is_host;
            state.value.users = data.users || [];
            state.value.playbackState.currentTime = data.current_time || 0;
            state.value.playbackState.isPlaying = data.is_playing || false;

            addSystemMessage(`Rejoined WatchParty session`);

            // Subscribe to MessageBus
            subscribeToSession(sessionId);

            return true;
        } catch (error) {
            console.error('Error fetching session status:', error);
            // Session might be invalid, clear from URL
            clearSessionFromUrl();
            return false;
        }
    };

    // URL helpers for session persistence and sharing
    const updateSessionUrl = (sessionId: string) => {
        if (typeof window === 'undefined') return;
        const url = new URL(window.location.href);
        url.searchParams.set('watchparty_session', sessionId);
        window.history.replaceState({}, '', url.toString());
    };

    const clearSessionFromUrl = () => {
        if (typeof window === 'undefined') return;
        const url = new URL(window.location.href);
        url.searchParams.delete('watchparty_session');
        window.history.replaceState({}, '', url.toString());
    };

    const getSessionFromUrl = (): string | null => {
        if (typeof window === 'undefined') return null;
        const url = new URL(window.location.href);
        return url.searchParams.get('watchparty_session');
    };

    // Auto-join session from URL on init (fetches status from backend)
    const autoJoinFromUrl = async () => {
        const sessionId = getSessionFromUrl();
        if (sessionId && !state.value.sessionId) {
            return await fetchSessionStatus(sessionId);
        }
        return false;
    };

    // MessageBus subscription (receive only, publish is server-side)
    let messageBusHandler: ((data: any) => void) | null = null;

    const subscribeToSession = (sessionId: string) => {
        if (typeof window === 'undefined' || !(window as any).MessageBus) {
            console.warn('[WatchParty] MessageBus not available');
            return;
        }

        const channel = `/watchparty/${sessionId}`;
        console.log('[WatchParty] Subscribing to channel:', channel);

        // Unsubscribe first if already subscribed
        unsubscribeFromSession();

        messageBusHandler = (data: any) => {
            console.log('[WatchParty] MessageBus received:', data);

            switch (data.type) {
                case 'chat_message':
                    console.log('[WatchParty] Chat message received:', data.text);
                    state.value.messages.push({
                        id: `msg_${Date.now()}`,
                        user: {
                            id: data.user_id,
                            name: data.user_name,
                            avatar: data.user_avatar || '',
                        },
                        text: data.text,
                        timestamp: new Date(),
                        type: 'message',
                    });
                    break;

                case 'playback_sync':
                    console.log('[WatchParty] Playback sync:', data.current_time, data.is_playing);
                    state.value.playbackState.currentTime = data.current_time;
                    state.value.playbackState.isPlaying = data.is_playing;
                    break;

                case 'user_joined':
                    console.log('[WatchParty] User joined:', data.user_name);
                    state.value.users.push(data.user);
                    addSystemMessage(`${data.user.name} joined the WatchParty`);
                    break;

                case 'user_left':
                    console.log('[WatchParty] User left:', data.user_name);
                    state.value.users = state.value.users.filter(u => u.id !== data.user_id);
                    addSystemMessage(`${data.user_name} left the WatchParty`);
                    break;

                case 'host_transferred':
                    if (data.new_host_id && data.new_host_name) {
                        console.log('[WatchParty] Host transferred to:', data.new_host_name);
                        addSystemMessage(`${data.new_host_name} is now the host`);
                    }
                    break;

                case 'session_ended':
                    console.log('[WatchParty] Session ended');
                    addSystemMessage('WatchParty session ended by host');
                    leaveSession();
                    break;

                default:
                    console.warn('[WatchParty] Unknown message type:', data.type);
            }
        };

        (window as any).MessageBus.subscribe(channel, messageBusHandler);
        console.log('[WatchParty] Successfully subscribed to', channel);
    };

    const unsubscribeFromSession = () => {
        if (typeof window === 'undefined' || !(window as any).MessageBus) return;

        if (state.value.sessionId) {
            const channel = `/watchparty/${state.value.sessionId}`;
            (window as any).MessageBus.unsubscribe(channel, messageBusHandler);
        }
        messageBusHandler = null;
    };

    const getShareUrl = (): string => {
        if (!state.value.sessionId) return '';
        if (typeof window === 'undefined') return '';
        const url = new URL(window.location.href);
        url.searchParams.set('watchparty_session', state.value.sessionId);
        return url.toString();
    };

    // Cleanup
    const cleanup = () => {
        unsubscribeFromSession();
    };

    return {
        state,
        isConnected,
        userCount,
        messageList,
        createSession,
        joinSession,
        leaveSession,
        sendMessage,
        syncPlayback,
        addSystemMessage,
        cleanup,
        autoJoinFromUrl,
        getShareUrl,
        getSessionFromUrl,
    };
}
