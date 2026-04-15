export type BillingProviderUiProfile = {
    key: string;
    displayName: string;
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
};

const PROVIDER_LABELS: Record<string, string> = {
    mercado_pago: 'Mercado Pago',
    lemon_squeezy: 'Lemon Squeezy',
    stripe: 'Stripe',
    paypal: 'PayPal',
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
        supportsInlineCardForm: false,
        supportsWalletCheckout: false,
        sdkPublicKey: '',
        secureBadgeText: '',
        subscribeDescription: `Continue with ${providerLabel} to activate your subscription.`,
        checkoutCta: `Continue in ${providerLabel} checkout`,
        checkoutLoadingCta: 'Opening checkout...',
        walletCta: `Pay with ${providerLabel} balance`,
        walletLoadingCta: 'Opening wallet checkout...',
        cardCta: 'Subscribe with card',
        cardLoadingCta: 'Processing card...',
    };
};

export const buildBillingProviderUiProfile = (
    providerKey: string,
    siteSettings: Record<string, any> | null | undefined,
): BillingProviderUiProfile => {
    const key = String(providerKey || 'mercado_pago').trim().toLowerCase();
    const profile = baseProfile(key);

    if (key !== 'mercado_pago') {
        return profile;
    }

    const mercadoPagoPublicKey = String(siteSettings?.mercadopago_public_key || '').trim();

    return {
        ...profile,
        supportsInlineCardForm: Boolean(mercadoPagoPublicKey),
        supportsWalletCheckout: true,
        sdkPublicKey: mercadoPagoPublicKey,
        secureBadgeText: 'Card tokenization powered by MercadoPago.js',
        subscribeDescription: 'Complete your payment details or continue in checkout to activate your subscription.',
        checkoutCta: 'Continue with Mercado Pago checkout',
        checkoutLoadingCta: 'Opening checkout...',
        walletCta: 'Use Mercado Pago balance',
        walletLoadingCta: 'Opening Mercado Pago wallet...',
        cardCta: 'Subscribe with card',
        cardLoadingCta: 'Processing card...',
    };
};
