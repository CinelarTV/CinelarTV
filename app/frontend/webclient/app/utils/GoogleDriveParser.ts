/* 
    * Google Drive Parser
    * This parser extracts video information from Google Drive links
    * to allow playback of videos hosted on Google Drive.
*/

import { useSiteSettings } from "../services/site-settings";

const { siteSettings } = useSiteSettings();

/* Extracted from https://github.com/SH20RAJ/DrivePlyr/blob/main/script.js */
const GOOGLE_DRIVE_API_KEY = "AIzaSyD739-eb6NzS_KbVJq1K8ZAxnrMfkIqPyw";

export function getGoogleDriveVideoInfo(url: string) {
    if (!siteSettings?.enable_google_drive_parser) return null;
    const match = url.match(/[-\w]{25,}/);
    const id = match ? match[0] : null;
    if (!id) return null;
    return {
        id,
        videourl: `https://www.googleapis.com/drive/v3/files/${id}?alt=media&key=${GOOGLE_DRIVE_API_KEY}`,
        poster: `https://lh3.googleusercontent.com/d/${id}`
    };
}