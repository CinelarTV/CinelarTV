interface MessageBusCallback {
    channel: string;
    func: (data: any, globalId?: number, messageId?: number) => void;
    last_id: number;
}

interface Message {
    channel: string;
    data: any;
    global_id?: number;
    message_id: number;
}

interface MessageBusConfig {
    minHiddenPollInterval?: number;
    enableChunkedEncoding?: boolean;
    enableLongPolling?: boolean;
    callbackInterval?: number;
    backgroundCallbackInterval?: number;
    minPollInterval?: number;
    maxPollInterval?: number;
    alwaysLongPoll?: boolean;
    shouldLongPollCallback?: () => boolean;
    firstChunkTimeout?: number;
    retryChunkedAfterRequests?: number;
    baseUrl?: string;
    headers?: Record<string, string>;
}

type MessageBusStatus = 'paused' | 'started' | 'stopped';

class MessageBus {
    private callbacks: MessageBusCallback[] = [];
    private clientId: string;
    private failCount = 0;
    private paused = false;
    private later: Message[] = [];
    private chunkedBackoff = 0;
    private stopped = false;
    private started = false;
    private pollTimeout: number | null = null;
    private delayPollTimeout: number | null = null;
    private totalAjaxFailures = 0;
    private totalAjaxCalls = 0;
    private lastAjaxStartedAt: Date | null = null;
    private currentRequest: AbortController | null = null;
    private onVisibilityChange: (() => void) | null = null;

    // Configuration
    public minHiddenPollInterval = 1500;
    public enableChunkedEncoding = true;
    public enableLongPolling = true;
    public callbackInterval = 15000;
    public backgroundCallbackInterval = 60000;
    public minPollInterval = 100;
    public maxPollInterval = 3 * 60 * 1000;
    public alwaysLongPoll = false;
    public shouldLongPollCallback?: () => boolean;
    public firstChunkTimeout = 3000;
    public retryChunkedAfterRequests = 30;
    public baseUrl = "/";
    public headers: Record<string, string> = {};

    constructor(config: MessageBusConfig = {}) {
        this.clientId = this.generateUniqueId();
        Object.assign(this, config);
    }

    private generateUniqueId(): string {
        return "xxxxxxxxxxxx4xxxyxxxxxxxxxxxxxxx".replace(/[xy]/g, (c) => {
            const r = (Math.random() * 16) | 0;
            const v = c === "x" ? r : (r & 0x3) | 0x8;
            return v.toString(16);
        });
    }

    private isHidden(): boolean {
        if (typeof document === 'undefined') return false;

        const prefixes = ["", "webkit", "ms", "moz"];
        for (const prefix of prefixes) {
            const prop = prefix + (prefix === "" ? "hidden" : "Hidden");
            if (document[prop as keyof Document] !== undefined) {
                return document[prop as keyof Document] as boolean;
            }
        }
        return !document.hasFocus();
    }

    private hasLocalStorage(): boolean {
        try {
            if (typeof localStorage === 'undefined') return false;
            localStorage.setItem("mbTestLocalStorage", Date.now().toString());
            localStorage.removeItem("mbTestLocalStorage");
            return true;
        } catch {
            return false;
        }
    }

    private updateLastAjax(): void {
        if (this.hasLocalStorage()) {
            localStorage.setItem("__mbLastAjax", Date.now().toString());
        }
    }

    private hiddenTabShouldWait(): boolean {
        if (this.hasLocalStorage() && this.isHidden()) {
            const lastAjaxCall = parseInt(localStorage.getItem("__mbLastAjax") || "0", 10);
            const deltaAjax = Date.now() - lastAjaxCall;
            return deltaAjax >= 0 && deltaAjax < this.minHiddenPollInterval;
        }
        return false;
    }

    private shouldLongPoll(): boolean {
        return this.alwaysLongPoll ||
            (this.shouldLongPollCallback ? this.shouldLongPollCallback() : !this.isHidden());
    }

    private processMessages(messages: Message[]): boolean {
        if (!messages || messages.length === 0) {
            this.logInfo('No messages to process');
            return false;
        }

        for (const message of messages) {
            for (const callback of this.callbacks) {
                if (callback.channel === message.channel) {
                    callback.last_id = message.message_id;
                    try {
                        callback.func(message.data, message.global_id, message.message_id);
                        this.logInfo(`Message received on channel '${message.channel}'`, message.data);
                    } catch (e) {
                        this.logError(`callback ${callback.channel} caused exception`, e);
                    }
                }
                if (message.channel === "/__status" && message.data[callback.channel] !== undefined) {
                    callback.last_id = message.data[callback.channel];
                }
            }
        }

        return true;
    }

    private reqSuccess(messages: Message[]): boolean {
        this.failCount = 0;
        if (this.paused) {
            if (messages) {
                this.later.push(...messages);
            }
            return false;
        } else {
            return this.processMessages(messages);
        }
    }

