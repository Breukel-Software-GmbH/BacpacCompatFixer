# 🏗️ Architektur-Übersicht: API-basierte Subscription-Verifizierung

> Die Diagramme sind in Mermaid verfasst und werden von GitHub direkt gerendert.

## 🔄 Login-Flow

```mermaid
flowchart TD
    A["User Login<br/>user@example.com"] --> B["RealTimePurchaseVerificationService<br/>VerifyPurchaseAsync()"]
    B --> C{"Cache vorhanden?<br/>Memory Cache, 5 Min"}
    C -- Hit --> D["Gecachten UserPurchaseStatus zurückgeben"]
    C -- Miss --> E["MarketplaceAuthService<br/>GetAccessTokenAsync()"]
    E --> F{"Token-Cache gültig?<br/>~55 Min"}
    F -- Ja --> G["Gecachten Token verwenden"]
    F -- Nein --> H["POST /oauth2/v2.0/token<br/>grant_type: client_credentials"]
    H --> I["Token 55 Min cachen"]
    I --> J["MarketplaceApiService<br/>GetSubscriptionByUserEmailAsync()"]
    G --> J
    J --> K["GET /api/saas/subscriptions"]
    K --> L["Filter: beneficiary.emailId == user<br/>saasSubscriptionStatus == Subscribed"]
    L --> M{"IsPremiumPlan(planId)?<br/>PremiumPlanIds aus appsettings.json"}
    M -- Ja --> N["UserPurchaseStatus<br/>HasPurchased=true, Status=Active<br/>MaxFileSizeBytes=5GB"]
    M -- Nein --> O["UserPurchaseStatus<br/>Free Tier, MaxFileSizeBytes=500MB"]
    N --> P["Ergebnis 5 Min cachen"]
    O --> P
    P --> Q["An die Anwendung zurückgeben"]
```

Details:

- `PremiumPlanIds` (appsettings.json): `["premium", "pro", "enterprise"]`
- Beispiel-Antwort der API:

```json
{
  "subscriptions": [
    {
      "id": "sub-123",
      "planId": "premium",
      "saasSubscriptionStatus": "Subscribed",
      "beneficiary": { "emailId": "user@example.com" }
    }
  ]
}
```

## 🧩 Komponenten-Diagramm

```mermaid
flowchart TD
    subgraph Blazor["BLAZOR APPLICATION"]
        UI["Blazor Components / Controllers<br/>Upload.razor, AccountController.cs"]
        SVC["RealTimePurchaseVerificationService<br/>VerifyPurchaseAsync()<br/>GetSubscriptionByIdAsync()<br/>UpdateSubscriptionAsync()<br/>IsPremiumPlan()"]
        API["MarketplaceApiService<br/>GetAllSubs() / GetSubById() / GetSubByEmail()"]
        CACHE["IMemoryCache<br/>5 Min Cache"]
        AUTH["MarketplaceAuthService<br/>GetAccessToken()"]
        UI -->|"Inject IPurchaseVerificationService"| SVC
        SVC -->|Uses| API
        SVC -->|Uses| CACHE
        API -->|Uses| AUTH
    end
    subgraph MS["MICROSOFT SERVICES"]
        AAD["Azure Active Directory<br/>POST /oauth2/v2.0/token<br/>Returns: Access Token (60 min)"]
        MKT["Marketplace Fulfillment API<br/>GET /api/saas/subscriptions<br/>GET /api/saas/subscriptions/{id}"]
        WH["Marketplace Webhook Service<br/>POST /api/marketplacewebhook<br/>Sends: Subscription Change Events"]
    end
    AUTH -->|"HTTP Requests"| AAD
    API -->|"HTTP Requests"| MKT
    WH -->|"HTTP Requests"| SVC
```

## 🪝 Webhook-Integration

