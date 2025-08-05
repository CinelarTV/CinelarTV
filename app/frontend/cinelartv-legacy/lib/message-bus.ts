import 'message-bus-client';

// Una implementación básica de ajax usando fetch para MessageBus
// Solo implementa los métodos y opciones usados por MessageBus

type AjaxOptions = {
    url: string;
    data: Record<string, any>;
    dataType?: string;
    headers?: Record<string, string>;
    messageBus: any;
    success: (response: string) => void;
    error: (xhr: any, statusText: string) => void;
    complete: () => void;
};

(function (global: any) {
    'use strict';
    if (!global.MessageBus) {
        throw new Error('MessageBus must be loaded before the ajax adapter');
    }

    global.MessageBus.ajax = async function (options: AjaxOptions) {
        const headers = {
            'Content-Type': 'application/x-www-form-urlencoded',
            ...(options.headers || {})
        };
        let controller: AbortController | undefined;
        let signal: AbortSignal | undefined;
        if (options.messageBus.chunked && options.messageBus.onProgressListener) {
            controller = new AbortController();
            signal = controller.signal;
        }
        try {
            const response = await fetch(options.url, {
                method: 'POST',
                headers,
                body: new URLSearchParams(options.data).toString(),
                signal
            });
            if (response.ok) {
                if (options.messageBus.chunked && options.messageBus.onProgressListener && response.body) {
                    // Soporte para onProgress usando streams
                    const reader = response.body.getReader();
                    const decoder = new TextDecoder();
                    let result = '';
                    let done = false;
                    while (!done) {
                        const { value, done: streamDone } = await reader.read();
                        if (value) {
                            const chunk = decoder.decode(value, { stream: true });
                            result += chunk;
                            options.messageBus.onProgressListener({
                                responseText: result,
                                chunk
                            });
                        }
                        done = streamDone;
                    }
                    options.success(result);
                } else {
                    const text = await response.text();
                    options.success(text);
                }
            } else {
                options.error(response, response.statusText);
            }
        } catch (err: any) {
            options.error(err, err.message);
        } finally {
            options.complete();
        }
    };
})(window);
