// MessageBus.ts

// ============================================================================
// TIPOS E INTERFACES
// ============================================================================

export interface Message {
    channel: string;
    data: any;
    global_id: number;
    message_id: number;
}

export interface Callback {
    channel: string;
    func: (data: any, globalId: number, messageId: number) => void;
    last_id: number;
}

export interface AjaxOptions {
    url: string;
    data: Record<string, any>;
    async: boolean;
    dataType: 'json' | 'text';
    type: 'POST' | 'GET';
    headers: Record<string, string>;
    messageBus: {
        chunked: boolean;
        onProgressListener: (xhr: XMLHttpRequest) => void;
    };
    xhr?: () => XMLHttpRequest;
    success: (response: any) => void;
    error: (xhr: XMLHttpRequest, textStatus: string) => void;
    complete: () => void;
}

export interface MessageBusConfig {
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
    ajax?: (options: AjaxOptions) => XMLHttpRequest;
    xhrImplementation?: typeof XMLHttpRequest;
}

export type MessageBusStatus = 'paused' | 'started' | 'stopped';

// ============================================================================
// UTILIDADES
// ============================================================================

/**
 * Genera un UUID v4 simplificado (compatible con el original)
 */
const generateUniqueId = (): string => {
    return 'xxxxxxxxxxxx4xxxyxxxxxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
        const r = (Math.random() * 16) | 0;
        const v = c === 'x' ? r : (r & 0x3) | 0x8;
        return v.toString(16);
    });
};

/**
 * Crea función para detectar si la pestaña está oculta
 */
const createIsHidden = (): (() => boolean) => {
    const prefixes = ['', 'webkit', 'ms', 'moz'] as const;
    let hiddenProperty: string | undefined;

    for (const prefix of prefixes) {
        const check = prefix + (prefix === '' ? 'hidden' : 'Hidden');
        if ((document as Record<string, any>)[check] !== undefined) {
            hiddenProperty = check;
            break;
        }
    }

    return () => {
        if (hiddenProperty) {
            return !!(document as Record<string, any>)[hiddenProperty];
        }
        return !document.hasFocus?.();
    };
};

/**
 * Detección segura de localStorage
 */
const hasLocalStorage = (() => {
    try {
        localStorage.setItem('mbTestLocalStorage', Date.now().toString());
        localStorage.removeItem('mbTestLocalStorage');
        return true;
    } catch {
        return false;
    }
})();

/**
 * Actualiza timestamp del último ajax en localStorage (coordinación entre tabs)
 */
const updateLastAjax = (): void => {
    if (hasLocalStorage) {
        localStorage.setItem('__mbLastAjax', Date.now().toString());
    }
};

// ============================================================================
// ADAPTADOR AJAX POR DEFECTO (Fallback sin jQuery)
// ============================================================================

export const createDefaultAjaxAdapter = (
    xhrImplementation?: typeof XMLHttpRequest
): ((options: AjaxOptions) => XMLHttpRequest) => {
    return (options: AjaxOptions): XMLHttpRequest => {
        const XHR = xhrImplementation ?? XMLHttpRequest;
        const xhr = new XHR();

        xhr.open(options.type, options.url, options.async);

        // Headers personalizados
        for (const [name, value] of Object.entries(options.headers)) {
            xhr.setRequestHeader(name, value);
        }
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');

        // Listener para chunked encoding
        if (options.messageBus.chunked) {
            options.messageBus.onProgressListener(xhr);
        }

        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4) {
                const { status } = xhr;
                const isSuccess = (status >= 200 && status < 300) || status === 304;

                if (isSuccess) {
                    options.success(xhr.responseText);
                } else {
                    options.error(xhr, xhr.statusText);
                }
                options.complete();
            }
        };

        xhr.send(new URLSearchParams(options.data).toString());
        return xhr;
    };
};

// ============================================================================
// CLASE PRINCIPAL: MessageBus
// ============================================================================

export class MessageBus {
    // ========================================================================
    // CONFIGURACIÓN PÚBLICA (con valores por defecto del original)
    // ========================================================================

