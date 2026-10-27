# MyScoutee Security Assessment - integration points and evidence

These internal notes provide the decision basis for product security checks. The
publishable technical guide lives in `../../publication/manuals/`. A scanner
check does not imply that the product uses the tool. Use the
[ordered assessment plan](test-plan.md) for the sequence and the
[assessment results](assessment-results.md) for current progress and next action.

## Current verified boundaries

| Area | Owner | Status |
| --- | --- | --- |
| HTTP entry and authorization | `myscoutee-backend/server/projects/profile` | `WebSecurityConfig` and the policy layer belong to the product. |
| Second factor | `myscoutee-2fa` | Standalone Go API supports TOTP, WebAuthn, and recovery codes; MyScoutee login does not call it yet. |
| Code quality | `myscoutee-sonarqube` | Separate, manually started SonarQube scan. |
| Elastic lab | `myscoutee-elastic` | CodeForge source search and Elastic telemetry; currently not a MyScoutee SIEM. |
| CI and release | `myscoutee-ci`, backend packaging | Release credential audit; frontend CodeQL; inactive backend Dependabot example. |
| Backups | Deployment and backend packaging | Recovery follows the owning deployment or host process; no separate MSC-130 restore exercise is selected. |

## Runnable assessment routes

| Check | Input | Evidence | Boundary |
| --- | --- | --- | --- |
| Trivy source | Explicit checkout or directory | Private JSON and HTML | Package vulnerabilities, configuration, and possible secret matches; manual triage required. |
| Trivy image | Existing local Docker image | Private JSON and HTML | Image contents; not a runtime or business-logic test. |
| ZAP baseline | Versioned MyScoutee loopback target and page markers | Private HTML and JSON | Time-limited spider and passive rules; no authenticated or active test. |
| SonarQube | Sibling repository's own runner | Results remain there | Its central server and configuration remain in that repository. |
| 2FA | Sibling repository demo | Go tests and API | No production login integration. |
| Elastic | Sibling repository lab | Kibana indexes | CodeForge events are not security incidents. |

## Potential product requirements

These examples need their own product decision and owner before integration
work. Listing them does not authorize implementation.

1. **Account takeover and privileged action:** the backend identifies the user
   and decides when another factor is required; the 2FA API verifies the proof.
   Passkey origin, recovery, rate limits, and negative authorization tests are
   needed.
2. **Release chain:** scan the actual release image with Trivy alongside the
   packaging credential audit, CodeQL, and SonarQube. Triage findings against
   the deployed version, available fix, and real exposure.
3. **Web attack surface:** run ZAP baseline against the anonymous surface of a
   dedicated test deployment. Authenticated or active testing needs separate
   fixtures, scope, and a test plan.

## Tools and replacement decisions

- **Firebase/Keycloak:** Keycloak is a replacement candidate only when a
  specific unmet identity requirement and a migration plan justify it. The
  2FA service would complement login.
- **Elastic Security/Wazuh:** a SIEM alerts on sanitized backend events; it
  cannot produce the application's business decisions on its behalf.
- **SonarQube/CodeQL/Trivy/ZAP:** these provide different evidence. Deduplicate
  overlapping findings and interpret them in MyScoutee context.
- **WAF/IDS/IPS/EDR:** network and host protection layers do not replace HTTP
  authorization rules.
- **SOAR/DLP/PAM/CSPM/CNAPP:** assess these later with specific telemetry,
  access models, and operating procedures.

## Primary sources

- OWASP ASVS 5.0: https://asvs.owasp.org/
- OWASP Logging Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- NIST CSF 2.0: https://doi.org/10.6028/NIST.CSWP.29
- ZAP Baseline: https://www.zaproxy.org/docs/docker/baseline-scan/
- Trivy: https://trivy.dev/latest/docs/
- Elastic Security: https://www.elastic.co/docs/solutions/security

The [published guide](../../publication/manuals/MyScoutee_Security_Assessment_Guide_EN.pdf)
explains these references and the other OWASP and tool sources in terms of
MyScoutee questions, evidence, and current integration status. Its examples are
assessment methods, not completed control assessments.