    private async longPoller(poll: () => void, data: Record<string, number>): Promise<void> {
        if (this.currentRequest) {
            return;
        }

        let gotData = false;
        let abortedByClient = false;
        let rateLimited = false;
        let rateLimitedSeconds = 0;

        this.lastAjaxStartedAt = new Date();
        this.totalAjaxCalls += 1;
        const requestData = { ...data, __seq: this.totalAjaxCalls };

        const longPoll = this.shouldLongPoll() && this.enableLongPolling;
        let chunked = longPoll && this.enableChunkedEncoding;

        if (this.chunkedBackoff > 0) {
            this.chunkedBackoff--;
            chunked = false;
        }

        const headers: Record<string, string> = {
            "X-SILENCE-LOGGER": "true",
            "Content-Type": "application/x-www-form-urlencoded",
            ...this.headers,
        };

        if (!chunked) {
            headers["Dont-Chunk"] = "true";
        }

        const controller = new AbortController();
        controller.signal.addEventListener("abort", () => {
            this.logWarn("Request aborted by client");
        });
        this.currentRequest = controller;

        const url = `${this.baseUrl}message-bus/${this.clientId}/poll${!longPoll ? "?dlp=t" : ""}`;
        const body = new URLSearchParams(requestData as any).toString();

        this.updateLastAjax();

        try {
            const response = await fetch(url, {
                method: 'POST',
                headers,
                body,
                signal: controller.signal,
            });

            if (response.status === 429) {
                const tryAfter = parseInt(response.headers.get("Retry-After") || "0", 10) || 15;
                rateLimitedSeconds = Math.max(tryAfter, 15);
                rateLimited = true;
            } else if (response.ok) {
                if (chunked && response.body) {
                    await this.handleChunkedResponse(response);
                } else {
                    const messages: Message[] = await response.json();
                    gotData = this.reqSuccess(messages);
                }
            } else {
                this.failCount += 1;
                this.totalAjaxFailures += 1;
            }
        } catch (error: any) {
            if (error.name === 'AbortError') {
                abortedByClient = true;
            } else {
                this.failCount += 1;
                this.totalAjaxFailures += 1;
            }
        } finally {
            this.currentRequest = null;
            this.scheduleNextPoll(poll, { gotData, rateLimited, rateLimitedSeconds, abortedByClient });
        }
    }

    private async handleChunkedResponse(response: Response): Promise<void> {
        const reader = response.body!.getReader();
        const decoder = new TextDecoder();
        let buffer = '';
        let position = 0;

        try {
            while (true) {
                const { done, value } = await reader.read();
                if (done) break;

                buffer += decoder.decode(value, { stream: true });
                position = this.handleProgress(buffer, position);
            }
        } catch (error) {
            this.logError('Error reading chunked response:', error);
        }
    }

    private handleProgress(payload: string, position: number): number {
        const separator = "\r\n|\r\n";
        const endChunk = payload.indexOf(separator, position);

        if (endChunk === -1) {
            return position;
        }

        const chunk = payload.substring(position, endChunk);
        const cleanChunk = chunk.replace(/\r\n\|\|\r\n/g, separator);

        try {
            const messages: Message[] = JSON.parse(cleanChunk);
            this.reqSuccess(messages);
        } catch (e) {
            console.error('FAILED TO PARSE CHUNKED REPLY:', cleanChunk);
        }

        return this.handleProgress(payload, endChunk + separator.length);
    }

    private scheduleNextPoll(
        poll: () => void,
        { gotData, rateLimited, rateLimitedSeconds, abortedByClient }: {
            gotData: boolean;
            rateLimited: boolean;
            rateLimitedSeconds: number;
            abortedByClient: boolean;
        }
    ): void {
        const inLongPollingMode = this.shouldLongPoll();
        let startNextRequestAfter: number;

        try {
            if (rateLimited) {
                startNextRequestAfter = Math.max(this.minPollInterval, rateLimitedSeconds * 1000);
            } else if (abortedByClient) {
                startNextRequestAfter = this.minPollInterval;
            } else if (this.failCount > 2) {
                startNextRequestAfter = Math.min(
                    this.callbackInterval * this.failCount,
                    this.maxPollInterval
                );
            } else if (inLongPollingMode && gotData) {
                startNextRequestAfter = this.minPollInterval;
            } else {
                const targetRequestInterval = inLongPollingMode
                    ? this.callbackInterval
                    : this.backgroundCallbackInterval;

                const elapsedSinceLastAjaxStarted = this.lastAjaxStartedAt
                    ? new Date().getTime() - this.lastAjaxStartedAt.getTime()
                    : 0;

                startNextRequestAfter = targetRequestInterval - elapsedSinceLastAjaxStarted;
                if (startNextRequestAfter < 100) {
                    startNextRequestAfter = 100;
                }
            }
        } catch (e: any) {
            console.error('MESSAGE BUS FAIL:', e.message);
            startNextRequestAfter = this.callbackInterval;
        }

        if (this.pollTimeout) {
            clearTimeout(this.pollTimeout);
            this.pollTimeout = null;
        }

        if (this.started) {
            this.pollTimeout = setTimeout(() => {
                this.pollTimeout = null;
                poll();
            }, startNextRequestAfter) as any;
        }
    }