    public minHiddenPollInterval = 1500;
    public enableChunkedEncoding = true;
    public enableLongPolling = true;
    public callbackInterval = 15000;
    public backgroundCallbackInterval = 60000;
    public minPollInterval = 100;
    public maxPollInterval = 3 * 60 * 1000; // 3 minutos
    public alwaysLongPoll = false;
    public shouldLongPollCallback?: () => boolean;
    public firstChunkTimeout = 3000;
    public retryChunkedAfterRequests = 30;
    public baseUrl = '/';
    public headers: Record<string, string> = {};
    public ajax?: (options: AjaxOptions) => XMLHttpRequest;
    public xhrImplementation?: typeof XMLHttpRequest;

    // ========================================================================
    // ESTADO INTERNO (privado)
    // ========================================================================

    private readonly _clientId: string;
    private readonly _callbacks: Callback[] = [];
    private readonly _isHidden: () => boolean;
    private readonly _hasProgressSupport: boolean;

    private _started = false;
    private _stopped = false;
    private _paused = false;
    private _ajaxInProgress = false;
    private _failCount = 0;
    private _chunkedBackoff = 0;
    private _pollTimeout: ReturnType<typeof setTimeout> | null = null;
    private _delayPollTimeout: ReturnType<typeof setTimeout> | null = null;
    private _longPoll: XMLHttpRequest | null = null;
    private _later: Message[] = [];
    private _totalAjaxFailures = 0;
    private _totalAjaxCalls = 0;
    private _lastAjaxStartedAt: Date | null = null;
    private _onVisibilityChange: (() => void) | null = null;

    // ========================================================================
    // CONSTRUCTOR
    // ========================================================================

    constructor(config?: Partial<MessageBusConfig>) {
        this._clientId = generateUniqueId();
        this._isHidden = createIsHidden();
        this._hasProgressSupport = new XMLHttpRequest().onprogress === null;

        // Aplicar configuración personalizada
        if (config) {
            this.configure(config);
        }

        // Establecer adapter AJAX por defecto si no se proporciona
        this.ajax ??= createDefaultAjaxAdapter(this.xhrImplementation);
    }

    // ========================================================================
    // MÉTODOS PRIVADOS - LÓGICA INTERNA
    // ========================================================================

    /**
     * Aplica configuración parcial manteniendo valores por defecto
     */
    private configure(config: Partial<MessageBusConfig>): void {
        Object.assign(this, config);
    }

    /**
     * Verifica si una pestaña oculta debe esperar antes de pollear
     */
    private hiddenTabShouldWait(): boolean {
        if (hasLocalStorage && this._isHidden()) {
            const lastAjaxCall = parseInt(localStorage.getItem('__mbLastAjax') ?? '0', 10);
            const deltaAjax = Date.now() - lastAjaxCall;
            return deltaAjax >= 0 && deltaAjax < this.minHiddenPollInterval;
        }
        return false;
    }

    /**
     * Determina si se permite encoding chunked
     */
    private allowChunked(): boolean {
        return this.enableChunkedEncoding && this._hasProgressSupport;
    }

    /**
     * Determina si se debe usar long polling
     */
    private shouldLongPoll(): boolean {
        return (
            this.alwaysLongPoll ||
            (this.shouldLongPollCallback?.() ?? !this._isHidden())
        );
    }

    /**
     * Procesa mensajes entrantes e invoca callbacks registrados
     */
    private processMessages(messages: Message[]): boolean {
        if (!messages?.length) return false;

        for (const message of messages) {
            for (const callback of this._callbacks) {
                // Matching por canal
                if (callback.channel === message.channel) {
                    callback.last_id = message.message_id;
                    try {
                        callback.func(message.data, message.global_id, message.message_id);
                    } catch (error) {
                        console?.log?.(
                            `MESSAGE BUS FAIL: callback ${callback.channel} caused exception ${(error as Error).stack}`
                        );
                    }
                }
                // Manejo especial para canal de estado
                if (message.channel === '/__status') {
                    const statusData = message.data as Record<string, number>;
                    if (statusData[callback.channel] !== undefined) {
                        callback.last_id = statusData[callback.channel];
                    }
                }
            }
        }
        return true;
    }

    /**
     * Maneja respuesta exitosa del servidor
     */
    private handleSuccess(messages?: Message[]): boolean {
        this._failCount = 0;

        if (this._paused) {
            // En pausa: encolar mensajes para procesar después
            if (messages?.length) {
                this._later.push(...messages);
            }
            return false;
        }

        return this.processMessages(messages ?? []);
    }

