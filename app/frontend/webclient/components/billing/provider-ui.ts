export type BillingProviderUiProfile = {
    key: string;
    displayName: string;
    subtitle: string;
    icon: string;
    supportsInlineCardForm: boolean;
    supportsWalletCheckout: boolean;
    sdkPublicKey: string;
    secureBadgeText: string;
    subscribeDescription: string;
    checkoutCta: string;
    checkoutLoadingCta: string;
    walletCta: string;
    walletLoadingCta: string;
    cardCta: string;
    cardLoadingCta: string;
    supportedRegions: string[];
    checkoutType: string;
};

const PROVIDER_LABELS: Record<string, string> = {
    mercado_pago: 'Mercado Pago',
    lemon_squeezy: 'Lemon Squeezy',
    stripe: 'Stripe',
    paypal: 'PayPal',
    google_play: 'Google Play',
};

export const formatProviderLabel = (provider?: string | null): string => {
    const key = String(provider || '').trim().toLowerCase();
    if (!key) return 'N/A';
    if (PROVIDER_LABELS[key]) return PROVIDER_LABELS[key];

    return key
        .split('_')
        .map((token) => token.charAt(0).toUpperCase() + token.slice(1))
        .join(' ');
};

const baseProfile = (providerKey: string): BillingProviderUiProfile => {
    const providerLabel = formatProviderLabel(providerKey);

    return {
        key: providerKey,
        displayName: providerLabel,
        subtitle: 'Suscripción recurrente mensual',
        icon: 'credit-card',
        supportsInlineCardForm: false,
        supportsWalletCheckout: false,
        sdkPublicKey: '',
        secureBadgeText: 'Pagos procesados de forma segura',
        subscribeDescription: `Continúa con ${providerLabel} para activar tu membresía.`,
        checkoutCta: `Continuar con ${providerLabel}`,
        checkoutLoadingCta: 'Abriendo pasarela de pago...',
        walletCta: `Pagar con saldo de ${providerLabel}`,
        walletLoadingCta: 'Abriendo checkout...',
        cardCta: 'Suscribirse con tarjeta',
        cardLoadingCta: 'Procesando tarjeta...',
        supportedRegions: [],
        checkoutType: 'redirect',
    };
};

export const buildBillingProviderUiProfile = (
    providerKey: string,
    siteSettings: Record<string, any> | null | undefined,
): BillingProviderUiProfile => {
    const key = String(providerKey || 'mercado_pago').trim().toLowerCase();
    const profile = baseProfile(key);

    if (key === 'mercado_pago') {
        const mercadoPagoPublicKey = String(siteSettings?.mercadopago_public_key || '').trim();

        return {
            ...profile,
            subtitle: 'Tarjetas locales, Dinero en cuenta',
            icon: 'credit-card',
            supportsInlineCardForm: Boolean(mercadoPagoPublicKey),
            supportsWalletCheckout: true,
            sdkPublicKey: mercadoPagoPublicKey,
            secureBadgeText: 'Pagos protegidos y procesados por Mercado Pago',
            subscribeDescription: 'Completa tus datos o continúa en Mercado Pago para activar tu suscripción.',
            checkoutCta: 'Continuar con Mercado Pago',
            checkoutLoadingCta: 'Abriendo Mercado Pago...',
            walletCta: 'Usar saldo de Mercado Pago',
            walletLoadingCta: 'Abriendo Mercado Pago...',
            cardCta: 'Suscribirme con tarjeta',
            cardLoadingCta: 'Procesando tarjeta...',
            supportedRegions: ['AR', 'BR', 'CL', 'CO', 'MX', 'PE', 'UY'],
            checkoutType: 'redirect',
        };
    }

    if (key === 'paypal') {
        return {
            ...profile,
            subtitle: 'Saldo PayPal, Tarjetas de débito y crédito',
            icon: 'credit-card',
            supportsInlineCardForm: false,
            supportsWalletCheckout: true,
            sdkPublicKey: '',
            secureBadgeText: 'Pagos seguros y cifrados por PayPal',
            subscribeDescription: 'Continúa con PayPal para autorizar tu suscripción segura.',
            checkoutCta: 'Continuar con PayPal',
            checkoutLoadingCta: 'Abriendo PayPal...',
            walletCta: 'Pagar con saldo de PayPal',
            walletLoadingCta: 'Abriendo PayPal...',
            cardCta: 'Suscribirse con tarjeta en PayPal',
            cardLoadingCta: 'Procesando...',
            supportedRegions: [],
            checkoutType: 'redirect',
        };
    }

    if (key === 'lemon_squeezy') {
        return {
            ...profile,
            subtitle: 'Tarjetas internacionales, Apple Pay',
            icon: 'credit-card',
            supportsInlineCardForm: false,
            supportsWalletCheckout: false,
            sdkPublicKey: '',
            secureBadgeText: 'Pagos internacionales por Lemon Squeezy',
            subscribeDescription: 'Continúa con Lemon Squeezy para activar tu suscripción.',
            checkoutCta: 'Continuar con Lemon Squeezy',
            checkoutLoadingCta: 'Abriendo checkout...',
            walletCta: 'Pagar con Apple Pay / Tarjeta',
            walletLoadingCta: 'Abriendo...',
            cardCta: 'Suscribirse con tarjeta',
            cardLoadingCta: 'Procesando...',
            supportedRegions: [],
            checkoutType: 'redirect',
        };
    }

    if (key === 'google_play') {
        return {
            ...profile,
            subtitle: 'Facturación directa mediante Google Play Store',
            icon: 'smartphone',
            supportsInlineCardForm: false,
            supportsWalletCheckout: false,
            sdkPublicKey: '',
            secureBadgeText: 'Procesado por Google Play',
            subscribeDescription: 'Suscríbete desde la app Android para activar tu membresía.',
            checkoutCta: 'Abrir app para suscribirse',
            checkoutLoadingCta: 'Abriendo Google Play...',
            walletCta: 'Usar billetera móvil',
            walletLoadingCta: 'Abriendo...',
            cardCta: 'Suscribirse con tarjeta',
            cardLoadingCta: 'Procesando...',
            supportedRegions: [],
            checkoutType: 'redirect',
        };
    }

    return profile;
};