    private logInfo(...args: any[]) {
        console.log('[MessageBus]', ...args);
    }
    private logWarn(...args: any[]) {
        console.warn('[MessageBus]', ...args);
    }
    private logError(...args: any[]) {
        console.error('[MessageBus]', ...args);
    }

    public diagnostics(): void {
        this.logInfo(`Stopped: ${this.stopped} Started: ${this.started}`);
        this.logInfo('Current callbacks:', this.callbacks);
        this.logInfo(
            `Total ajax calls: ${this.totalAjaxCalls} Recent failure count: ${this.failCount} Total failures: ${this.totalAjaxFailures}`
        );
        if (this.lastAjaxStartedAt) {
            this.logInfo(
                `Last ajax call: ${(new Date().getTime() - this.lastAjaxStartedAt.getTime()) / 1000} seconds ago`
            );
        }
    }

    public pause(): void {
        this.paused = true;
        this.logWarn('Paused polling');
    }

    public resume(): void {
        this.paused = false;
        this.processMessages(this.later);
        this.later = [];
        this.logInfo('Resumed polling');
    }

    public stop(): void {
        this.stopped = true;
        this.started = false;

        if (this.delayPollTimeout) {
            clearTimeout(this.delayPollTimeout);
            this.delayPollTimeout = null;
        }

        if (this.pollTimeout) {
            clearTimeout(this.pollTimeout);
            this.pollTimeout = null;
        }

        if (this.currentRequest) {
            this.currentRequest.abort();
            this.currentRequest = null;
        }

        if (this.onVisibilityChange) {
            document?.removeEventListener("visibilitychange", this.onVisibilityChange);
            this.onVisibilityChange = null;
        }

        this.logWarn('Stopped polling');
    }

    public start(): void {
        if (this.started) return;
        this.logInfo('Started polling');

        this.started = true;
        this.stopped = false;

        const poll = (): void => {
            if (this.stopped) return;

            if (this.callbacks.length === 0 || this.hiddenTabShouldWait()) {
                if (!this.delayPollTimeout) {
                    this.delayPollTimeout = setTimeout(() => {
                        this.delayPollTimeout = null;
                        poll();
                    }, parseInt((500 + Math.random() * 500).toString())) as any;
                }
                return;
            }

            const data: Record<string, number> = {};
            for (const callback of this.callbacks) {
                data[callback.channel] = callback.last_id;
            }

            if (!this.currentRequest) {
                this.longPoller(poll, data);
            }
        };

        // Monitor visibility
        if (typeof document !== 'undefined' && document.addEventListener && 'hidden' in document) {
            this.onVisibilityChange = (): void => {
                if (
                    !document.hidden &&
                    !this.currentRequest &&
                    (this.pollTimeout || this.delayPollTimeout)
                ) {
                    if (this.pollTimeout) clearTimeout(this.pollTimeout);
                    if (this.delayPollTimeout) clearTimeout(this.delayPollTimeout);

                    this.delayPollTimeout = null;
                    this.pollTimeout = null;
                    poll();
                }
            };

            document.addEventListener("visibilitychange", this.onVisibilityChange);
        }

        poll();
    }

    public status(): MessageBusStatus {
        if (this.paused) return "paused";
        if (this.started) return "started";
        if (this.stopped) return "stopped";
        throw new Error("Cannot determine current status");
    }

    public subscribe(
        channel: string,
        func: (data: any, globalId?: number, messageId?: number) => void,
        lastId?: number
    ): (data: any, globalId?: number, messageId?: number) => void {
        if (!this.started && !this.stopped) {
            this.start();
        }

        if (lastId === null || lastId === undefined) {
            lastId = -1;
        } else if (typeof lastId !== "number") {
            throw new Error(`lastId has type ${typeof lastId} but a number was expected.`);
        }

        if (typeof channel !== "string") {
            throw new Error("Channel name must be a string!");
        }

        this.callbacks.push({
            channel,
            func,
            last_id: lastId,
        });

        this.logInfo(`Subscribed to channel '${channel}'`);

        if (this.currentRequest) {
            this.currentRequest.abort();
        }

        return func;
    }

    public unsubscribe(channel: string, func?: (data: any, globalId?: number, messageId?: number) => void): boolean {
        let glob = false;
        if (channel.endsWith("*")) {
            channel = channel.slice(0, -1);
            glob = true;
        }

        let removed = false;

        for (let i = this.callbacks.length - 1; i >= 0; i--) {
            const callback = this.callbacks[i];
            let keep: boolean;

            if (glob) {
                keep = !callback.channel.startsWith(channel);
            } else {
                keep = callback.channel !== channel;
            }

            if (!keep && func && callback.func !== func) {
                keep = true;
            }

            if (!keep) {
                this.callbacks.splice(i, 1);
                removed = true;
            }
        }

        if (removed) {
            this.logWarn(`Unsubscribed from channel '${channel}'`);
        }

        if (removed && this.currentRequest) {
            this.currentRequest.abort();
        }

        return removed;
    }
}

export const messageBus = new MessageBus({
    baseUrl: "/",
})