    /**
     * Función principal de long polling
     */
    private longPoller(poll: () => void, data: Record<string, number>): XMLHttpRequest | undefined {
        if (this._ajaxInProgress) return; // Prevenir requests AJAX concurrentes

        let gotData = false;
        let abortedByClient = false;
        let rateLimited = false;
        let rateLimitedSeconds = 0;

        // Tracking de métricas
        this._lastAjaxStartedAt = new Date();
        this._totalAjaxCalls += 1;
        data.__seq = this._totalAjaxCalls;

        // Determinar modo de conexión
        const longPoll = this.shouldLongPoll() && this.enableLongPolling;
        let chunked = longPoll && this.allowChunked();

        if (this._chunkedBackoff > 0) {
            this._chunkedBackoff--;
            chunked = false;
        }

        // Preparar headers
        const headers: Record<string, string> = {
            'X-SILENCE-LOGGER': 'true',
            ...this.headers
        };

        if (!chunked) {
            headers['Dont-Chunk'] = 'true';
        }

        const dataType: 'json' | 'text' = chunked ? 'text' : 'json';
        let position = 0;

        // Parser para respuestas chunked
        const handleProgress = (payload: string, pos: number): number => {
            const separator = '\r\n|\r\n';
            const endChunk = payload.indexOf(separator, pos);

            if (endChunk === -1) return pos;

            let chunk = payload.substring(pos, endChunk);
            // Normalizar separadores dobles
            chunk = chunk.replace(/\r\n\|\|\r\n/g, separator);

            try {
                this.handleSuccess(JSON.parse(chunk));
            } catch {
                console?.log?.('FAILED TO PARSE CHUNKED REPLY', data);
            }

            return handleProgress(payload, endChunk + separator.length);
        };

        let chunkedTimeout: ReturnType<typeof setTimeout> | undefined;

        const disableChunked = () => {
            if (this._longPoll) {
                this._longPoll.abort();
                this._chunkedBackoff = this.retryChunkedAfterRequests;
            }
        };

        if (!this.ajax) {
            throw new Error('Either jQuery or the ajax adapter must be loaded');
        }

        updateLastAjax();
        this._ajaxInProgress = true;

        return this.ajax({
            url: `${this.baseUrl}message-bus/${this._clientId}/poll${!longPoll ? '?dlp=t' : ''}`,
            data,
            async: true,
            dataType,
            type: 'POST',
            headers,
            messageBus: {
                chunked,
                onProgressListener: (xhr: XMLHttpRequest) => {
                    position = 0;
                    // Timeout para detectar proxies que bufferizan
                    chunkedTimeout = setTimeout(disableChunked, this.firstChunkTimeout);

                    xhr.onprogress = () => {
                        clearTimeout(chunkedTimeout);
                        const contentType = xhr.getResponseHeader('Content-Type');
                        if (contentType === 'application/json; charset=utf-8') {
                            chunked = false; // Respuesta JSON completa, no chunked
                        } else {
                            position = handleProgress(xhr.responseText, position);
                        }
                    };
                },
            },
            xhr: () => {
                const xhr = new (this.xhrImplementation ?? XMLHttpRequest)();
                return xhr;
            },
            success: (response: any) => {
                if (!chunked) {
                    const messages = typeof response === 'string' ? JSON.parse(response) : response;
                    gotData = this.handleSuccess(messages);
                }
            },
            error: (xhr: XMLHttpRequest, textStatus: string) => {
                clearTimeout(chunkedTimeout);

                if (xhr.status === 429) {
                    // Rate limiting: respetar header Retry-After
                    const retryAfter = parseInt(xhr.getResponseHeader('Retry-After') ?? '0', 10);
                    rateLimitedSeconds = Math.max(retryAfter, 15);
                    rateLimited = true;
                } else if (textStatus === 'abort') {
                    abortedByClient = true;
                } else {
                    this._failCount += 1;
                    this._totalAjaxFailures += 1;
                }
            },
            complete: () => {
                this._ajaxInProgress = false;

                const inLongPollingMode = this.shouldLongPoll();
                // Inicializar con un valor por defecto seguro
                let startNextRequestAfter: number = this.minPollInterval;

                try {
                    if (rateLimited) {
                        startNextRequestAfter = Math.max(
                            this.minPollInterval,
                            rateLimitedSeconds * 1000
                        );
                    } else if (abortedByClient) {
                        startNextRequestAfter = this.minPollInterval;
                    } else if (this._failCount > 2) {
                        // Backoff lineal en caso de fallos
                        startNextRequestAfter = Math.min(
                            this.callbackInterval * this._failCount,
                            this.maxPollInterval
                        );
                    } else if (inLongPollingMode && gotData) {
                        // Datos recibidos: poll inmediato
                        startNextRequestAfter = this.minPollInterval;
                    } else {
                        // Intervalo normal basado en tiempo transcurrido
                        const targetInterval = inLongPollingMode
                            ? this.callbackInterval
                            : this.backgroundCallbackInterval;

                        const elapsed = this._lastAjaxStartedAt
                            ? Date.now() - this._lastAjaxStartedAt.getTime()
                            : 0;

                        startNextRequestAfter = Math.max(100, targetInterval - elapsed);
                    }
                } catch (error) {
                    console?.log?.(`MESSAGE BUS FAIL: ${(error as Error).message}`);
                }

                // Limpiar timeout anterior
                if (this._pollTimeout) {
                    clearTimeout(this._pollTimeout);
                    this._pollTimeout = null;
                }

                // Programar próximo poll si está iniciado
                if (this._started) {
                    this._pollTimeout = setTimeout(() => {
                        this._pollTimeout = null;
                        poll();
                    }, startNextRequestAfter);
                }

                this._longPoll = null;
            },
        });
    }

