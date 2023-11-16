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
    Logster?: {
      enabled: boolean;
    };
  }
}

let lastReport: Date | null = null;

console.log("Logster enabled: " + siteSettings.enable_js_error_reporting);

if (!window.Logster) {
  window.Logster = {
    enabled: !!siteSettings.enable_js_error_reporting,
  };
}

if (!window.Logster.enabled) {
  if (process.env.NODE_ENV === 'development') {
    console.warn("DEV: JS error reporting is disabled.\nThis message is only shown in development mode.");
  }
}

console.log(siteSettings)


export const reportError = (err: Error, severity: string): void => {
  if (!err) return;

  if (lastReport && new Date().getTime() - lastReport.getTime() < 1000 * 60) {
    return;
  }

  lastReport = new Date();

  const reportData: ErrorReportData = {
    message: err.message ? err.message : err + "",
    url: AppRouter.currentRoute.value.fullPath,
    window_location: window.location && (window.location + ""),
    stacktrace: err.stack ? err.stack : err.message ? err.message : err + "",
    // error object doesn't have column and line properties, maybe it's possible to get them from the stacktrace?
    column: 0,
    line: 0,
    severity,
  };

  const stacktraceMatches = /(?:at\s.*?[(@])(.*):(\d+):(\d+)/.exec(err.stack || "");
  if (stacktraceMatches && stacktraceMatches.length === 4) {
    reportData.column = parseInt(stacktraceMatches[3], 10);
    reportData.line = parseInt(stacktraceMatches[2], 10);
  }

  if (!siteSettings.enable_js_error_reporting) {
    return;
  }

  if (severity === 'error') {
    console.error(err);
  } else {
    console.warn(err);
  }

  ajax.post("/logs/report_js_error", reportData).catch(() => {
    // Do nothing, we don't want to report errors about reporting errors
  });
};

export default {
  install: (app: any): void => {
    app.config.errorHandler = (err: Error, vm: any, info: string): void => {
      reportError(err, 'error');
    };

    app.config.warnHandler = (err: Error, vm: any, info: string): void => {
      reportError(err, 'warning');
    };
  },
};
