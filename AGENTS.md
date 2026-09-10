# AGENTS.md

## Geltungsbereich
Diese Datei ist die kurze Brücke für dieses Repository.

## Führende Regeldatei

- Führende CORE-Datei ist `INSTRUCTIONS.md`.
- `.github/copilot-instructions.md` verweist auf dieselbe CORE-Datei.

## Kritische Kurzregeln

- Führende Regeldatei ist `INSTRUCTIONS.md` im Repository-Root.
- `.github/copilot-instructions.md` verweist auf dieselbe CORE-Datei.
- Textdateien als UTF-8 mit BOM speichern und nach Änderungen `rg "\x{FFFD}|\x{00C3}|\x{00E2}|\x{251C}"` ausführen.
- Repo-spezifische Regeln niemals aus anderen Repositories übernehmen.
- Secrets und Marketplace-Regeln stehen führend in `INSTRUCTIONS.md`.