    /**
     * Crea la función de polling principal
     */
    private createPollFunction(): () => void {
        return () => {
            if (this._stopped) return;

            // Esperar si no hay callbacks o la tab está oculta recientemente
            if (this._callbacks.length === 0 || this.hiddenTabShouldWait()) {
                if (!this._delayPollTimeout) {
                    this._delayPollTimeout = setTimeout(() => {
                        this._delayPollTimeout = null;
                        this.createPollFunction()();
                    }, 500 + Math.random() * 500);
                }
                return;
            }

            // Preparar datos de subscripciones
            const data: Record<string, number> = {};
            for (const cb of this._callbacks) {
                data[cb.channel] = cb.last_id;
            }

            // Iniciar long poll si no hay uno activo
            if (!this._longPoll) {
                this._longPoll = this.longPoller(this.createPollFunction(), data) ?? null;
            }
        };
    }

    // ========================================================================
    // API PÚBLICA - MÉTODOS PRINCIPALES
    // ========================================================================

    /**
     * Inicia el polling de mensajes
     */
    public start(): void {
        if (this._started) return;

        this._started = true;
        this._stopped = false;

        const poll = this.createPollFunction();

        // Escuchar cambios de visibilidad para reanudar polling
        if (document.addEventListener && 'hidden' in document) {
            this._onVisibilityChange = () => {
                if (
                    !document.hidden &&
                    !this._longPoll &&
                    (this._pollTimeout || this._delayPollTimeout)
                ) {
                    [this._pollTimeout, this._delayPollTimeout].forEach((t) => {
                        if (t) clearTimeout(t);
                    });
                    this._pollTimeout = null;
                    this._delayPollTimeout = null;
                    poll();
                }
            };
            document.addEventListener('visibilitychange', this._onVisibilityChange);
        }

        poll();
    }

    /**
     * Detiene todo polling y limpia recursos
     */
    public stop(): void {
        this._stopped = true;
        this._started = false;

        // Limpiar timeouts
        [this._delayPollTimeout, this._pollTimeout].forEach((t) => {
            if (t) clearTimeout(t);
        });
        this._delayPollTimeout = null;
        this._pollTimeout = null;

        // Abortar request activo
        if (this._longPoll) {
            this._longPoll.abort();
            this._longPoll = null;
        }

        // Remover listener de visibilidad
        if (this._onVisibilityChange) {
            document.removeEventListener('visibilitychange', this._onVisibilityChange);
            this._onVisibilityChange = null;
        }
    }

    /**
     * Pausa el procesamiento de mensajes (se encolan)
     */
    public pause(): void {
        this._paused = true;
    }

    /**
     * Reanuda el procesamiento y despacha mensajes encolados
     */
    public resume(): void {
        this._paused = false;
        if (this._later.length) {
            this.processMessages(this._later);
            this._later = [];
        }
    }

