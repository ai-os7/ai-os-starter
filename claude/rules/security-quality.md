---
description: OWASP Top 10 Checklist, Quality Gates, Code Review Trigger, Input Validation
---

# Security & Quality

## Credentials — NIEMALS / STATTDESSEN

| ❌ NIEMALS | ✅ STATTDESSEN |
|-----------|----------------|
| API-Keys in Code/Workflows | Environment Variables / Credentials Manager |
| Secrets in Git commiten | `.gitignore` + Secret Manager |
| Hardcoded URLs mit Auth | Credential-Referenzen |
| Tokens in Logs ausgeben | Maskierte Ausgabe |

**Vor jedem Commit prüfen:**
```bash
git diff --cached | grep -iE "(api.?key|secret|password|token|bearer)"
```

## Input Validation

- **Webhooks:** Signature-Validierung (HMAC) wo möglich
- **User Input:** Immer sanitizen, nie direkt in Queries/Code
- **URLs:** Nur HTTPS, Domain-Whitelist für Redirects
- **File Uploads:** Type-Check, Size-Limits, keine Execution

## OWASP Top 10 (bei Code-Erstellung mental durchgehen)

| # | Risiko | Maßnahme |
|---|--------|----------|
| 1 | Injection | Parameterized queries, kein String-Concat |
| 2 | Broken Auth | Session-Management, Token-Expiry |
| 3 | Sensitive Data | Encryption at rest + transit |
| 4 | XXE | XML-Parser sicher konfigurieren |
| 5 | Broken Access Control | Authorization auf Server, nicht Client |
| 6 | Security Misconfig | Keine Default-Credentials, Headers setzen |
| 7 | XSS | Output encoding, CSP-Headers |
| 8 | Insecure Deserialization | JSON bevorzugen, Typen validieren |
| 9 | Vulnerable Components | Dependencies aktuell halten |
| 10 | Logging | Audit-Trail, aber keine Secrets loggen |

## Quality Gates (vor Abschluss einer Aufgabe)

```
□ Happy Path funktioniert?
□ Edge Cases abgedeckt? (Leere Inputs, Nulls, Timeouts)
□ Error Handling vorhanden? (Nicht silent fail)
□ Testbar? (Manuell oder automatisiert)
□ Security-Review gemacht?
```

## Code Review Trigger

Automatisch `feature-dev:code-reviewer` aufrufen bei:
- Neuer Endpoint / Webhook
- Authentifizierung / Authorization Änderungen
- Datenbank-Schema Änderungen
- External API Integration
- File/Upload Handling
