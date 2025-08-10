import AppRouter from "../routes/router-map";
import { useSiteSettings } from "../app/services/site-settings";
import { ajax } from "./Ajax";
import { PiniaStore } from "../app/lib/Pinia";

const { siteSettings } = useSiteSettings(PiniaStore);


interface ErrorReportData {
  message: string;
  url: string;
  window_location: string;
  stacktrace: string;
  column: number;
  line: number;
  severity: string;
}

declare global {
  interface Window {
    Logster?: { enabled: boolean };
  }
}

let lastReport: number = 0;

if (!window.Logster) {
  window.Logster = { enabled: !!siteSettings?.enable_js_error_reporting };
}

if (!window.Logster.enabled && process.env.NODE_ENV === 'development') {
  console.warn("DEV: JS error reporting is disabled.\nThis message is only shown in development mode.");
}

export const reportError = (err: Error, severity: 'error' | 'warning'): void => {
  if (!err) return;
  const now = Date.now();

  // Mostrar SIEMPRE por consola
  severity === 'error' ? console.error(err) : console.warn(err);

  // Solo enviar por ajax si han pasado 30s
  if (lastReport && now - lastReport < 30_000) return;
  lastReport = now;

  const stack = err.stack || err.message || String(err);
  const stacktraceMatches = /(?:at\s.*?[(@])(.*):(\d+):(\d+)/.exec(stack);
  const column = stacktraceMatches ? parseInt(stacktraceMatches[3], 10) : 0;
  const line = stacktraceMatches ? parseInt(stacktraceMatches[2], 10) : 0;

  const reportData: ErrorReportData = {
    message: err.message || String(err),
    url: AppRouter.currentRoute.value.fullPath,
    window_location: String(window.location),
    stacktrace: stack,
    column,
    line,
    severity,
  };

  if (!siteSettings?.enable_js_error_reporting) return;

  ajax.post("/logs/report_js_error", reportData).catch(() => { });
};

export default {
  install: (app: any): void => {
    app.config.errorHandler = (err: Error) => reportError(err, 'error');
    app.config.warnHandler = (err: Error) => reportError(err, 'warning');
  },
};