    /**
     * Subscribirse a un canal
     * @param channel - Nombre del canal (string)
     * @param func - Callback a ejecutar al recibir mensaje
     * @param lastId - ID desde donde recibir mensajes:
     *   - `-1`: solo mensajes nuevos (default)
     *   - `-2`: último mensaje + nuevos
     *   - `-N`: últimos N-1 mensajes + nuevos
     *   - `>=0`: mensajes después de ese ID
     * @returns La función callback registrada
     */
    public subscribe(
        channel: string,
        func: (data: any, globalId: number, messageId: number) => void,
        lastId?: number
    ): typeof func {
        // Auto-start si no está detenido explícitamente
        if (!this._started && !this._stopped) {
            this.start();
        }

        // Validar y normalizar lastId
        if (lastId == null) {
            lastId = -1;
        } else if (typeof lastId !== 'number') {
            throw new TypeError(`lastId has type ${typeof lastId} but a number was expected.`);
        }

        if (typeof channel !== 'string') {
            throw new TypeError('Channel name must be a string!');
        }

        // Registrar callback
        this._callbacks.push({ channel, func, last_id: lastId });

        // Abortar poll activo para aplicar nueva subscripción inmediatamente
        if (this._longPoll) {
            this._longPoll.abort();
            this._longPoll = null;
        }

        return func;
    }

    /**
     * Cancelar subscripción de un canal
     * @param channel - Nombre del canal o patrón glob (ej: '/channel/*')
     * @param func - (Opcional) Callback específico a remover
     * @returns `true` si se removió al menos un callback
     */
    public unsubscribe(
        channel: string,
        func?: (data: any, globalId: number, messageId: number) => void
    ): boolean {
        // Soporte para globbing en sufijo: '/channel/*'
        let glob = false;
        if (channel.endsWith('*')) {
            channel = channel.slice(0, -1);
            glob = true;
        }

        let removed = false;

        // Iterar en reversa para splice seguro
        for (let i = this._callbacks.length - 1; i >= 0; i--) {
            const cb = this._callbacks[i];
            let shouldKeep: boolean;

            if (glob) {
                // Matching por prefijo para globs
                shouldKeep = !cb.channel.startsWith(channel);
            } else {
                // Matching exacto
                shouldKeep = cb.channel !== channel;
            }

            // Si se especificó func, solo remover si coincide
            if (!shouldKeep && func && cb.func !== func) {
                shouldKeep = true;
            }

            if (!shouldKeep) {
                this._callbacks.splice(i, 1);
                removed = true;
            }
        }

        // Abortar poll si se modificaron callbacks
        if (removed && this._longPoll) {
            this._longPoll.abort();
            this._longPoll = null;
        }

        return removed;
    }

    /**
     * Obtener estado actual del MessageBus
     */
    public status(): MessageBusStatus {
        if (this._paused) return 'paused';
        if (this._started) return 'started';
        if (this._stopped) return 'stopped';
        throw new Error('Cannot determine current status');
    }

    /**
     * Imprimir información de diagnóstico en consola
     */
    public diagnostics(): void {
        console.log(`Stopped: ${this._stopped} Started: ${this._started}`);
        console.log('Current callbacks:', this._callbacks);
        console.log(
            `Total ajax calls: ${this._totalAjaxCalls} | ` +
            `Recent failures: ${this._failCount} | ` +
            `Total failures: ${this._totalAjaxFailures}`
        );
        console.log(
            `Last ajax call: ${this._lastAjaxStartedAt
                ? ((Date.now() - this._lastAjaxStartedAt.getTime()) / 1000).toFixed(2)
                : 'never'
            } seconds ago`
        );
    }

    // ========================================================================
    // GETTERS PÚBLICOS (solo lectura)
    // ========================================================================

    /**
     * ID único del cliente (generado al instanciar)
     */
    public get clientId(): string {
        return this._clientId;
    }

    /**
     * Copia de solo lectura de callbacks registrados
     */
    public get callbacks(): ReadonlyArray<Callback> {
        return [...this._callbacks];
    }

    /**
     * Contador total de llamadas AJAX realizadas
     */
    public get totalAjaxCalls(): number {
        return this._totalAjaxCalls;
    }

    /**
     * Contador total de fallos AJAX
     */
    public get totalAjaxFailures(): number {
        return this._totalAjaxFailures;
    }
}

// ============================================================================
// EXPORTS PARA COMPATIBILIDAD (UMD-style)
// ============================================================================

// Export por defecto para ES Modules
export default MessageBus;

// Registro global para compatibilidad con scripts legacy
if (typeof window !== 'undefined') {
    (window as Record<string, any>).MessageBus = new MessageBus();
}