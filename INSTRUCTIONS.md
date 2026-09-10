# INSTRUCTIONS

**Stand:** 06.05.2026 13:51 Uhr MESZ  
**Zweck:** Kurze CORE-Regeln für dieses Repository

---

## CORE-Regeln

- AGENTS.md ist nur die kurze Brücke; führende Regeldatei ist INSTRUCTIONS.md im Repository-Root.
- Deutsch schreiben; Umlaute und ß korrekt verwenden.
- Textdateien als UTF-8 mit BOM speichern und nach Änderungen `rg "\x{FFFD}|\x{00C3}|\x{00E2}|\x{251C}"` ausführen.
- Keine Secrets in Code, Dateien oder Dokumentation ablegen.
- Secrets nur über User Secrets für lokale Entwicklung und über Environment Variables oder Secret Stores für produktive Umgebungen verwalten; niemals in `appsettings.json` oder im Code ablegen.
- Qualität vor Geschwindigkeit: erst prüfen, dann ändern, dann warning-frei validieren.
- Keine Begriffe wie `Team`, `Executive Summary` oder `ROI` verwenden.
- Keine exakten Zeitangaben in Tagen, Wochen oder Stunden; nur qualitative Aufwandskategorien.
- Die Kauf- und Berechtigungsprüfung läuft über die Microsoft Marketplace Fulfillment API; keine lokale JSON- oder Dateispeicherung für Purchases oder Subscriptions wieder einführen.
- Relevante Services für die Marketplace-Logik sind `MarketplaceAuthService`, `MarketplaceApiService` und `RealTimePurchaseVerificationService`.
- Der Webhook-Endpunkt `/api/MarketplaceWebhook` hält Cache und Abonnementstatus konsistent und gehört bei Änderungen an der Verifizierungslogik mit betrachtet.

---

## On-demand Referenzen

- `README.md`
- `src/BacpacCompatFixer.Blazor/SECRETS_MANAGEMENT.md`
- `src/BacpacCompatFixer.Blazor/README_DOCUMENTATION_INDEX.md`
- `Docs/`

---

**Erstellt von:** Michael Breukel  
**Letzte Aktualisierung:** 06.05.2026 13:51 Uhr MESZ
