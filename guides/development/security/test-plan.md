# MyScoutee security assessment plan

**Scope:** the existing MyScoutee product and this repository's assessment tools.

This is the ordered work plan for MSC-130. The [coverage matrix](coverage-matrix.md)
lists possible tools and methods; it is not an execution queue. The
[assessment results](assessment-results.md) record current states, findings,
and next actions. The [verification record](verification.md) covers earlier
laboratory tool checks.

Keep step numbers and order stable. Record new evidence and state changes in
the assessment results. Change this plan only when scope, sequence, or method
changes, and state the reason in the results.

## Execution rules

- Start with read-only review. Do not start Docker containers, an application
  stack, or a second build pipeline for steps 1 and 2.
- No separate security VM is required. Do not repeat MyScoutee KVM or Ansible
  qualification as part of this assessment.
- Before any runtime step, identify the exact target, owner, test environment,
  fixture, and available host capacity. Run only the relevant check; stop its
  processes and record the result before starting another resource-heavy check.
- Use the application's existing test owners and runners. Add a test only for a
  concrete uncovered behavior. Do not redefine authorization rules from a
  scanner result or duplicate existing test infrastructure.
- Keep raw scanner outputs in the Git-ignored `.local/` directory. Commit only
  sanitized summaries: target revision or image digest, question, result,
  limitation, owner, and follow-up.
- A finding is a question to investigate, not a confirmed vulnerability.
  A passing test proves the selected case, not the whole application.

## Ordered work

| Step | Question and action | Entry condition | Completion evidence |
| --- | --- | --- | --- |
| 1. Release image and finding triage | Identify the latest published production nginx image from its release manifest. Scan that exact digest when host capacity allows. Group duplicates, review five potentially relevant HIGH findings first, then finish the HIGH queue. | Published release digest and capacity before scanning. No KVM or Ansible qualification is needed. | Exact published image digest and matching scan target; a finding table with package, affected version, fix availability, exposure, owner, decision, and reason for every relevant HIGH finding. Record the MEDIUM/LOW backlog separately. |
| 2. Authorization coverage decision | Check whether existing tests already cover admin/operator denial, revoked sessions, workspace boundaries, integration credentials, and private media. Record a specific uncovered rule or defect if found. | Read-only backend and template review against current product rules. | A short coverage decision and a concrete missing case if one exists. |
| 3. Focused negative tests | For a rule or defect that existing tests do not cover, run one focused denial test in its owning repository. | A named actor, resource, action, expected denial, and available test environment. | Test name, expected and observed result, source revision, and focused run result. If a defect is found, fix it in the owning implementation and verify the equivalent template path where applicable. |
| 4. Security-event and sensitive-data review | Check whether existing login records can answer one detection question without exposing session credentials. Establish who can read those records and how long they are kept; decide whether an additional event is needed. | Read-only review of existing audit behavior and its access/retention policy. | A reuse/add/defer decision, permitted fields, access and retention boundary, and one testable detection question. |
| 5. Main-application passive web baseline | Run the existing ZAP baseline against the anonymous surface of a designated MyScoutee test deployment; review headers, cookies, redirects, cache behavior, and passive warnings. | The versioned loopback target passes its MyScoutee page identity check, fixture state is approved, and host capacity is available. | Target URL and revision, ZAP version, private report, triaged warnings, and confirmation that the scanner exited. |
| 6. Recovery scope decision | Decide whether this security assessment needs a recovery check beyond the deployment owner's existing backup or whole-disk recovery process. Do not run a separate restore without a named recovery question. | Read-only review of the actual deployment and backup ownership. | A reuse/skip decision and reason. Reopen only for a specific recovery gap, owner, and safe test target. |
| 7. Second-factor login integration | Define the MyScoutee login or privileged action that must require a second factor. Assess how the existing standalone 2FA service would fit the backend-owned session and recovery flow; implement and test in the product owner only when that feature is tasked. | Product task specifies actors, trigger, accepted factors, account recovery, and expected session behavior. | Integration decision and, if implemented, focused backend/template tests proving both a permitted and a denied flow. |
| 8. Security-event detection and SIEM | Define one MyScoutee detection question, then assess whether an approved, sanitized product event and a collector/rule can answer it. Compare tools only against that same event and expected alert. | Product owner defines event fields, reader, retention, trigger, and expected alert; step 4 did not supply such a contract. | Event and alert evidence with false-positive/negative review, ownership, and a reuse/integrate/defer decision. |
| 9. Existing web-edge protection | Review the nginx route inventory, rate limits, scanner IP bans, and operator blocklist. Check what each control actually detects, how it is tested, and whether any named web threat remains uncovered. | Existing nginx source and tests; a safe target only if a live check is needed. | Source and test evidence, known limits, and a reuse or focused follow-up decision. Evaluate an additional WAF engine only for a concrete unmet requirement. |

