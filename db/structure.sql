\restrict fpmnxB5dxOQYHdjcOF6JEcgRgUSpauwxzPvM0K586zgCYwmutfNcTFK8ykCSm4M

-- Dumped from database version 15.18
-- Dumped by pg_dump version 15.18

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: intarray; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS intarray WITH SCHEMA public;


--
-- Name: EXTENSION intarray; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION intarray IS 'functions, operators, and index support for 1-D arrays of integers';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: immutable_unaccent(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.immutable_unaccent(text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT unaccent('unaccent', $1)
$_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    user_id uuid,
    action integer NOT NULL,
    custom_type character varying(100),
    auditable_type character varying,
    auditable_id bigint,
    target_user_id uuid,
    subject character varying(255),
    previous_value text,
    new_value text,
    details text,
    ip_address character varying(45),
    request_id character varying(36),
    context character varying(500),
    source character varying(100) DEFAULT 'core'::character varying NOT NULL,
    result character varying(20) DEFAULT 'success'::character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: backups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.backups (
    id bigint NOT NULL,
    filename character varying NOT NULL,
    size bigint,
    backup_type character varying,
    source character varying,
    notes text,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    checksum character varying,
    encrypted boolean DEFAULT false NOT NULL,
    encryption_key_fingerprint text,
    file_manifest jsonb DEFAULT '{}'::jsonb,
    audit_log jsonb DEFAULT '[]'::jsonb,
    completed_at timestamp(6) without time zone,
    expires_at timestamp(6) without time zone,
    retention_days integer DEFAULT 30,
    error_message character varying
);


--
-- Name: backups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.backups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: backups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.backups_id_seq OWNED BY public.backups.id;


--
-- Name: cast_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cast_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    content_id uuid NOT NULL,
    person_id uuid NOT NULL,
    character_name character varying,
    "order" integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id bigint NOT NULL,
    name character varying,
    description character varying,
    image character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tmdb_id integer
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: cinelar_ads_ad_impressions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cinelar_ads_ad_impressions (
    id bigint NOT NULL,
    ad_type character varying NOT NULL,
    placement character varying NOT NULL,
    house_ad_id bigint,
    user_id uuid,
    ip_address character varying,
    clicked_at timestamp(6) without time zone,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: cinelar_ads_ad_impressions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cinelar_ads_ad_impressions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cinelar_ads_ad_impressions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cinelar_ads_ad_impressions_id_seq OWNED BY public.cinelar_ads_ad_impressions.id;


--
-- Name: cinelar_ads_house_ad_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cinelar_ads_house_ad_categories (
    id bigint NOT NULL,
    house_ad_id bigint NOT NULL,
    category_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: cinelar_ads_house_ad_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cinelar_ads_house_ad_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cinelar_ads_house_ad_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cinelar_ads_house_ad_categories_id_seq OWNED BY public.cinelar_ads_house_ad_categories.id;


--
-- Name: cinelar_ads_house_ad_content_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cinelar_ads_house_ad_content_types (
    id bigint NOT NULL,
    house_ad_id bigint NOT NULL,
    content_type character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: cinelar_ads_house_ad_content_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cinelar_ads_house_ad_content_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cinelar_ads_house_ad_content_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cinelar_ads_house_ad_content_types_id_seq OWNED BY public.cinelar_ads_house_ad_content_types.id;


--
-- Name: cinelar_ads_house_ad_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cinelar_ads_house_ad_settings (
    id bigint NOT NULL,
    slot character varying NOT NULL,
    ad_names text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: cinelar_ads_house_ad_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cinelar_ads_house_ad_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cinelar_ads_house_ad_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cinelar_ads_house_ad_settings_id_seq OWNED BY public.cinelar_ads_house_ad_settings.id;


--
-- Name: cinelar_ads_house_ads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cinelar_ads_house_ads (
    id bigint NOT NULL,
    name character varying NOT NULL,
    html text NOT NULL,
    visible_to_anons boolean DEFAULT true NOT NULL,
    visible_to_logged_in_users boolean DEFAULT true NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: cinelar_ads_house_ads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cinelar_ads_house_ads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cinelar_ads_house_ads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cinelar_ads_house_ads_id_seq OWNED BY public.cinelar_ads_house_ads.id;


--
-- Name: content_analytics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_analytics (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    content_id uuid NOT NULL,
    total_views integer DEFAULT 0 NOT NULL,
    total_seconds_watched double precision DEFAULT 0.0 NOT NULL,
    unique_profiles integer DEFAULT 0 NOT NULL,
    completion_rate double precision DEFAULT 0.0 NOT NULL,
    avg_watch_percentage double precision DEFAULT 0.0 NOT NULL,
    last_watched_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: content_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_categories (
    id bigint NOT NULL,
    content_id uuid NOT NULL,
    category_id integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: content_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.content_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.content_categories_id_seq OWNED BY public.content_categories.id;


--
-- Name: content_content_descriptors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_content_descriptors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    content_id uuid NOT NULL,
    content_descriptor_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: content_descriptors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_descriptors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    key character varying NOT NULL,
    name_translations jsonb DEFAULT '{}'::jsonb,
    description_translations jsonb DEFAULT '{}'::jsonb,
    category character varying NOT NULL,
    severity_level integer DEFAULT 1,
    active boolean DEFAULT true,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: content_ratings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_ratings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying NOT NULL,
    system character varying NOT NULL,
    name_translations jsonb DEFAULT '{}'::jsonb,
    description_translations jsonb DEFAULT '{}'::jsonb,
    min_age integer,
    color character varying DEFAULT '#ffffff'::character varying,
    active boolean DEFAULT true,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: contents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying,
    description character varying,
    banner character varying,
    cover character varying,
    content_type character varying,
    year integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    trailer_url character varying,
    available boolean DEFAULT true,
    premium boolean DEFAULT false,
    tmdb_id integer,
    banner_resized character varying,
    cover_resized character varying,
    scheduled_launch_at timestamp(6) without time zone,
    search_data tsvector,
    content_rating_id uuid,
    content_rating_code character varying
);


--
-- Name: continue_watchings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.continue_watchings (
    id bigint NOT NULL,
    profile_id uuid NOT NULL,
    content_id uuid NOT NULL,
    episode_id uuid,
    progress double precision DEFAULT 0 NOT NULL,
    duration double precision DEFAULT 0 NOT NULL,
    last_watched_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    finished boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: continue_watchings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.continue_watchings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: continue_watchings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.continue_watchings_id_seq OWNED BY public.continue_watchings.id;


--
-- Name: custom_pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_pages (
    id bigint NOT NULL,
    title character varying,
    slug character varying,
    template text,
    metadata json,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: custom_pages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_pages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_pages_id_seq OWNED BY public.custom_pages.id;


--
-- Name: dislikes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dislikes (
    id bigint NOT NULL,
    profile_id uuid,
    content_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: dislikes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dislikes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dislikes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dislikes_id_seq OWNED BY public.dislikes.id;


--
-- Name: email_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_templates (
    id bigint NOT NULL,
    key character varying NOT NULL,
    locale character varying NOT NULL,
    subject text,
    body text,
    interpolation_variables jsonb DEFAULT '[]'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: email_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_templates_id_seq OWNED BY public.email_templates.id;


--
-- Name: episode_content_descriptors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.episode_content_descriptors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    episode_id uuid NOT NULL,
    content_descriptor_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: episodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.episodes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying,
    description character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    "position" integer,
    thumbnail character varying,
    premium boolean DEFAULT false,
    thumbnail_resized character varying,
    season_id uuid NOT NULL,
    tmdb_id integer,
    content_rating_id uuid,
    content_rating_code character varying
);


--
-- Name: image_variants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.image_variants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    imageable_type character varying NOT NULL,
    image_type character varying NOT NULL,
    variant character varying NOT NULL,
    format character varying NOT NULL,
    url character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    imageable_id uuid NOT NULL
);


--
-- Name: likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.likes (
    id bigint NOT NULL,
    profile_id uuid,
    content_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: likes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.likes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: likes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.likes_id_seq OWNED BY public.likes.id;


--
-- Name: live_chat_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.live_chat_messages (
    id bigint NOT NULL,
    live_event_id bigint NOT NULL,
    profile_id uuid NOT NULL,
    message_type character varying DEFAULT 'user'::character varying NOT NULL,
    body text,
    deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp(6) without time zone,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: live_chat_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.live_chat_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: live_chat_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.live_chat_messages_id_seq OWNED BY public.live_chat_messages.id;


--
-- Name: live_event_attendees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.live_event_attendees (
    id bigint NOT NULL,
    live_event_id bigint NOT NULL,
    profile_id uuid NOT NULL,
    notified_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: live_event_attendees_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.live_event_attendees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: live_event_attendees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.live_event_attendees_id_seq OWNED BY public.live_event_attendees.id;


--
-- Name: live_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.live_events (
    id bigint NOT NULL,
    content_id uuid NOT NULL,
    organizer_id uuid NOT NULL,
    title character varying,
    description text,
    starts_at timestamp(6) without time zone NOT NULL,
    estimated_end_at timestamp(6) without time zone,
    status integer DEFAULT 0 NOT NULL,
    max_participants integer,
    is_public boolean DEFAULT true NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: live_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.live_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: live_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.live_events_id_seq OWNED BY public.live_events.id;


--
-- Name: live_tv_channels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.live_tv_channels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    description text,
    logo_url character varying,
    stream_url character varying NOT NULL,
    stream_format character varying DEFAULT 'hls'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    "position" integer DEFAULT 0,
    xmltv_channel_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: oauth_access_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_grants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    resource_owner_id uuid NOT NULL,
    application_id uuid NOT NULL,
    token character varying NOT NULL,
    expires_in integer NOT NULL,
    redirect_uri text NOT NULL,
    scopes character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    revoked_at timestamp(6) without time zone
);


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    resource_owner_id uuid,
    application_id uuid,
    token character varying NOT NULL,
    refresh_token character varying,
    expires_in integer,
    scopes character varying,
    created_at timestamp(6) without time zone NOT NULL,
    revoked_at timestamp(6) without time zone,
    previous_refresh_token character varying DEFAULT ''::character varying NOT NULL,
    current_profile_id uuid
);


--
-- Name: oauth_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_applications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    uid character varying NOT NULL,
    secret character varying NOT NULL,
    redirect_uri text,
    scopes character varying DEFAULT ''::character varying NOT NULL,
    confidential boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: oauth_device_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_device_grants (
    id bigint NOT NULL,
    resource_owner_id uuid,
    application_id uuid NOT NULL,
    device_code character varying NOT NULL,
    user_code character varying,
    expires_in integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    last_polling_at timestamp without time zone,
    scopes character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: oauth_device_grants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_device_grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_device_grants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_device_grants_id_seq OWNED BY public.oauth_device_grants.id;


--
-- Name: oauth_identities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_identities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    provider character varying NOT NULL,
    uid character varying NOT NULL,
    access_token character varying,
    refresh_token character varying,
    extra_data jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    subscription_id uuid NOT NULL,
    user_id uuid NOT NULL,
    provider_key character varying NOT NULL,
    provider_invoice_id character varying,
    provider_payment_id character varying,
    kind character varying DEFAULT 'renewal'::character varying NOT NULL,
    status character varying NOT NULL,
    amount_cents bigint NOT NULL,
    currency character varying(3) NOT NULL,
    attempted_at timestamp(6) without time zone,
    paid_at timestamp(6) without time zone,
    failure_code character varying,
    failure_message text,
    provider_metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.people (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tmdb_id integer NOT NULL,
    name character varying NOT NULL,
    profile_path character varying,
    known_for_department character varying DEFAULT 'Acting'::character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preferences (
    id bigint NOT NULL,
    profile_id uuid NOT NULL,
    key character varying,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.preferences_id_seq OWNED BY public.preferences.id;


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    name character varying,
    profile_type character varying,
    avatar_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: provider_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.provider_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_key character varying NOT NULL,
    provider_event_id character varying,
    event_type character varying NOT NULL,
    resource_type character varying,
    resource_id character varying,
    signature_valid boolean NOT NULL,
    occurred_at timestamp(6) without time zone,
    received_at timestamp(6) without time zone NOT NULL,
    processed_at timestamp(6) without time zone,
    processing_error text,
    attempt_count integer DEFAULT 0 NOT NULL,
    payload_sha256 character varying NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    headers jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: reproductions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reproductions (
    id bigint NOT NULL,
    profile_id uuid NOT NULL,
    content_id uuid NOT NULL,
    played_at timestamp(6) without time zone NOT NULL,
    country_code character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: reproductions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reproductions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reproductions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reproductions_id_seq OWNED BY public.reproductions.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id bigint NOT NULL,
    name character varying,
    resource_type character varying,
    resource_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: scheduler_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scheduler_stats (
    id integer NOT NULL,
    name character varying NOT NULL,
    hostname character varying NOT NULL,
    pid integer NOT NULL,
    duration_ms integer,
    live_slots_start integer,
    live_slots_finish integer,
    started_at timestamp without time zone NOT NULL,
    success boolean,
    error text
);


--
-- Name: scheduler_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scheduler_stats_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scheduler_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scheduler_stats_id_seq OWNED BY public.scheduler_stats.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: seasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seasons (
    title character varying,
    description character varying,
    content_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    "position" integer,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tmdb_id integer
);


--
-- Name: segments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.segments (
    id bigint NOT NULL,
    start_time double precision,
    end_time double precision,
    segment_type character varying NOT NULL,
    segmentable_type character varying NOT NULL,
    segmentable_id character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: segments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.segments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: segments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.segments_id_seq OWNED BY public.segments.id;


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings (
    id bigint NOT NULL,
    var character varying NOT NULL,
    value text,
    data_type character varying DEFAULT 'string'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    exposed_to_client boolean DEFAULT false
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.settings_id_seq OWNED BY public.settings.id;


--
-- Name: subscription_access_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscription_access_grants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    granted_by_user_id uuid,
    starts_at timestamp(6) without time zone NOT NULL,
    ends_at timestamp(6) without time zone NOT NULL,
    reason character varying NOT NULL,
    revoked_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: subscription_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscription_payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    user_subscription_id bigint NOT NULL,
    provider character varying NOT NULL,
    provider_payment_id character varying NOT NULL,
    amount numeric(10,2) NOT NULL,
    currency character varying NOT NULL,
    status character varying NOT NULL,
    paid_at timestamp(6) without time zone,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    offering_key character varying DEFAULT 'cinelartv_membership_monthly'::character varying NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    provider_key character varying NOT NULL,
    provider_subscription_id character varying,
    provider_customer_id character varying,
    provider_plan_id character varying,
    amount_cents bigint NOT NULL,
    currency character varying(3) NOT NULL,
    interval_unit character varying DEFAULT 'month'::character varying NOT NULL,
    interval_count integer DEFAULT 1 NOT NULL,
    current_period_started_at timestamp(6) without time zone,
    current_period_ends_at timestamp(6) without time zone,
    access_until timestamp(6) without time zone,
    grace_ends_at timestamp(6) without time zone,
    cancel_at_period_end boolean DEFAULT false NOT NULL,
    cancelled_at timestamp(6) without time zone,
    expired_at timestamp(6) without time zone,
    remote_updated_at timestamp(6) without time zone,
    last_reconciled_at timestamp(6) without time zone,
    provider_metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tv_programs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tv_programs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    live_tv_channel_id uuid NOT NULL,
    title character varying NOT NULL,
    description text,
    start_time timestamp(6) without time zone NOT NULL,
    end_time timestamp(6) without time zone NOT NULL,
    icon_url character varying,
    category character varying,
    xmltv_id character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_subscriptions (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    order_id integer,
    order_item_id integer,
    product_id integer,
    variant_id integer,
    product_name character varying,
    variant_name character varying,
    user_name character varying,
    user_email character varying,
    status character varying,
    status_formatted character varying,
    card_brand character varying,
    card_last_four character varying,
    cancelled boolean,
    trial_ends_at timestamp(6) without time zone,
    billing_anchor integer,
    renews_at timestamp(6) without time zone,
    ends_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    test_mode boolean,
    provider character varying DEFAULT 'mercado_pago'::character varying NOT NULL,
    provider_subscription_id character varying,
    provider_customer_id character varying,
    provider_plan_id character varying,
    checkout_reference character varying,
    external_status character varying,
    granted_by_admin boolean DEFAULT false NOT NULL,
    granted_until timestamp(6) without time zone,
    cancelled_at timestamp(6) without time zone,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    purchase_token character varying,
    iap_product_id character varying,
    external_id character varying
);


--
-- Name: user_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_subscriptions_id_seq OWNED BY public.user_subscriptions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    username character varying,
    customer_id integer,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp(6) without time zone,
    last_sign_in_at timestamp(6) without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    suspended boolean DEFAULT false NOT NULL,
    suspended_until timestamp(6) without time zone,
    suspended_reason text,
    suspended_by_id uuid,
    deactivated_at timestamp(6) without time zone,
    deactivated_reason text,
    deactivated_by_id uuid,
    confirmation_token character varying,
    confirmed_at timestamp(6) without time zone,
    confirmation_sent_at timestamp(6) without time zone,
    unconfirmed_email character varying
);


--
-- Name: users_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_roles (
    user_id uuid,
    role_id bigint
);


--
-- Name: video_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.video_sources (
    id bigint NOT NULL,
    url character varying,
    quality character varying,
    format character varying,
    storage_location character varying,
    videoable_type character varying NOT NULL,
    videoable_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    status character varying,
    temp_path character varying,
    last_checked_at timestamp(6) without time zone,
    media_status character varying DEFAULT 'verified'::character varying,
    failure_count integer DEFAULT 0,
    trailer boolean DEFAULT false NOT NULL
);


--
-- Name: video_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.video_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: video_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.video_sources_id_seq OWNED BY public.video_sources.id;


--
-- Name: watch_party_session_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.watch_party_session_users (
    id bigint NOT NULL,
    watch_party_session_id bigint NOT NULL,
    user_id uuid NOT NULL,
    is_host boolean DEFAULT false,
    joined_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: watch_party_session_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.watch_party_session_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: watch_party_session_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.watch_party_session_users_id_seq OWNED BY public.watch_party_session_users.id;


--
-- Name: watch_party_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.watch_party_sessions (
    id bigint NOT NULL,
    content_id character varying NOT NULL,
    host_id uuid NOT NULL,
    user_id uuid NOT NULL,
    playback_current_time double precision DEFAULT 0.0,
    is_playing boolean DEFAULT false,
    started_at timestamp(6) without time zone,
    ended_at timestamp(6) without time zone,
    last_sync_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    live_event_id bigint,
    is_public boolean DEFAULT false NOT NULL,
    playback_position double precision DEFAULT 0.0,
    last_playback_update_at timestamp(6) without time zone,
    last_activity_at timestamp(6) without time zone
);


--
-- Name: watch_party_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.watch_party_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: watch_party_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.watch_party_sessions_id_seq OWNED BY public.watch_party_sessions.id;


--
-- Name: watch_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.watch_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    profile_id uuid NOT NULL,
    content_id uuid NOT NULL,
    episode_id uuid,
    started_at timestamp(6) without time zone NOT NULL,
    ended_at timestamp(6) without time zone,
    duration_watched double precision DEFAULT 0.0 NOT NULL,
    total_duration double precision DEFAULT 0.0 NOT NULL,
    completed boolean DEFAULT false NOT NULL,
    country_code character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    last_progress double precision DEFAULT 0.0 NOT NULL
);


--
-- Name: webhook_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhook_logs (
    id bigint NOT NULL,
    event_name character varying,
    payload text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: webhook_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.webhook_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: webhook_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.webhook_logs_id_seq OWNED BY public.webhook_logs.id;


--
-- Name: xmltv_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.xmltv_sources (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying NOT NULL,
    url character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    last_fetched_at timestamp(6) without time zone,
    last_parsed_at timestamp(6) without time zone,
    raw_xml text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: backups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.backups ALTER COLUMN id SET DEFAULT nextval('public.backups_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: cinelar_ads_ad_impressions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cinelar_ads_ad_impressions ALTER COLUMN id SET DEFAULT nextval('public.cinelar_ads_ad_impressions_id_seq'::regclass);


--
-- Name: cinelar_ads_house_ad_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cinelar_ads_house_ad_categories ALTER COLUMN id SET DEFAULT nextval('public.cinelar_ads_house_ad_categories_id_seq'::regclass);


--
-- Name: cinelar_ads_house_ad_content_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cinelar_ads_house_ad_content_types ALTER COLUMN id SET DEFAULT nextval('public.cinelar_ads_house_ad_content_types_id_seq'::regclass);


--
-- Name: cinelar_ads_house_ad_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cinelar_ads_house_ad_settings ALTER COLUMN id SET DEFAULT nextval('public.cinelar_ads_house_ad_settings_id_seq'::regclass);


--
-- Name: cinelar_ads_house_ads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cinelar_ads_house_ads ALTER COLUMN id SET DEFAULT nextval('public.cinelar_ads_house_ads_id_seq'::regclass);


--
-- Name: content_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_categories ALTER COLUMN id SET DEFAULT nextval('public.content_categories_id_seq'::regclass);


--
-- Name: continue_watchings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.continue_watchings ALTER COLUMN id SET DEFAULT nextval('public.continue_watchings_id_seq'::regclass);


--
-- Name: custom_pages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_pages ALTER COLUMN id SET DEFAULT nextval('public.custom_pages_id_seq'::regclass);


--
-- Name: dislikes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dislikes ALTER COLUMN id SET DEFAULT nextval('public.dislikes_id_seq'::regclass);


--
-- Name: email_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_templates ALTER COLUMN id SET DEFAULT nextval('public.email_templates_id_seq'::regclass);


--
-- Name: likes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.likes ALTER COLUMN id SET DEFAULT nextval('public.likes_id_seq'::regclass);


--
-- Name: live_chat_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_chat_messages ALTER COLUMN id SET DEFAULT nextval('public.live_chat_messages_id_seq'::regclass);


--
-- Name: live_event_attendees id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_event_attendees ALTER COLUMN id SET DEFAULT nextval('public.live_event_attendees_id_seq'::regclass);


--
-- Name: live_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_events ALTER COLUMN id SET DEFAULT nextval('public.live_events_id_seq'::regclass);


--
-- Name: oauth_device_grants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_device_grants ALTER COLUMN id SET DEFAULT nextval('public.oauth_device_grants_id_seq'::regclass);


--
-- Name: preferences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preferences ALTER COLUMN id SET DEFAULT nextval('public.preferences_id_seq'::regclass);


--
-- Name: reproductions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reproductions ALTER COLUMN id SET DEFAULT nextval('public.reproductions_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: scheduler_stats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduler_stats ALTER COLUMN id SET DEFAULT nextval('public.scheduler_stats_id_seq'::regclass);


--
-- Name: segments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.segments ALTER COLUMN id SET DEFAULT nextval('public.segments_id_seq'::regclass);


--
-- Name: settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings ALTER COLUMN id SET DEFAULT nextval('public.settings_id_seq'::regclass);


--
-- Name: user_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.user_subscriptions_id_seq'::regclass);


--
-- Name: video_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_sources ALTER COLUMN id SET DEFAULT nextval('public.video_sources_id_seq'::regclass);


--
-- Name: watch_party_session_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_party_session_users ALTER COLUMN id SET DEFAULT nextval('public.watch_party_session_users_id_seq'::regclass);


--
-- Name: watch_party_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_party_sessions ALTER COLUMN id SET DEFAULT nextval('public.watch_party_sessions_id_seq'::regclass);


--
-- Name: webhook_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_logs ALTER COLUMN id SET DEFAULT nextval('public.webhook_logs_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: backups backups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.backups
    ADD CONSTRAINT backups_pkey PRIMARY KEY (id);


--
-- Name: cast_members cast_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cast_members
    ADD CONSTRAINT cast_members_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: cinelar_ads_ad_impressions cinelar_ads_ad_impressions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cinelar_ads_ad_impressions
    ADD CONSTRAINT cinelar_ads_ad_impressions_pkey PRIMARY KEY (id);


--
-- Name: cinelar_ads_house_ad_categories cinelar_ads_house_ad_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cinelar_ads_house_ad_categories
    ADD CONSTRAINT cinelar_ads_house_ad_categories_pkey PRIMARY KEY (id);


--
-- Name: cinelar_ads_house_ad_content_types cinelar_ads_house_ad_content_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cinelar_ads_house_ad_content_types
    ADD CONSTRAINT cinelar_ads_house_ad_content_types_pkey PRIMARY KEY (id);


--
-- Name: cinelar_ads_house_ad_settings cinelar_ads_house_ad_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cinelar_ads_house_ad_settings
    ADD CONSTRAINT cinelar_ads_house_ad_settings_pkey PRIMARY KEY (id);


--
-- Name: cinelar_ads_house_ads cinelar_ads_house_ads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cinelar_ads_house_ads
    ADD CONSTRAINT cinelar_ads_house_ads_pkey PRIMARY KEY (id);


--
-- Name: content_analytics content_analytics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_analytics
    ADD CONSTRAINT content_analytics_pkey PRIMARY KEY (id);


--
-- Name: content_categories content_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_categories
    ADD CONSTRAINT content_categories_pkey PRIMARY KEY (id);


--
-- Name: content_content_descriptors content_content_descriptors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_content_descriptors
    ADD CONSTRAINT content_content_descriptors_pkey PRIMARY KEY (id);


--
-- Name: content_descriptors content_descriptors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_descriptors
    ADD CONSTRAINT content_descriptors_pkey PRIMARY KEY (id);


--
-- Name: content_ratings content_ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_ratings
    ADD CONSTRAINT content_ratings_pkey PRIMARY KEY (id);


--
-- Name: contents contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contents
    ADD CONSTRAINT contents_pkey PRIMARY KEY (id);


--
-- Name: continue_watchings continue_watchings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.continue_watchings
    ADD CONSTRAINT continue_watchings_pkey PRIMARY KEY (id);


--
-- Name: custom_pages custom_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_pages
    ADD CONSTRAINT custom_pages_pkey PRIMARY KEY (id);


--
-- Name: dislikes dislikes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dislikes
    ADD CONSTRAINT dislikes_pkey PRIMARY KEY (id);


--
-- Name: email_templates email_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_templates
    ADD CONSTRAINT email_templates_pkey PRIMARY KEY (id);


--
-- Name: episode_content_descriptors episode_content_descriptors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.episode_content_descriptors
    ADD CONSTRAINT episode_content_descriptors_pkey PRIMARY KEY (id);


--
-- Name: episodes episodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.episodes
    ADD CONSTRAINT episodes_pkey PRIMARY KEY (id);


--
-- Name: image_variants image_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.image_variants
    ADD CONSTRAINT image_variants_pkey PRIMARY KEY (id);


--
-- Name: likes likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_pkey PRIMARY KEY (id);


--
-- Name: live_chat_messages live_chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_chat_messages
    ADD CONSTRAINT live_chat_messages_pkey PRIMARY KEY (id);


--
-- Name: live_event_attendees live_event_attendees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_event_attendees
    ADD CONSTRAINT live_event_attendees_pkey PRIMARY KEY (id);


--
-- Name: live_events live_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_events
    ADD CONSTRAINT live_events_pkey PRIMARY KEY (id);


--
-- Name: live_tv_channels live_tv_channels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_tv_channels
    ADD CONSTRAINT live_tv_channels_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_grants oauth_access_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT oauth_access_grants_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_tokens oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: oauth_applications oauth_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_applications
    ADD CONSTRAINT oauth_applications_pkey PRIMARY KEY (id);


--
-- Name: oauth_device_grants oauth_device_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_device_grants
    ADD CONSTRAINT oauth_device_grants_pkey PRIMARY KEY (id);


--
-- Name: oauth_identities oauth_identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_identities
    ADD CONSTRAINT oauth_identities_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: people people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: preferences preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preferences
    ADD CONSTRAINT preferences_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: provider_events provider_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provider_events
    ADD CONSTRAINT provider_events_pkey PRIMARY KEY (id);


--
-- Name: reproductions reproductions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reproductions
    ADD CONSTRAINT reproductions_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: scheduler_stats scheduler_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduler_stats
    ADD CONSTRAINT scheduler_stats_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: seasons seasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seasons
    ADD CONSTRAINT seasons_pkey PRIMARY KEY (id);


--
-- Name: segments segments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.segments
    ADD CONSTRAINT segments_pkey PRIMARY KEY (id);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: subscription_access_grants subscription_access_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_access_grants
    ADD CONSTRAINT subscription_access_grants_pkey PRIMARY KEY (id);


--
-- Name: subscription_payments subscription_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_payments
    ADD CONSTRAINT subscription_payments_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: tv_programs tv_programs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tv_programs
    ADD CONSTRAINT tv_programs_pkey PRIMARY KEY (id);


--
-- Name: user_subscriptions user_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT user_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: video_sources video_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.video_sources
    ADD CONSTRAINT video_sources_pkey PRIMARY KEY (id);


--
-- Name: watch_party_session_users watch_party_session_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_party_session_users
    ADD CONSTRAINT watch_party_session_users_pkey PRIMARY KEY (id);


--
-- Name: watch_party_sessions watch_party_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_party_sessions
    ADD CONSTRAINT watch_party_sessions_pkey PRIMARY KEY (id);


--
-- Name: watch_sessions watch_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_sessions
    ADD CONSTRAINT watch_sessions_pkey PRIMARY KEY (id);


--
-- Name: webhook_logs webhook_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_logs
    ADD CONSTRAINT webhook_logs_pkey PRIMARY KEY (id);


--
-- Name: xmltv_sources xmltv_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.xmltv_sources
    ADD CONSTRAINT xmltv_sources_pkey PRIMARY KEY (id);


--
-- Name: idx_ccd_on_content_and_descriptor; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_ccd_on_content_and_descriptor ON public.content_content_descriptors USING btree (content_id, content_descriptor_id);


--
-- Name: idx_cinelar_ads_ha_cat_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_cinelar_ads_ha_cat_unique ON public.cinelar_ads_house_ad_categories USING btree (house_ad_id, category_id);


--
-- Name: idx_cinelar_ads_ha_ct_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_cinelar_ads_ha_ct_unique ON public.cinelar_ads_house_ad_content_types USING btree (house_ad_id, content_type);


--
-- Name: idx_ecd_on_episode_and_descriptor; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_ecd_on_episode_and_descriptor ON public.episode_content_descriptors USING btree (episode_id, content_descriptor_id);


--
-- Name: idx_image_variants_on_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_image_variants_on_lookup ON public.image_variants USING btree (imageable_type, imageable_id, image_type, variant, format);


--
-- Name: idx_on_watch_party_session_id_user_id_46fa650fed; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_watch_party_session_id_user_id_46fa650fed ON public.watch_party_session_users USING btree (watch_party_session_id, user_id);


--
-- Name: idx_user_subscriptions_provider_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_user_subscriptions_provider_external_id ON public.user_subscriptions USING btree (provider, provider_subscription_id) WHERE (provider_subscription_id IS NOT NULL);


--
-- Name: index_access_grants_active_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_access_grants_active_lookup ON public.subscription_access_grants USING btree (user_id, starts_at, ends_at);


--
-- Name: index_audit_logs_on_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_action ON public.audit_logs USING btree (action);


--
-- Name: index_audit_logs_on_action_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_action_and_created_at ON public.audit_logs USING btree (action, created_at);


--
-- Name: index_audit_logs_on_auditable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_auditable ON public.audit_logs USING btree (auditable_type, auditable_id);


--
-- Name: index_audit_logs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_created_at ON public.audit_logs USING btree (created_at);


--
-- Name: index_audit_logs_on_custom_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_custom_type ON public.audit_logs USING btree (custom_type);


--
-- Name: index_audit_logs_on_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_source ON public.audit_logs USING btree (source);


--
-- Name: index_audit_logs_on_target_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_target_user_id ON public.audit_logs USING btree (target_user_id);


--
-- Name: index_audit_logs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_logs_on_user_id ON public.audit_logs USING btree (user_id);


--
-- Name: index_backups_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_backups_on_created_at ON public.backups USING btree (created_at);


--
-- Name: index_backups_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_backups_on_expires_at ON public.backups USING btree (expires_at);


--
-- Name: index_backups_on_filename; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_backups_on_filename ON public.backups USING btree (filename);


--
-- Name: index_backups_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_backups_on_status ON public.backups USING btree (status);


--
-- Name: index_cast_members_on_content_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cast_members_on_content_id ON public.cast_members USING btree (content_id);


--
-- Name: index_cast_members_on_content_id_and_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cast_members_on_content_id_and_order ON public.cast_members USING btree (content_id, "order");


--
-- Name: index_cast_members_on_content_id_and_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cast_members_on_content_id_and_person_id ON public.cast_members USING btree (content_id, person_id);


--
-- Name: index_cast_members_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cast_members_on_person_id ON public.cast_members USING btree (person_id);


--
-- Name: index_categories_on_tmdb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_categories_on_tmdb_id ON public.categories USING btree (tmdb_id) WHERE (tmdb_id IS NOT NULL);


--
-- Name: index_cinelar_ads_ad_impressions_on_ad_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cinelar_ads_ad_impressions_on_ad_type ON public.cinelar_ads_ad_impressions USING btree (ad_type);


--
-- Name: index_cinelar_ads_ad_impressions_on_ad_type_and_placement; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cinelar_ads_ad_impressions_on_ad_type_and_placement ON public.cinelar_ads_ad_impressions USING btree (ad_type, placement);


--
-- Name: index_cinelar_ads_ad_impressions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cinelar_ads_ad_impressions_on_created_at ON public.cinelar_ads_ad_impressions USING btree (created_at);


--
-- Name: index_cinelar_ads_ad_impressions_on_house_ad_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cinelar_ads_ad_impressions_on_house_ad_id ON public.cinelar_ads_ad_impressions USING btree (house_ad_id);


--
-- Name: index_cinelar_ads_ad_impressions_on_placement; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cinelar_ads_ad_impressions_on_placement ON public.cinelar_ads_ad_impressions USING btree (placement);


--
-- Name: index_cinelar_ads_ad_impressions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cinelar_ads_ad_impressions_on_user_id ON public.cinelar_ads_ad_impressions USING btree (user_id);


--
-- Name: index_cinelar_ads_house_ad_categories_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cinelar_ads_house_ad_categories_on_category_id ON public.cinelar_ads_house_ad_categories USING btree (category_id);


--
-- Name: index_cinelar_ads_house_ad_categories_on_house_ad_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cinelar_ads_house_ad_categories_on_house_ad_id ON public.cinelar_ads_house_ad_categories USING btree (house_ad_id);


--
-- Name: index_cinelar_ads_house_ad_content_types_on_house_ad_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cinelar_ads_house_ad_content_types_on_house_ad_id ON public.cinelar_ads_house_ad_content_types USING btree (house_ad_id);


--
-- Name: index_cinelar_ads_house_ad_settings_on_slot; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cinelar_ads_house_ad_settings_on_slot ON public.cinelar_ads_house_ad_settings USING btree (slot);


--
-- Name: index_cinelar_ads_house_ads_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cinelar_ads_house_ads_on_name ON public.cinelar_ads_house_ads USING btree (name);


--
-- Name: index_content_analytics_on_content_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_content_analytics_on_content_id ON public.content_analytics USING btree (content_id);


--
-- Name: index_content_analytics_on_last_watched_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_analytics_on_last_watched_at ON public.content_analytics USING btree (last_watched_at);


--
-- Name: index_content_analytics_on_total_views; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_analytics_on_total_views ON public.content_analytics USING btree (total_views);


--
-- Name: index_content_categories_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_categories_on_category_id ON public.content_categories USING btree (category_id);


--
-- Name: index_content_categories_on_content_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_categories_on_content_id ON public.content_categories USING btree (content_id);


--
-- Name: index_content_categories_on_content_id_and_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_content_categories_on_content_id_and_category_id ON public.content_categories USING btree (content_id, category_id);


--
-- Name: index_content_content_descriptors_on_content_descriptor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_content_descriptors_on_content_descriptor_id ON public.content_content_descriptors USING btree (content_descriptor_id);


--
-- Name: index_content_content_descriptors_on_content_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_content_descriptors_on_content_id ON public.content_content_descriptors USING btree (content_id);


--
-- Name: index_content_descriptors_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_content_descriptors_on_key ON public.content_descriptors USING btree (key);


--
-- Name: index_content_ratings_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_content_ratings_on_code ON public.content_ratings USING btree (code);


--
-- Name: index_contents_on_available_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contents_on_available_and_created_at ON public.contents USING btree (created_at DESC) WHERE (available = true);


--
-- Name: index_contents_on_available_true; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contents_on_available_true ON public.contents USING btree (available) WHERE (available = true);


--
-- Name: index_contents_on_content_rating_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contents_on_content_rating_id ON public.contents USING btree (content_rating_id);


--
-- Name: index_contents_on_content_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contents_on_content_type ON public.contents USING btree (content_type);


--
-- Name: index_contents_on_scheduled_launch_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contents_on_scheduled_launch_pending ON public.contents USING btree (scheduled_launch_at) WHERE ((scheduled_launch_at IS NOT NULL) AND (available = false));


--
-- Name: index_contents_on_search_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contents_on_search_data ON public.contents USING gin (search_data);


--
-- Name: index_contents_on_tmdb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contents_on_tmdb_id ON public.contents USING btree (tmdb_id);


--
-- Name: index_continue_watchings_on_content_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_continue_watchings_on_content_id ON public.continue_watchings USING btree (content_id);


--
-- Name: index_continue_watchings_on_episode_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_continue_watchings_on_episode_id ON public.continue_watchings USING btree (episode_id);


--
-- Name: index_continue_watchings_on_last_watched_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_continue_watchings_on_last_watched_at ON public.continue_watchings USING btree (last_watched_at);


--
-- Name: index_continue_watchings_on_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_continue_watchings_on_profile_id ON public.continue_watchings USING btree (profile_id);


--
-- Name: index_continue_watchings_on_profile_id_and_last_watched_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_continue_watchings_on_profile_id_and_last_watched_at ON public.continue_watchings USING btree (profile_id, last_watched_at);


--
-- Name: index_custom_pages_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_custom_pages_on_slug ON public.custom_pages USING btree (slug);


--
-- Name: index_dislikes_on_content_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dislikes_on_content_id ON public.dislikes USING btree (content_id);


--
-- Name: index_dislikes_on_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dislikes_on_profile_id ON public.dislikes USING btree (profile_id);


--
-- Name: index_email_templates_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_templates_on_key ON public.email_templates USING btree (key);


--
-- Name: index_email_templates_on_key_and_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_email_templates_on_key_and_locale ON public.email_templates USING btree (key, locale);


--
-- Name: index_email_templates_on_locale; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_email_templates_on_locale ON public.email_templates USING btree (locale);


--
-- Name: index_episode_content_descriptors_on_content_descriptor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_episode_content_descriptors_on_content_descriptor_id ON public.episode_content_descriptors USING btree (content_descriptor_id);


--
-- Name: index_episode_content_descriptors_on_episode_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_episode_content_descriptors_on_episode_id ON public.episode_content_descriptors USING btree (episode_id);


--
-- Name: index_episodes_on_content_rating_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_episodes_on_content_rating_id ON public.episodes USING btree (content_rating_id);


--
-- Name: index_episodes_on_season_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_episodes_on_season_id ON public.episodes USING btree (season_id);


--
-- Name: index_episodes_on_season_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_episodes_on_season_id_and_position ON public.episodes USING btree (season_id, "position");


--
-- Name: index_episodes_on_tmdb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_episodes_on_tmdb_id ON public.episodes USING btree (tmdb_id) WHERE (tmdb_id IS NOT NULL);


--
-- Name: index_image_variants_on_image_type_and_variant_and_format; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_image_variants_on_image_type_and_variant_and_format ON public.image_variants USING btree (image_type, variant, format);


--
-- Name: index_image_variants_on_imageable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_image_variants_on_imageable ON public.image_variants USING btree (imageable_type, imageable_id);


--
-- Name: index_likes_on_content_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_likes_on_content_id ON public.likes USING btree (content_id);


--
-- Name: index_likes_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_likes_on_created_at ON public.likes USING btree (created_at);


--
-- Name: index_likes_on_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_likes_on_profile_id ON public.likes USING btree (profile_id);


--
-- Name: index_likes_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_likes_on_updated_at ON public.likes USING btree (updated_at);


--
-- Name: index_live_chat_messages_on_live_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_chat_messages_on_live_event_id ON public.live_chat_messages USING btree (live_event_id);


--
-- Name: index_live_chat_messages_on_live_event_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_chat_messages_on_live_event_id_and_created_at ON public.live_chat_messages USING btree (live_event_id, created_at);


--
-- Name: index_live_chat_messages_on_message_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_chat_messages_on_message_type ON public.live_chat_messages USING btree (message_type);


--
-- Name: index_live_chat_messages_on_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_chat_messages_on_profile_id ON public.live_chat_messages USING btree (profile_id);


--
-- Name: index_live_event_attendees_on_live_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_event_attendees_on_live_event_id ON public.live_event_attendees USING btree (live_event_id);


--
-- Name: index_live_event_attendees_on_live_event_id_and_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_live_event_attendees_on_live_event_id_and_profile_id ON public.live_event_attendees USING btree (live_event_id, profile_id);


--
-- Name: index_live_event_attendees_on_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_event_attendees_on_profile_id ON public.live_event_attendees USING btree (profile_id);


--
-- Name: index_live_events_on_content_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_events_on_content_id ON public.live_events USING btree (content_id);


--
-- Name: index_live_events_on_organizer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_events_on_organizer_id ON public.live_events USING btree (organizer_id);


--
-- Name: index_live_events_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_events_on_status ON public.live_events USING btree (status);


--
-- Name: index_live_events_on_status_and_starts_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_events_on_status_and_starts_at ON public.live_events USING btree (status, starts_at);


--
-- Name: index_live_tv_channels_on_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_tv_channels_on_is_active ON public.live_tv_channels USING btree (is_active);


--
-- Name: index_live_tv_channels_on_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_tv_channels_on_position ON public.live_tv_channels USING btree ("position");


--
-- Name: index_live_tv_channels_on_xmltv_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_live_tv_channels_on_xmltv_channel_id ON public.live_tv_channels USING btree (xmltv_channel_id);


--
-- Name: index_oauth_access_grants_on_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_grants_on_application_id ON public.oauth_access_grants USING btree (application_id);


--
-- Name: index_oauth_access_grants_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_grants_on_resource_owner_id ON public.oauth_access_grants USING btree (resource_owner_id);


--
-- Name: index_oauth_access_grants_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_grants_on_token ON public.oauth_access_grants USING btree (token);


--
-- Name: index_oauth_access_tokens_on_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_tokens_on_application_id ON public.oauth_access_tokens USING btree (application_id);


--
-- Name: index_oauth_access_tokens_on_refresh_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_refresh_token ON public.oauth_access_tokens USING btree (refresh_token);


--
-- Name: index_oauth_access_tokens_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_tokens_on_resource_owner_id ON public.oauth_access_tokens USING btree (resource_owner_id);


--
-- Name: index_oauth_access_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_token ON public.oauth_access_tokens USING btree (token);


--
-- Name: index_oauth_applications_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_applications_on_uid ON public.oauth_applications USING btree (uid);


--
-- Name: index_oauth_device_grants_on_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_device_grants_on_application_id ON public.oauth_device_grants USING btree (application_id);


--
-- Name: index_oauth_device_grants_on_device_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_device_grants_on_device_code ON public.oauth_device_grants USING btree (device_code);


--
-- Name: index_oauth_device_grants_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_device_grants_on_resource_owner_id ON public.oauth_device_grants USING btree (resource_owner_id);


--
-- Name: index_oauth_device_grants_on_user_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_device_grants_on_user_code ON public.oauth_device_grants USING btree (user_code);


--
-- Name: index_oauth_identities_on_provider_and_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_identities_on_provider_and_uid ON public.oauth_identities USING btree (provider, uid);


--
-- Name: index_oauth_identities_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_identities_on_user_id ON public.oauth_identities USING btree (user_id);


--
-- Name: index_one_open_subscription_per_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_one_open_subscription_per_user ON public.subscriptions USING btree (user_id) WHERE ((status)::text = ANY ((ARRAY['pending'::character varying, 'active'::character varying, 'past_due'::character varying, 'cancelled'::character varying])::text[]));


--
-- Name: index_payments_on_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payments_on_subscription_id ON public.payments USING btree (subscription_id);


--
-- Name: index_payments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payments_on_user_id ON public.payments USING btree (user_id);


--
-- Name: index_payments_remote_invoice_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_payments_remote_invoice_id ON public.payments USING btree (provider_key, provider_invoice_id) WHERE (provider_invoice_id IS NOT NULL);


--
-- Name: index_payments_remote_payment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_payments_remote_payment_id ON public.payments USING btree (provider_key, provider_payment_id) WHERE (provider_payment_id IS NOT NULL);


--
-- Name: index_people_on_tmdb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_people_on_tmdb_id ON public.people USING btree (tmdb_id);


--
-- Name: index_preferences_on_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preferences_on_profile_id ON public.preferences USING btree (profile_id);


--
-- Name: index_preferences_on_profile_id_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_preferences_on_profile_id_and_key ON public.preferences USING btree (profile_id, key);


--
-- Name: index_profiles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_profiles_on_user_id ON public.profiles USING btree (user_id);


--
-- Name: index_provider_events_dedup_fallback; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_provider_events_dedup_fallback ON public.provider_events USING btree (provider_key, event_type, resource_id, payload_sha256);


--
-- Name: index_provider_events_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_provider_events_external_id ON public.provider_events USING btree (provider_key, provider_event_id) WHERE (provider_event_id IS NOT NULL);


--
-- Name: index_reproductions_on_content_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reproductions_on_content_id ON public.reproductions USING btree (content_id);


--
-- Name: index_reproductions_on_country_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reproductions_on_country_code ON public.reproductions USING btree (country_code);


--
-- Name: index_reproductions_on_played_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reproductions_on_played_at ON public.reproductions USING btree (played_at);


--
-- Name: index_reproductions_on_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reproductions_on_profile_id ON public.reproductions USING btree (profile_id);


--
-- Name: index_roles_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_name ON public.roles USING btree (name);


--
-- Name: index_roles_on_name_and_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_name_and_resource_type_and_resource_id ON public.roles USING btree (name, resource_type, resource_id);


--
-- Name: index_roles_on_resource; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_resource ON public.roles USING btree (resource_type, resource_id);


--
-- Name: index_seasons_on_content_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_seasons_on_content_id ON public.seasons USING btree (content_id);


--
-- Name: index_seasons_on_content_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_seasons_on_content_id_and_position ON public.seasons USING btree (content_id, "position");


--
-- Name: index_seasons_on_tmdb_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_seasons_on_tmdb_id ON public.seasons USING btree (tmdb_id) WHERE (tmdb_id IS NOT NULL);


--
-- Name: index_segments_on_segment_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_segments_on_segment_type ON public.segments USING btree (segment_type);


--
-- Name: index_segments_on_segmentable_type_and_segmentable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_segments_on_segmentable_type_and_segmentable_id ON public.segments USING btree (segmentable_type, segmentable_id);


--
-- Name: index_segments_on_type_and_id_and_start_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_segments_on_type_and_id_and_start_time ON public.segments USING btree (segmentable_type, segmentable_id, start_time);


--
-- Name: index_settings_on_var; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_settings_on_var ON public.settings USING btree (var);


--
-- Name: index_subscription_access_grants_on_granted_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscription_access_grants_on_granted_by_user_id ON public.subscription_access_grants USING btree (granted_by_user_id);


--
-- Name: index_subscription_access_grants_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscription_access_grants_on_user_id ON public.subscription_access_grants USING btree (user_id);


--
-- Name: index_subscription_payments_on_provider_and_provider_payment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_subscription_payments_on_provider_and_provider_payment_id ON public.subscription_payments USING btree (provider, provider_payment_id);


--
-- Name: index_subscription_payments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscription_payments_on_user_id ON public.subscription_payments USING btree (user_id);


--
-- Name: index_subscription_payments_on_user_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscription_payments_on_user_subscription_id ON public.subscription_payments USING btree (user_subscription_id);


--
-- Name: index_subscriptions_on_access_until; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_access_until ON public.subscriptions USING btree (access_until);


--
-- Name: index_subscriptions_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_status ON public.subscriptions USING btree (status);


--
-- Name: index_subscriptions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_user_id ON public.subscriptions USING btree (user_id);


--
-- Name: index_subscriptions_remote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_subscriptions_remote_id ON public.subscriptions USING btree (provider_key, provider_subscription_id) WHERE (provider_subscription_id IS NOT NULL);


--
-- Name: index_tv_programs_on_channel_and_times; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tv_programs_on_channel_and_times ON public.tv_programs USING btree (live_tv_channel_id, start_time, end_time);


--
-- Name: index_tv_programs_on_end_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tv_programs_on_end_time ON public.tv_programs USING btree (end_time);


--
-- Name: index_tv_programs_on_live_tv_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tv_programs_on_live_tv_channel_id ON public.tv_programs USING btree (live_tv_channel_id);


--
-- Name: index_tv_programs_on_start_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tv_programs_on_start_time ON public.tv_programs USING btree (start_time);


--
-- Name: index_tv_programs_on_xmltv_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tv_programs_on_xmltv_id ON public.tv_programs USING btree (xmltv_id);


--
-- Name: index_user_subscriptions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_subscriptions_on_created_at ON public.user_subscriptions USING btree (created_at);


--
-- Name: index_user_subscriptions_on_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_subscriptions_on_external_id ON public.user_subscriptions USING btree (external_id);


--
-- Name: index_user_subscriptions_on_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_subscriptions_on_provider ON public.user_subscriptions USING btree (provider);


--
-- Name: index_user_subscriptions_on_purchase_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_subscriptions_on_purchase_token ON public.user_subscriptions USING btree (purchase_token);


--
-- Name: index_user_subscriptions_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_subscriptions_on_status ON public.user_subscriptions USING btree (status);


--
-- Name: index_user_subscriptions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_subscriptions_on_user_id ON public.user_subscriptions USING btree (user_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_created_at ON public.users USING btree (created_at);


--
-- Name: index_users_on_deactivated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_deactivated_at ON public.users USING btree (deactivated_at);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_suspended_until; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_suspended_until ON public.users USING btree (suspended_until);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON public.users USING btree (username);


--
-- Name: index_users_roles_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_roles_on_role_id ON public.users_roles USING btree (role_id);


--
-- Name: index_users_roles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_roles_on_user_id ON public.users_roles USING btree (user_id);


--
-- Name: index_users_roles_on_user_id_and_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_roles_on_user_id_and_role_id ON public.users_roles USING btree (user_id, role_id);


--
-- Name: index_video_sources_on_last_checked_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_video_sources_on_last_checked_at ON public.video_sources USING btree (last_checked_at);


--
-- Name: index_video_sources_on_media_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_video_sources_on_media_status ON public.video_sources USING btree (media_status);


--
-- Name: index_video_sources_on_media_status_and_last_checked; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_video_sources_on_media_status_and_last_checked ON public.video_sources USING btree (media_status, last_checked_at);


--
-- Name: index_video_sources_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_video_sources_on_status ON public.video_sources USING btree (status);


--
-- Name: index_video_sources_on_videoable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_video_sources_on_videoable ON public.video_sources USING btree (videoable_type, videoable_id);


--
-- Name: index_video_sources_on_videoable_and_trailer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_video_sources_on_videoable_and_trailer ON public.video_sources USING btree (videoable_id, videoable_type, trailer);


--
-- Name: index_watch_party_session_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_party_session_users_on_user_id ON public.watch_party_session_users USING btree (user_id);


--
-- Name: index_watch_party_session_users_on_watch_party_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_party_session_users_on_watch_party_session_id ON public.watch_party_session_users USING btree (watch_party_session_id);


--
-- Name: index_watch_party_sessions_on_content_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_party_sessions_on_content_id ON public.watch_party_sessions USING btree (content_id);


--
-- Name: index_watch_party_sessions_on_host_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_party_sessions_on_host_id ON public.watch_party_sessions USING btree (host_id);


--
-- Name: index_watch_party_sessions_on_is_public_and_ended_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_party_sessions_on_is_public_and_ended_at ON public.watch_party_sessions USING btree (is_public, ended_at);


--
-- Name: index_watch_party_sessions_on_live_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_party_sessions_on_live_event_id ON public.watch_party_sessions USING btree (live_event_id);


--
-- Name: index_watch_party_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_party_sessions_on_user_id ON public.watch_party_sessions USING btree (user_id);


--
-- Name: index_watch_sessions_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_sessions_active ON public.watch_sessions USING btree (profile_id, content_id) WHERE (ended_at IS NULL);


--
-- Name: index_watch_sessions_on_completed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_sessions_on_completed ON public.watch_sessions USING btree (completed);


--
-- Name: index_watch_sessions_on_content_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_sessions_on_content_id ON public.watch_sessions USING btree (content_id);


--
-- Name: index_watch_sessions_on_content_id_and_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_sessions_on_content_id_and_started_at ON public.watch_sessions USING btree (content_id, started_at);


--
-- Name: index_watch_sessions_on_episode_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_sessions_on_episode_id ON public.watch_sessions USING btree (episode_id);


--
-- Name: index_watch_sessions_on_profile_content_episode_started; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_sessions_on_profile_content_episode_started ON public.watch_sessions USING btree (profile_id, content_id, episode_id, started_at DESC);


--
-- Name: index_watch_sessions_on_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_sessions_on_profile_id ON public.watch_sessions USING btree (profile_id);


--
-- Name: index_watch_sessions_on_profile_id_and_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_sessions_on_profile_id_and_started_at ON public.watch_sessions USING btree (profile_id, started_at);


--
-- Name: index_watch_sessions_on_started_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_watch_sessions_on_started_at ON public.watch_sessions USING btree (started_at);


--
-- Name: index_webhook_logs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webhook_logs_on_created_at ON public.webhook_logs USING btree (created_at);


--
-- Name: index_xmltv_sources_on_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_xmltv_sources_on_is_active ON public.xmltv_sources USING btree (is_active);


--
-- Name: index_xmltv_sources_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_xmltv_sources_on_url ON public.xmltv_sources USING btree (url);


--
-- Name: unique_continue_watchings_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_continue_watchings_index ON public.continue_watchings USING btree (profile_id, content_id, episode_id);


--
-- Name: cast_members fk_rails_00be64699e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cast_members
    ADD CONSTRAINT fk_rails_00be64699e FOREIGN KEY (content_id) REFERENCES public.contents(id);


--
-- Name: watch_party_sessions fk_rails_03c2382ec9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_party_sessions
    ADD CONSTRAINT fk_rails_03c2382ec9 FOREIGN KEY (host_id) REFERENCES public.users(id);


--
-- Name: watch_sessions fk_rails_04052a3182; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_sessions
    ADD CONSTRAINT fk_rails_04052a3182 FOREIGN KEY (episode_id) REFERENCES public.episodes(id) ON DELETE CASCADE;


--
-- Name: payments fk_rails_081dc04a02; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_rails_081dc04a02 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: live_chat_messages fk_rails_0b5fcd472a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_chat_messages
    ADD CONSTRAINT fk_rails_0b5fcd472a FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: continue_watchings fk_rails_0e0f61a88f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.continue_watchings
    ADD CONSTRAINT fk_rails_0e0f61a88f FOREIGN KEY (content_id) REFERENCES public.contents(id);


--
-- Name: tv_programs fk_rails_10e983512a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tv_programs
    ADD CONSTRAINT fk_rails_10e983512a FOREIGN KEY (live_tv_channel_id) REFERENCES public.live_tv_channels(id);


--
-- Name: episodes fk_rails_14b1666c11; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.episodes
    ADD CONSTRAINT fk_rails_14b1666c11 FOREIGN KEY (season_id) REFERENCES public.seasons(id);


--
-- Name: likes fk_rails_1cf78c0e99; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT fk_rails_1cf78c0e99 FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: audit_logs fk_rails_1f26bc34ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT fk_rails_1f26bc34ae FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: reproductions fk_rails_231e9f469a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reproductions
    ADD CONSTRAINT fk_rails_231e9f469a FOREIGN KEY (content_id) REFERENCES public.contents(id);


--
-- Name: seasons fk_rails_2430f73af3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seasons
    ADD CONSTRAINT fk_rails_2430f73af3 FOREIGN KEY (content_id) REFERENCES public.contents(id);


--
-- Name: content_content_descriptors fk_rails_28213353d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_content_descriptors
    ADD CONSTRAINT fk_rails_28213353d1 FOREIGN KEY (content_id) REFERENCES public.contents(id);


--
-- Name: cinelar_ads_house_ad_categories fk_rails_2901ff9e0b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cinelar_ads_house_ad_categories
    ADD CONSTRAINT fk_rails_2901ff9e0b FOREIGN KEY (house_ad_id) REFERENCES public.cinelar_ads_house_ads(id);


--
-- Name: watch_sessions fk_rails_2cea18c0c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_sessions
    ADD CONSTRAINT fk_rails_2cea18c0c3 FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: oauth_identities fk_rails_2f75762ff1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_identities
    ADD CONSTRAINT fk_rails_2f75762ff1 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: content_categories fk_rails_308cf77b4f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_categories
    ADD CONSTRAINT fk_rails_308cf77b4f FOREIGN KEY (content_id) REFERENCES public.contents(id) ON DELETE CASCADE;


--
-- Name: oauth_device_grants fk_rails_308d5b76fe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_device_grants
    ADD CONSTRAINT fk_rails_308d5b76fe FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id);


--
-- Name: episode_content_descriptors fk_rails_334b174b2a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.episode_content_descriptors
    ADD CONSTRAINT fk_rails_334b174b2a FOREIGN KEY (content_descriptor_id) REFERENCES public.content_descriptors(id);


--
-- Name: watch_party_session_users fk_rails_344f2a1c86; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_party_session_users
    ADD CONSTRAINT fk_rails_344f2a1c86 FOREIGN KEY (watch_party_session_id) REFERENCES public.watch_party_sessions(id);


--
-- Name: audit_logs fk_rails_38f95330b4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT fk_rails_38f95330b4 FOREIGN KEY (target_user_id) REFERENCES public.users(id);


--
-- Name: content_analytics fk_rails_3a8847f963; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_analytics
    ADD CONSTRAINT fk_rails_3a8847f963 FOREIGN KEY (content_id) REFERENCES public.contents(id);


--
-- Name: live_chat_messages fk_rails_3d5bd5ed20; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_chat_messages
    ADD CONSTRAINT fk_rails_3d5bd5ed20 FOREIGN KEY (live_event_id) REFERENCES public.live_events(id);


--
-- Name: watch_party_session_users fk_rails_3f8fdd49ee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_party_session_users
    ADD CONSTRAINT fk_rails_3f8fdd49ee FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: cinelar_ads_house_ad_categories fk_rails_41a0e208d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cinelar_ads_house_ad_categories
    ADD CONSTRAINT fk_rails_41a0e208d2 FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: likes fk_rails_4e21ceafd7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT fk_rails_4e21ceafd7 FOREIGN KEY (content_id) REFERENCES public.contents(id);


--
-- Name: contents fk_rails_5ac65b7dbc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contents
    ADD CONSTRAINT fk_rails_5ac65b7dbc FOREIGN KEY (content_rating_id) REFERENCES public.content_ratings(id);


--
-- Name: watch_party_sessions fk_rails_64ed814eaf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_party_sessions
    ADD CONSTRAINT fk_rails_64ed814eaf FOREIGN KEY (live_event_id) REFERENCES public.live_events(id);


--
-- Name: content_content_descriptors fk_rails_67cc5e3269; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_content_descriptors
    ADD CONSTRAINT fk_rails_67cc5e3269 FOREIGN KEY (content_descriptor_id) REFERENCES public.content_descriptors(id);


--
-- Name: cinelar_ads_house_ad_content_types fk_rails_6a6bb546fe; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cinelar_ads_house_ad_content_types
    ADD CONSTRAINT fk_rails_6a6bb546fe FOREIGN KEY (house_ad_id) REFERENCES public.cinelar_ads_house_ads(id);


--
-- Name: live_event_attendees fk_rails_6b9ba7b731; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_event_attendees
    ADD CONSTRAINT fk_rails_6b9ba7b731 FOREIGN KEY (live_event_id) REFERENCES public.live_events(id);


--
-- Name: dislikes fk_rails_6bddc9db89; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dislikes
    ADD CONSTRAINT fk_rails_6bddc9db89 FOREIGN KEY (content_id) REFERENCES public.contents(id);


--
-- Name: oauth_access_tokens fk_rails_732cb83ab7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT fk_rails_732cb83ab7 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id);


--
-- Name: watch_sessions fk_rails_774b56c473; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_sessions
    ADD CONSTRAINT fk_rails_774b56c473 FOREIGN KEY (content_id) REFERENCES public.contents(id);


--
-- Name: dislikes fk_rails_7f2a75d885; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dislikes
    ADD CONSTRAINT fk_rails_7f2a75d885 FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: cinelar_ads_ad_impressions fk_rails_80c7045554; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cinelar_ads_ad_impressions
    ADD CONSTRAINT fk_rails_80c7045554 FOREIGN KEY (house_ad_id) REFERENCES public.cinelar_ads_house_ads(id);


--
-- Name: live_events fk_rails_86c3050b0a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_events
    ADD CONSTRAINT fk_rails_86c3050b0a FOREIGN KEY (organizer_id) REFERENCES public.users(id);


--
-- Name: subscription_payments fk_rails_87f7b124e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_payments
    ADD CONSTRAINT fk_rails_87f7b124e7 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: watch_party_sessions fk_rails_8b08aea8a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_party_sessions
    ADD CONSTRAINT fk_rails_8b08aea8a8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: subscriptions fk_rails_933bdff476; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_933bdff476 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: episodes fk_rails_9b648764cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.episodes
    ADD CONSTRAINT fk_rails_9b648764cb FOREIGN KEY (content_rating_id) REFERENCES public.content_ratings(id);


--
-- Name: subscription_access_grants fk_rails_9c55bca553; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_access_grants
    ADD CONSTRAINT fk_rails_9c55bca553 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: cinelar_ads_ad_impressions fk_rails_a4fd5eed36; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cinelar_ads_ad_impressions
    ADD CONSTRAINT fk_rails_a4fd5eed36 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: cast_members fk_rails_af34b95100; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cast_members
    ADD CONSTRAINT fk_rails_af34b95100 FOREIGN KEY (person_id) REFERENCES public.people(id);


--
-- Name: episode_content_descriptors fk_rails_b0daab56b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.episode_content_descriptors
    ADD CONSTRAINT fk_rails_b0daab56b8 FOREIGN KEY (episode_id) REFERENCES public.episodes(id);


--
-- Name: oauth_access_grants fk_rails_b4b53e07b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT fk_rails_b4b53e07b8 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id);


--
-- Name: subscription_access_grants fk_rails_bd6c57d911; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_access_grants
    ADD CONSTRAINT fk_rails_bd6c57d911 FOREIGN KEY (granted_by_user_id) REFERENCES public.users(id);


--
-- Name: live_event_attendees fk_rails_d1901934f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_event_attendees
    ADD CONSTRAINT fk_rails_d1901934f8 FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: live_events fk_rails_d3d9589bb5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.live_events
    ADD CONSTRAINT fk_rails_d3d9589bb5 FOREIGN KEY (content_id) REFERENCES public.contents(id);


--
-- Name: preferences fk_rails_d84f5acc1e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preferences
    ADD CONSTRAINT fk_rails_d84f5acc1e FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: reproductions fk_rails_deeb46af7e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reproductions
    ADD CONSTRAINT fk_rails_deeb46af7e FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: subscription_payments fk_rails_df4818ebc6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_payments
    ADD CONSTRAINT fk_rails_df4818ebc6 FOREIGN KEY (user_subscription_id) REFERENCES public.user_subscriptions(id);


--
-- Name: profiles fk_rails_e424190865; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT fk_rails_e424190865 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: continue_watchings fk_rails_ea67a0817c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.continue_watchings
    ADD CONSTRAINT fk_rails_ea67a0817c FOREIGN KEY (profile_id) REFERENCES public.profiles(id);


--
-- Name: oauth_device_grants fk_rails_f1606c5ac4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_device_grants
    ADD CONSTRAINT fk_rails_f1606c5ac4 FOREIGN KEY (resource_owner_id) REFERENCES public.users(id);


--
-- Name: continue_watchings fk_rails_f5636722ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.continue_watchings
    ADD CONSTRAINT fk_rails_f5636722ac FOREIGN KEY (episode_id) REFERENCES public.episodes(id);


--
-- Name: content_categories fk_rails_f84b713483; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_categories
    ADD CONSTRAINT fk_rails_f84b713483 FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: payments fk_rails_fd6be2115b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_rails_fd6be2115b FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id);


--
-- PostgreSQL database dump complete
--

\unrestrict fpmnxB5dxOQYHdjcOF6JEcgRgUSpauwxzPvM0K586zgCYwmutfNcTFK8ykCSm4M

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260922160710'),
('20260921120000'),
('20260920185504'),
('20260903153038'),
('20260903153037'),
('20260903153036'),
('20260903153035'),
('20260903153034'),
('20260831120000'),
('20260830234756'),
('20260830234740'),
('20260830234710'),
('20260830000001'),
('20260818000004'),
('20260818000003'),
('20260818000002'),
('20260818000001'),
('20260814000001'),
('20260805000001'),
('20260804000001'),
('20260804000000'),
('20260803000001'),
('20260708000001'),
('20260707000000'),
('20260705100001'),
('20260704100002'),
('20260704100001'),
('20260704000001'),
('20260703000000'),
('20260630235519'),
('20260629020000'),
('20260629014453'),
('20260628000002'),
('20260628000001'),
('20260604000001'),
('20260604000000'),
('20260603000002'),
('20260603000001'),
('20260603000000'),
('20260512132107'),
('20260512131856'),
('20260509000100'),
('20260422000006'),
('20260422000005'),
('20260422000003'),
('20260422000002'),
('20260422000001'),
('20260421210000'),
('20260419220001'),
('20260419220000'),
('20260419120000'),
('20260416103500'),
('20260416095000'),
('20260416000700'),
('20260415234242'),
('20260415200330'),
('20260414000004'),
('20260414000003'),
('20260414000002'),
('20260414000001'),
('20250815135244'),
('20250807134608'),
('20250807132351'),
('20250807130325'),
('20231127021842'),
('20230923174851'),
('20230921163321'),
('20230919155412'),
('20230919143136'),
('20230919141554'),
('20230919131055'),
('20230918123946'),
('20230918121820'),
('20230912012438'),
('20230912010917'),
('20230912003141'),
('20230912002111'),
('20230909014633'),
('20230907200838'),
('20230907200211'),
('20230907172508'),
('20230907131506'),
('20230906121904'),
('20230906014033'),
('20230905174333'),
('20230905003336'),
('20230904233750'),
('20230904225954'),
('20230904014218'),
('20230903073955'),
('20230823231553'),
('20230821124837'),
('20230820215219'),
('20230820215212'),
('20230820215037'),
('20230820214911'),
('20230819014230'),
('20230818184509'),
('20230818184255'),
('20230818145835'),
('20230818024756'),
('20230818014957'),
('20230818014523');

