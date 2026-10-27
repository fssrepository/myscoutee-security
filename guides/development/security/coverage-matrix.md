# Security stack coverage matrix - MyScoutee

This is a decision inventory, not a claim that every component is installed.
`Runnable` means the assessment repository has a verified command. `Sibling` means
another MyScoutee repository owns an implementation. `Candidate` needs a
separate scoped experiment. `Method` is assessed through documents and tests.

| Area | Kind | Candidate or owner | Concrete MyScoutee use case | Status / decision |
| --- | --- | --- | --- | --- |
| IAM | Product control | Firebase + backend session/policy; Keycloak candidate | Member, workspace, admin, and operator authority | Existing owner. Compare Keycloak only against a missing identity requirement and migration cost. |
| MFA / passkeys | Product control | `myscoutee-2fa` | Second factor for privileged access | Sibling runs independently; backend integration pending. |
| PAM | Host access | Dedicated operator identities, SSH access controls; Teleport candidate | Privileged host and deployment access | Candidate after access inventory. |
| Firewall | Host/network control | Existing host and proxy rules | Limit public and private ports | Assess actual deployment rules; no duplicate firewall in this repo. |
| WAF / web-edge filtering | Edge control | Existing MyScoutee nginx route inventory, rate limits, scanner IP bans, and operator blocklist; CRS/ModSecurity only if a gap warrants it | Reject route probing and abusive rates at the public edge | Existing targeted controls are source-verified; generic request-body attack rules are not part of them. Backend policy remains authoritative. |
| IDS / IPS | Network control | Suricata candidate | Detect or block suspicious lab traffic | Candidate on isolated network only. |
| NDR | Network analysis | Zeek candidate | Understand traffic patterns between services | Candidate; needs explicit capture scope. |
| EDR | Endpoint control | Elastic Defend or Wazuh agent candidate | Host process and file activity | Candidate on a dedicated lab host. |
| XDR | Cross-source analysis | Elastic Security or Wazuh candidate | Correlate endpoint, identity, and network signals | Candidate after event sources exist. |
| SIEM | Event platform | Elastic Security or Wazuh candidate | Alert on repeated auth failures and privileged changes | Candidate; current CodeForge Elastic lab is not a SIEM. |
| SOAR | Response workflow | Documented playbook, later automation | Revoke a compromised integration key after verified incident | Method first; automation only after validated alerts and authority. |
| SAST | Source check | Frontend CodeQL; `myscoutee-sonarqube` | Java/TypeScript bug and vulnerability patterns | Sibling/existing workflow. Preserve their ownership. |
| SCA | Dependency check | Trivy; inactive Dependabot example | Known vulnerabilities in dependencies | Runnable Trivy; hosted Dependabot not enabled. |
| Image scan | Artifact check | Trivy | Exact release image packages and secrets | Runnable on a local image. |
| Secret scan | Source/artifact check | Trivy; existing package credential audit | Accidental token or private key inclusion | Runnable Trivy; release audit remains separate. |
| DAST | Running app check | ZAP baseline | Anonymous web response headers and passive signals | Runnable for versioned MyScoutee loopback target; authenticated/active scope pending. |
| Vulnerability scanning | Host/network check | Greenbone/OpenVAS candidate | Guest and exposed service configuration | Candidate with lab target and scan window. |
| DLP | Data governance/control | Classification and export policy first | Personal data in logs, reports, or exports | Method first; product selection requires data-flow inventory. |
| Secrets management | Key custody | Existing deployment secret files; Vault candidate | API, release, and database keys | Assess existing custody/rotation before new server. |
| Threat intelligence | Input to detections | MISP/OpenCTI candidate | Enrich a verified indicator in an incident | Candidate; useful only with clear response use case. |
| CSPM / CNAPP | Cloud posture | Trivy config and deployment-owner checks; platform candidates | KVM/Kubernetes/cloud configuration drift | Method + targeted checks; match the deployment actually used. |
| Backup / recovery | Resilience | Deployment or host backup process; packaging tools where used | Recovery of the actual installation | Deployment-owned. Separate restore skipped for MSC-130 without a named recovery gap. |
| SOC | Operating function | Owner-run review and incident queue | Triage and follow-up of real alerts | Method. A dashboard alone is not an operating function. |
| DevSecOps | Development method | CI, CodeQL, SonarQube, release checks | Trace finding to fix and qualification | Method across existing owners. |
| Zero Trust | Architecture principle | Existing request/session/policy checks | Verify actor and resource on each sensitive request | Method; assess selected flows, not a new product. |
| GRC / NIST CSF | Risk method | NIST CSF 2.0, OWASP ASVS 5.0 | Prioritize controls and show evidence | Method. Use concise project-specific control cards. |

## Execution order

Use the [ordered assessment plan](test-plan.md) for the next step, prerequisites,
completion evidence, and status. This matrix is a capability inventory, not a
second work queue.

Primary sources: [NIST CSF](https://doi.org/10.6028/NIST.CSWP.29),
[OWASP ASVS](https://asvs.owasp.org/),
[ZAP baseline](https://www.zaproxy.org/docs/docker/baseline-scan/),
[Trivy](https://trivy.dev/latest/docs/),
[Elastic Security](https://www.elastic.co/docs/solutions/security), and
[Wazuh](https://documentation.wazuh.com/current/getting-started/components/index.html).
