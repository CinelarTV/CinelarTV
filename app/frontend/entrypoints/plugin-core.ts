/**
 * Populates window.CinelarTV with core modules so third-party plugins
 * can import them at runtime (externalized by vite.config.plugins.ts).
 *
 * This entry point is loaded as a module script BEFORE boot-cinelartv.ts
 * and BEFORE any third-party plugin <script type="module"> tags.
 *
 * Module scripts execute in document order, so this runs first.
 */

import * as Vue from "vue";
import * as VueRouter from "vue-router";
import * as Pinia from "pinia";
import axios from "axios";
import pluginEvents from "../webclient/lib/plugin-events";
import * as siteSettings from "../webclient/app/services/site-settings";
import * as pluginOutlet from "../webclient/components/PluginOutlet";
import * as pluginOutlets from "../webclient/stores/pluginOutlets";

const CT = (window.CinelarTV = window.CinelarTV || ({} as any));

CT.Vue = Vue;
CT.VueRouter = VueRouter;
CT.Pinia = Pinia;
CT.axios = axios;
CT.PluginEvents = pluginEvents.default || pluginEvents;
CT.SiteSettings = siteSettings;
CT.PluginOutlet = pluginOutlet;
CT.PluginOutlets = pluginOutlets;

console.log("🔌 CinelarTV core modules loaded for plugins");
