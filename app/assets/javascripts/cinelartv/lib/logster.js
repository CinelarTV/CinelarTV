/* This handler will report JavaScript errors to
Logster gem, so they are accessible from "/logs" */

import AppRouter from "../routes/router-map";
import { SiteSettings } from "../pre-initializers/essentials-preload";
import { ajax } from "./axios-setup";

var lastReport = null;

if (!window.Logster) {
    window.Logster = {
        enabled: SiteSettings.enable_js_error_reporting
    };
}

if (!Logster.enabled) {
    if (process.env.NODE_ENV === 'development') {
        console.warn("DEV: JS error reporting is disabled.\nThis message is only shown in development mode.");
    }
}


export const reportError = (err, severity) => {
    if (!err) return;

    if (lastReport && new Date() - lastReport < 1000 * 60) {
        return;
    }


    lastReport = new Date();

    let reportData = {
        message: err.message ? err.message : err + "",
        url: AppRouter.currentRoute.value.fullPath,
        window_location: window.location && (window.location + ""),
        stacktrace: err.stack ? err.stack : err.message ? err.message : err + "",
        column: err.column || err.columnNumber ? err.column || err.columnNumber : null,
        line: err.line || err.lineNumber ? err.line || err.lineNumber : null,
        severity,
    }

    if (!SiteSettings.enable_js_error_reporting) {
        return;
    }

    if (severity === 'error') {
        console.error(err)
    } else {
        console.warn(err)
    }

    ajax.post("/logs/report_js_error",
        reportData
    ).catch(err => {
        // Do nothing, we don't want to report errors about reporting errors
    });
}



export default {
    install: (app) => {
        app.config.errorHandler = function (err, vm, info) {
            reportError(err, 'error')
        };

        app.config.warnHandler = function (err, vm, info) {
            reportError(err, 'warning')
        };

    }
};