Steps 3-5 may expose defects and create their own focused implementation work.
That work follows the owning repository's instructions. The security repository
records the assessment and evidence; it does not take over product controls.

## Recording results

After each check, update the current state and add a dated entry in
[assessment-results.md](assessment-results.md) with:

1. The exact question, target revision or image digest, and environment.
2. The command or review method, including whether it started a process.
3. The observed result and private report location, if any.
4. The interpretation, limits, owner, and next action.

Do not paste credentials, raw token values, personal data, or full scanner
reports into committed documents. The [verification record](verification.md)
remains the history of laboratory tool checks.

## Additional executable tests from the full security stack

The following tests continue after step 9. Each has an observable result. A
conditional test waits for its stated fixture or owner; it does not imply that
the corresponding product or sensor has been installed. Record runs and
findings in `assessment-results.md`, never in this plan. Run one resource-heavy
tool at a time, and do not start another KVM for this list.

| Step | Test and exact question | Target, method, and entry condition | Evidence to collect |
| --- | --- | --- | --- |
| 10. Source dependency and secret scan | Do the selected source revision's dependencies, configuration, or tracked files contain a reportable vulnerability, misconfiguration, or possible secret? | Run the existing `scan-source` command separately on each named MyScoutee source tree. Exclude generated data; record the commit and Trivy version. | Private JSON/HTML, affected file or package, false-positive review, owner, and source-level fix decision. |
| 11. Remaining release images | Which packages or configuration findings occur in each accepted production service image beyond the nginx image in step 1? | Obtain each image's immutable identity from its own accepted release manifest; use the existing `scan-image` command on one locally available exact image at a time. No rebuild is required for this check. | Image digest and ID, scanner version, private report, deduplicated finding triage, and unscanned-image list. |
| 12. Existing SAST runs | Does a source analyzer identify a reachable issue in a selected backend or frontend change? | Use the owning CodeQL or SonarQube workflow and its configured rules on a recorded commit. Review one finding with the source owner; do not create another analyzer pipeline. | Rule ID, source location, reachability assessment, owner decision, and focused retest after a fix. |
| 13. Release credential audit | Does an accepted release package contain a private key, token, password, or credential-bearing file? | Run the existing packaging credential audit against a named candidate artifact; inspect matches privately without copying values into reports. | Artifact identity, audit result, match classification, owner, and removal/rebuild evidence when needed. |
| 14. Transport and HTTP policy | Does the running test entry point enforce the intended TLS/redirect policy and return the expected security headers and cookie attributes? | Read-only `curl`/TLS inspection of the designated MyScoutee KVM entry point after identifying its URL and deployed revision; compare against the gateway source policy. | Response/status samples without credentials, certificate identity/expiry, observed headers, source rule, and discrepancies. |
| 15. Network exposure and firewall | Are only intended gateway and administration ports reachable from each designated test network? | Compare the deployment owner's port inventory with guest listeners and firewall rules; if a network probe is needed, use only approved addresses and low-rate discovery on the existing test KVM. | Expected-versus-observed port table, network vantage point, rule owner, and unexpected exposure. |
| 16. Privileged access (PAM) | Who can administer the host, deployment, scanner reports, and release credentials, and can access be attributed to an individual? | Read-only review of operator identities, SSH/sudo permissions, report file modes, and access records with the deployment owner. Use a disposable account only for a later access trial. | Role-to-resource matrix, least-privilege exception, revocation path, and evidence that reports are restricted. |
| 17. Secret custody and rotation | Can one selected integration or deployment secret be located, rotated, and retired without exposing its value in logs or Git? | Trace the existing secret source, consumer, file permissions, and documented rotation path. Perform an actual rotation only in a safe fixture with the owning service. | Custody diagram, permitted readers, expiry/rotation owner, old-secret rejection and new-secret acceptance if exercised. |
| 18. Sensitive-data egress (DLP) | Does one controlled personal-data marker appear in an unauthorized log, export, scanner report, or response? | Classify one MyScoutee field and run a synthetic marker through an approved test account/fixture; inspect only the named output locations. Do not use real personal or payment data. | Data-flow map, allowed destinations, marker presence/absence, reader/retention boundary, and source owner. |
| 19. Deployment posture (CSPM/CNAPP) | Do the actual Compose/Kubernetes or host manifests expose privileged containers, broad mounts, public services, or unpinned images? | Scan the deployment manifests with Trivy configuration checks and review the effective test deployment with its owner. Cloud-only checks apply only if MyScoutee uses that cloud control plane. | Manifest revision, effective setting, policy rationale, exception owner, and corrected configuration check. |
| 20. Authenticated DAST | Can a designated ordinary account reach another actor's named private resource or privileged function through the running app? | On an isolated MyScoutee fixture, use two disposable actors and a focused ZAP/manual request sequence. Set request limits and expected denial before testing; keep tokens private. | Actor/resource/action, exact request class, expected and observed status/data, ZAP report if used, and owning backend test. |
| 21. Host/service vulnerability scan | Does a named guest or exposed service advertise a vulnerable version or unsafe configuration? | Schedule a bounded Greenbone/OpenVAS scan of a disposable or specifically approved MyScoutee test target when host capacity allows; confirm service inventory first. | Target and scan profile, private report, version validation, false-positive triage, and source/deployment owner. |
| 22. IDS detection | Does a Suricata rule alert on a controlled suspicious trace while leaving an ordinary MyScoutee request trace quiet? | Replay sanitized PCAPs offline on a dedicated sensor fixture; no live packet capture or new KVM is needed for the first check. | PCAP origin and sanitization, rule ID, alert/no-alert comparison, tuning decision, and false positives. |
| 23. IPS blocking | Does a selected network rule block the controlled bad flow while allowing a normal gateway flow? | Run Suricata in prevention mode only on an isolated, disposable network path with a rollback path; do not insert it into the running KVM gateway. | Before/after connectivity, rule/action, benign-flow result, rollback result, and operator owner. |
| 24. NDR visibility | Which service-to-service flows and unexpected destinations can Zeek describe from a controlled MyScoutee network trace? | Analyze a sanitized offline PCAP from a named test topology, with capture scope and retention agreed before collection. | Zeek flow/DNS/HTTP metadata, expected topology comparison, blind spots from encryption, and sensitive-field review. |
| 25. EDR host signal | Does a host sensor detect a benign canary process or file event on a designated disposable MyScoutee-like host? | Install a Wazuh/Elastic Defend candidate only on a dedicated lab host; run one documented harmless event and remove the agent afterward. | Agent/version, host baseline, event-to-alert path, false-positive assessment, overhead, and cleanup. |
| 26. Cross-source correlation (XDR) | Can a synthetic gateway event and a controlled host/network event be linked to the same incident without falsely joining unrelated actors? | Use sanitized output from steps 22–25 in an isolated correlation fixture. This proves a tool workflow, not a MyScoutee product event or deployed XDR. | Join keys and time window, matched/unmatched examples, alert rationale, and data-access boundary. |
| 27. Alert triage and response (SOC/SOAR) | Can an analyst turn one real scanner finding or synthetic alert into a justified, reviewable action? | Run a tabletop with the source owner: validate target, deduplicate, assess impact, choose containment and approval, then rehearse a dry-run playbook. Do not revoke live accounts or keys. | Finding record, decision owner, approved action and rollback, timestamps, and retest condition. |
| 28. Threat-intelligence enrichment | Does an indicator add useful context to a specific controlled alert, and is it removed when stale? | Enrich one synthetic IP/domain/hash with a documented MISP/OpenCTI feed in an isolated fixture; compare it with a harmless indicator. | Source, confidence, expiry, false-match review, analyst decision, and deletion/retention policy. |
| 29. Optional broader WAF | Does a named request-payload threat evade the existing nginx route/rate/IP controls, and would a compatible WAF rule catch it without breaking normal flows? | First establish the gap in step 9. Then test a compatible engine and OWASP CRS in observation mode on an isolated gateway fixture; replay normal login, OAuth, upload, media, and API traffic plus one controlled test request. | Matched rule, benign false positives, sensitive log fields, latency, rollback, and an integrate/reject decision. |

Step 7 remains in the separate 2FA session. Step 6 already records the decision
to leave whole-installation backup and recovery with the deployment owner. Step
8 remains conditional on a product-owned event contract; step 26 tests only an
isolated correlation fixture. These boundaries do not prevent the independent
tests above from being specified and run when their stated targets are ready.
