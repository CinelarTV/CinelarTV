# Manual de operación: suscripciones de CinelarTV

Este manual describe el sistema de suscripciones implementado en CinelarTV. Léase junto con [la decisión arquitectónica](SUBSCRIPTION_ARCHITECTURE.md).

## 1. Modelo operativo

Hay una sola oferta: `cinelartv_membership_monthly`. No se crean ni se administran planes desde CinelarTV ni desde la UI administrativa.

Una persona obtiene acceso si ocurre una de estas condiciones:

* tiene una fila `subscriptions` con `access_until >= ahora`;
* tiene un `subscription_access_grant` vigente creado por un administrador.

Una concesión no es una suscripción de pago y no debe etiquetarse como Mercado Pago, Lemon Squeezy u otro proveedor.

Estados locales:

| Estado | Significado | Acceso |
|---|---|---|
| `pending` | checkout/primer cobro aún no confirmado | no |
| `active` | cobro y período confirmados | hasta `access_until` |
| `past_due` | cobro fallido; está en gracia | hasta `grace_ends_at` |
| `cancelled` | no se renovará | hasta final del período ya pagado |
| `expired` | finalizó el acceso | no |

No se debe editar SQL ni cambiar un estado manualmente para dar acceso. Use una concesión.

## 2. Instalación

En una instalación nueva o de desarrollo:

```powershell
bundle install
pnpm install
bundle exec rails db:migrate
pnpm run i18n:export
bundle exec rails server -b 0.0.0.0
bundle exec sidekiq -C config/sidekiq_general.yml
```

Compruebe que el scheduler está habilitado en Sidekiq. `ReconcileSubscriptionsJob` se ejecuta cada 15 minutos; es el seguro ante un webhook perdido o fuera de orden.

## 3. Configuración de la única oferta

En Administración → Configuración, establezca:

| Ajuste | Ejemplo | Regla |
|---|---|---|
| `enable_subscription` | `true` | activar sólo tras probar sandbox |
| `subscription_amount_cents` | `39000` | entero en centavos; no usar decimales |
| `subscription_currency` | `UYU` | ISO-4217 de tres letras |
| `subscription_interval_unit` | `month` | `month` o `year` |
| `subscription_interval_count` | `1` | entero positivo |
| `subscription_provider_primary` | `mercado_pago` | proveedor elegido por defecto |

Los términos se copian a cada `Subscription` al iniciar checkout. Por ello un cambio de precio afecta sólo altas nuevas, no modifica accidentalmente contratos activos.

## 4. Configurar Mercado Pago

1. Cree una aplicación de Mercado Pago y habilite credenciales de prueba.
2. Guarde `mercadopago_access_token`, `mercadopago_public_key`, `mercadopago_application_id` y, si aplica, `mercadopago_site_id`.
3. Active `enable_mercado_pago_provider`.
4. Configure `mercadopago_webhook_secret` y una URL pública HTTPS: `POST /subscriptions/webhooks/mercado_pago`.
5. Suscríbase a `payment`, `subscription_preapproval` y `subscription_authorized_payment`.
6. Pruebe una suscripción sandbox completa: alta, cancelación, pago rechazado y webhook duplicado.

Use exclusivamente la API programable `preapproval`/`preapproval_plan`. No cree la oferta en “Subscription Plans” manuales del Dashboard y luego intente usarla como fuente de datos de CinelarTV.

## 5. Configurar Lemon Squeezy

1. Configure `lemonsqueezy_api_key`, `lemonsqueezy_store_id`, `lemon_squeezy_plan_id` y `lemonsqueezy_webhook_secret`.
2. Active `enable_lemon_squeezy_provider`.
3. Registre `POST /subscriptions/webhooks/lemon_squeezy` y seleccione eventos de subscription y payment.
4. Haga una compra sandbox y confirme que el evento contiene el `subscription_id` custom para correlacionar con CinelarTV.

Para Stripe, PayPal o Paddle, implemente el mismo puerto de provider (`start_checkout`, `fetch_remote_subscription`, `cancel`, verificación y procesamiento webhook). No agregue condiciones de provider a controladores o Vue.

## 6. Operación diaria

### Usuario

El usuario entra a **Cuenta → Facturación**, inicia checkout y vuelve a una pantalla de verificación. Un `return_url` no activa acceso: lo activan un recurso remoto confirmado y webhook/reconciliación.

Cancelar mantiene el acceso hasta `access_until`. Si el proveedor sólo admite cancelación inmediata, informar claramente antes de ejecutar esa acción.

### Administrador

La pantalla de Suscripciones tiene tres vistas relevantes:

* **Resumen:** totales y recaudación confirmada del mes.
* **Suscripciones:** búsqueda, cancelación, sincronización y creación de concesiones.
* **Registros:** eventos recibidos, pendientes o fallidos.

Para otorgar acceso editorial/promocional: cree una concesión con motivo y fecha de vencimiento. Para resolver un problema de provider: abra la suscripción y pulse **Sincronizar**. No cambie montos ni períodos en el Dashboard del provider salvo bajo un incidente documentado.

## 7. Webhooks, reintentos y reconciliación

El endpoint valida la firma, persiste el payload y cabeceras sanitarias en `provider_events`, responde rápido y delega el procesamiento a Sidekiq.

Si llega dos veces el mismo evento, los índices únicos lo descartan. Si llega fuera de orden, `remote_updated_at` evita que un estado anterior sobrescriba uno nuevo. Si no llega, el reconciliador recupera el recurso canónico del proveedor.

Runbook para un evento fallido:

1. Abra Registros y confirme firma, provider, tipo y resource ID.
2. Verifique las credenciales/secret y la URL HTTPS en el provider.
3. Consulte la suscripción remota con el ID almacenado.
4. Use **Sincronizar**. Corrija el adapter si el snapshot no mapea correctamente.
5. Reprocese sólo después de identificar el problema; no altere pagos manualmente.

## 8. Incidentes financieros

* **Cobro aprobado sin acceso:** sincronice la suscripción; verifique `payments` y `access_until`. Si el provider confirma el pago pero los términos no coinciden, marque el incidente y no habilite acceso automáticamente.
* **Usuario con acceso tras rechazo:** es esperable hasta `grace_ends_at`. Pida cambio de método; el proveedor ejecuta sus reintentos.
* **Cancelación inesperada desde Dashboard:** reconciliación la importa. Preserve el registro/auditoría y comuníquese con la persona afectada.
* **Webhook inválido:** no reintentar el cuerpo a ciegas. Revise secret, algoritmo y hora del servidor.

## 9. Datos y seguridad

No guardar PAN, CVV, tokens reutilizables ni secretos en `provider_metadata`, logs o eventos. Los secretos pertenecen a Site Settings/gestor de secretos. Limitar acceso administrativo a logs porque contienen metadata de proveedores.

Los pagos son un ledger: no se borran ni se reescriben para “arreglar” un total. Registrar refunds/disputes como nuevos hechos del proveedor.

## 10. Checklist de salida a producción

- [ ] Migraciones aplicadas y backup verificado.
- [ ] Credenciales de producción separadas de sandbox.
- [ ] Firma de webhook habilitada; no dejar secretos vacíos.
- [ ] URL HTTPS pública, con prueba de delivery y reintento.
- [ ] Sidekiq/scheduler funcionando y cola `subscriptions` monitorizada.
- [ ] Alta, primer fallo, renovación, rechazo, cambio de método, cancelación y evento duplicado probados.
- [ ] Alertas por `provider_events.processing_error`, reconciliación atrasada y `past_due` prolongado.
- [ ] Acceso de admin y retención de logs revisados.
