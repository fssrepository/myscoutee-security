# MyScoutee Security Assessment guide

The English, MyScoutee-branded PDF: [MyScoutee Security Assessment Guide](MyScoutee_Security_Assessment_Guide_EN.pdf).
Document ID: `MSC-SEC-001`; version: `1.5.0`.

Regenerate from the security repository root:

```sh
python3 guides/publication/manuals/build-guide.py
```

The editable generator is `build-guide.py`; the brand asset is `assets/heart.png`.
ReportLab and DejaVu fonts are required. The PDF distinguishes current product
controls from candidate integrations and includes a practical security
workday, a beginner glossary, capability components, WAF and ZAP methodology,
OWASP Top 10:2025 and API Security Top 10:2023 examples tied to MyScoutee,
practical NIST CSF 2.0 and OWASP ASVS/WSTG/SAMM/Logging/CRS guidance,
the full 21-area security stack with components, test methods, and MyScoutee
relevance, and a finding-triage example. When a scanner, application
connection, or configuration changes, update the generator, document version,
and PDF together. The internal integration plan is in
`../../development/security/README.md`.