```mermaid
sequenceDiagram
    participant MP as Microsoft Marketplace
    participant WH as MarketplaceWebhookController
    participant SVC as RealTimePurchaseVerificationService
    participant C as IMemoryCache
    MP->>WH: POST /api/marketplacewebhook<br/>{ subscriptionId, planId, action, purchaser.emailId }
    WH->>WH: Validate JWT Token
    WH->>SVC: Process Event / UpdateSubscriptionAsync()
    SVC->>C: Invalidate Cache für user@example.com<br/>_cache.Remove("purchase_status_user@example.com")
    Note over C: Nächster Login lädt frische Daten von der API
```

## ⚡ Caching-Strategie

- Cache-Key: `purchase_status_{userEmail}`
- Dauer: 5 Minuten (konfigurierbar über `CacheDurationMinutes`)
- Invalidierung:
  - Automatisch nach Ablauf (5 Minuten)
  - Manuell durch Webhook-Events
  - Manuell durch `UpdateSubscriptionAsync()`

Beispiel-Timeline:

| Zeit | Ereignis | Cache | API-Call |
|------|----------|-------|----------|
| 10:00 | Erster Login | Miss | GET /api/saas/subscriptions → Premium, Cache bis 10:05 |
| 10:02 | Zweiter Login (innerhalb 5 Min) | Hit | Kein API-Call (Performance!) |
| 10:03 | Webhook: Downgrade auf Free | Invalidiert | – |
| 10:04 | Dritter Login (nach Webhook) | Miss | GET /api/saas/subscriptions → Free, Cache bis 10:09 |
| 10:06 | Vierter Login (Cache von 10:00 abgelaufen) | Miss | GET /api/saas/subscriptions → aktueller Status, Cache bis 10:11 |

## 🌳 Decision Tree: Premium vs. Free

```mermaid
flowchart TD
    A["User Login"] --> B["Subscription von API laden"]
    B --> C{"Subscription gefunden?"}
    C -- Nein --> FREE1["FREE TIER<br/>MaxFileSize: 500MB<br/>Status: Free"]
    C -- Ja --> D{"Status == Subscribed?"}
    D -- Nein --> FREE2["FREE TIER<br/>Status: Suspended/Unsubscribed"]
    D -- Ja --> E{"PlanId in PremiumPlanIds?"}
    E -- Nein --> FREE3["FREE TIER<br/>Status: Free<br/>Has non-premium plan"]
    E -- Ja --> PREMIUM["PREMIUM TIER<br/>MaxFileSize: 5GB<br/>Status: Active<br/>HasPurchased: true"]
    FREE1 --> R["Return UserPurchaseStatus"]
    FREE2 --> R
    FREE3 --> R
    PREMIUM --> R
```

## 📈 Performance-Metriken

| Szenario | Antwortzeit |
|----------|-------------|
| Cache Hit (< 5 Min) | ~1 ms |
| Cache Miss + API-Call | ~50–200 ms |
| Token Refresh (stündlich) | ~100 ms (async, 55 Min gecacht) |

API-Calls pro Stunde (100 User):

| Variante | Rechnung | API-Calls |
|----------|----------|-----------|
| Ohne Cache | 100 User × 60 Logins/Stunde | 6.000 |
| Mit 5-Min-Cache | 100 User × 12 Logins/Stunde | 1.200 |

Reduktion: **80 % weniger API-Calls** 🎉

## 🔒 Security-Flow

```mermaid
flowchart TD
    CFG["Konfiguration<br/>appsettings.json<br/>(Production: Azure Key Vault)<br/>TenantId, ClientId, ClientSecret<br/>⚠️ ClientSecret NIEMALS in Git!"] --> TOK
    TOK["Azure AD Token Request<br/>POST /{tenant}/oauth2/v2.0/token"] --> JWT
    JWT["Access Token (JWT)<br/>Gültig: 60 Minuten<br/>Gecacht: 55 Minuten<br/>Scope: Marketplace API"] --> REQ
    REQ["Marketplace API Request<br/>Authorization: Bearer {access_token}"] --> DATA
    DATA["Subscription Data<br/>Gecacht für 5 Minuten"]
```

---

**Dokumentation erstellt:** 2025-01-15  
**Version:** 2.0 (API-basiert)
