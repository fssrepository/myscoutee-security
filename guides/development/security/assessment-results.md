# MyScoutee security assessment results

This file tracks dated findings and the current state of each step in the
[assessment plan](test-plan.md). The [laboratory verification record](verification.md)
contains earlier tool checks; those checks do not establish product findings.
Raw scanner reports stay in Git-ignored `.local/`.

## Current state

| Step | State | Next action |
| --- | --- | --- |
| 1. Release image and finding triage | Paused for this assessment at the user's request. Published 1.5.0 production nginx has 196 raw package alerts; the source-level 1.5.1 nginx candidate scanned clean. HIGH triage and scans of other service images remain open. | Return when the relevant package upgrades and release image inputs are available; triage the published findings and scan each other published image identity. |
| 2. Authorization coverage decision | Read-only review complete; no specific gap found in the reviewed cases. | Revisit only for a new rule or defect. |
| 3. Focused negative tests | No case selected; no test run. | Start when a concrete uncovered access rule is identified. |
| 4. Security-event and sensitive-data review | Skipped after the initial read-only review. Operator-wide login detection was not specified or developed as a MyScoutee feature. The existing account-user warning remains; the audit-retention observation is recorded below. | Reopen only if a concrete product requirement is defined. |
| 5. Main-application passive web baseline | Partially completed: ZAP 2.17.0 ran on the existing MyScoutee KVM's anonymous entry page (zero FAIL, ten WARN groups, 58 PASS rules), and the report was triaged. Two source-level improvements passed candidate gateway tests, but the running deployment has not been updated or rescanned. | Keep the step open for deployment and a same-target ZAP rerun; review the broader CSP and JavaScript signals with their source owners. |
| 6. Recovery scope decision | Skipped as a separate MSC-130 runtime test. Backup and recovery belong to the actual deployment or host process; no specific recovery gap was identified for this security assessment. | Reopen only for a named recovery requirement or defect owned by the deployment team. |
| 7. Second-factor login integration | Not started. The standalone 2FA service is not connected to MyScoutee login; no product task defines when a factor is required. | Wait for the backend-owned feature contract; then assess and test that flow in its owner. |
| 8. Security-event detection and SIEM | Not started. Step 4 found no specified operator-wide event or alert contract; the Elastic CodeForge data is not a MyScoutee security feed. | Wait for one named detection question and approved event fields, access, and retention. |
| 9. Existing web-edge protection | Source review complete; live deployment behavior not checked in this step. The nginx module already blocks scanner IPs after repeated unknown-route requests, and the gateway has rate limits plus an operator blocklist. This is targeted WAF-like filtering, not a generic payload rule set. | Reuse the existing control. Run a focused live check only if deployed behavior must be established; assess another rule engine only for a named uncovered threat. |

## Next action

Step 5 has a useful baseline but remains open until the source changes are
deployed and the same target is rescanned. Step 6 is skipped. Tasks 7 and 8
wait for product requirements. Step 9 has a source-level decision; any live
check needs a specific question. Step 1 remains paused and will be revisited.

## 2026-10-28 assessment

The source review started without a scanner, build, service, Ansible playbook,
or KVM command. The backend source was at
`62d7f776551253301eb39188dc5db419a6ff0df8`; the template source was at
`f829ec111986df4f5478bb849690e216fed026b4`. The image scan below ran later
the same day.

### Step 1: released nginx image scan

The [backend 1.5.0 release](https://github.com/fssrepository/myscoutee-backend/releases/tag/v1.5.0)
manifest identifies the production nginx image as
`ghcr.io/fssrepository/myscoutee-nginx@sha256:cf65d7676290ec0e67b1c7c27ad2e769a069bbd7bc1eed1bd03a5cf110bb5bc3`
with image ID
`sha256:831c233dcb371f89348490cedabc0e5e71ba1ab40527d9e1963f21b2140bea6a`.
The local `myscoutee-nginx:1.5.0-prod` image matched both. Running
`./lab.sh scan-image myscoutee-nginx:1.5.0-prod` completed with Trivy 0.76.1
(`vuln,misconfig,secret`). Private JSON and Trivy-template HTML are in
`.local/reports/20261028T003402Z-image-186981/` as `trivy.json` and
`trivy.html` (both mode 0600). The temporary image archive was removed and the
scanner exited.

The report contains 196 raw package alerts: 47 HIGH, 81 MEDIUM, 64 LOW, and
4 UNKNOWN, covering 126 distinct vulnerability IDs. It reports no secret or
configuration findings. These are scanner observations, not confirmed product
vulnerabilities. No finding has been triaged or marked fixed. The running KVM
was not queried.

### Step 1 follow-up: 1.5.1 nginx source candidate

The `myscoutee-nginx` source commit
`a9bcac09f14a18f76a3cfe4f821b5e5acce69f33` updates the pinned upstream
nginx image to 1.31.8, matches the native module source version and checksum,
and refreshes Alpine packages in the source Dockerfile. The official upstream
image alone still had three HIGH package alerts for `brotli-libs`, `curl`, and
`libcurl`; the Alpine 3.24 repository supplied fixed versions of all three.

The local `myscoutee-nginx:1.5.1-candidate` image was built from that source
with image ID
`sha256:50c73f8b8105466b32ed9644bb9127164d11d7bb86186adcc9a687da2f8a33e7`.
Native edge, Kubernetes, geometry, route-inventory, traffic-tool, and shell
syntax checks passed. `./lab.sh scan-image myscoutee-nginx:1.5.1-candidate`
completed with Trivy 0.76.1 (`vuln,misconfig,secret`). Its private JSON and
Trivy-template HTML are in `.local/reports/20261028T004530Z-image-199231/`.
The report has zero findings in all three scanner classes. The scanner exited;
no application service or KVM was started.

This verifies the native nginx candidate only. The published 1.5.0 production
image still has its original findings. After the 1.5.1 source is released, the
backend and template production images need to consume that release and be
scanned separately. No release or deployment was performed in this assessment.
The backend's checked-in deployment image lock lists 17 other service images;
their scan coverage remains open and requires each published image identity to
be confirmed before scanning.

### Step 1 pause

At the user's request, the remaining released-image triage and other service
image scans are paused while the assessment moves to step 4. The clean nginx
source candidate does not change the findings in the published 1.5.0 image.
Revisit the open findings when the relevant package upgrades and release image
inputs are available; prefer source-level package updates where fixed versions
exist. No finding is marked fixed by this pause.

### Step 2: authorization decision

Read-only review found existing negative tests for admin/operator access,
revoked sessions, workspace and group boundaries, integration credentials, and
private media. The template has corresponding checks. No tests were run in this
assessment, and no specific uncovered rule was identified in the reviewed
cases.

### Step 3: focused negative tests

No case was selected and no test was run in this assessment. The next trigger
is a specific access rule or defect without a matching test.

### Step 4: security-event and data decision

**Question:** Can an operator identify a newly accepted concurrent session
without receiving a session ID or bearer credential? Read-only source review of
the backend and template at `62d7f776551253301eb39188dc5db419a6ff0df8`
and `f829ec111986df4f5478bb849690e216fed026b4` found:

- The login audit stores `ACCEPTED` and `BLOCKED_LIMIT` outcomes with user and
  attempt IDs, a session ID, source address, client details, and a user-agent
  hash. The login service reads it for idempotent retries. No application audit
  read endpoint was found in the reviewed source. The Mongo initializer grants
  the application user database-level `readWrite` access, which includes these
  raw records. They are not suitable for direct operator or SIEM export.
- The existing `security-login` notification is sent to the account user for a
  newly accepted concurrent session or a session-limit block. Its payload has
  outcome, client label, and attempt ID. Existing end-to-end checks verify that
  it contains no session ID or raw user agent. The notification API resolves
  the selected profile and reads by recipient. This is a user warning, not a
  cross-account operator detection feed.
- No time-based expiry for `userLoginAudits` was found in its document/index
  definition or database initializer. The reviewed deleted-account cleanup does
  not remove this collection. A retention and deletion boundary is therefore
  not established by the current source.

**Decision:** Skip further step 4 work. Operator-wide login detection is not a
specified or implemented MyScoutee feature; its absence is not classified as a
defect by this assessment. The existing account-user warning is already in use.
The missing retention/deletion boundary for existing login-audit records remains
a source-review observation, not an operator-event implementation request. No
runtime process, live log inspection, code change, or test was part of this
review.

### Runtime boundary

The earlier ZAP run tested only the CodeForge lab. The MyScoutee KVM was not
used for steps 1-4; step 5 below used its existing deployment. Step 6 was
later scoped out as a separate recovery exercise.

### Step 5: MyScoutee anonymous web baseline

The assessment scope now identifies this repository as a product security
assessment, not a separate application lab. Its web target and MyScoutee HTML
identity markers are versioned in `config/web-baseline.json`; the ordered plan
keeps the same step number and method. The user authorized the existing
MyScoutee KVM as the test target. The old Ansible/Puppet configuration VM had
occupied port 18080 and served a synthetic page, so it was halted before the
original `myscoutee-msc121` VM was started. No ZAP scan ran against that
synthetic page.

The original VM's recorded libvirt UUID and disks were retained. Its normal
`vm.py start` refused a Terraform plan that would replace cloud-init resources;
the existing domain was started directly, with no Terraform apply, rebuild,
image import, or Ansible qualification. Its Kubernetes API and frontend pod
became ready. `workloads.py frontend-up` refused the current image lock because
it lacks the newly listed `mongo-seed` artifact; no deployment change was made.
The existing frontend pod already had one desired and one ready replica, so
the owning `workloads.py forward` command exposed its existing NodePort at
`http://127.0.0.1:18080/`. The target `/entry` returned HTTP 200 with the
MyScoutee title and application root. The running frontend image was
`docker.io/library/myscoutee-service-frontend:1.5.0-060e5573bb06`, image ID
`sha256:060e5573bb06f6c6d90d086ffae5fd78c6ea47850287b1dc8be388ab92646ce7`.
The source checkout revision is not claimed as the running image revision.

With about 4 GiB host memory available and no other Docker container running,
`./lab.sh scan-web-passive` scanned the anonymous `/entry` target using ZAP
2.17.0. The baseline spider and passive scan completed with zero FAIL, ten WARN
groups, and 58 PASS rules. The JSON has 16 alert variants across those groups.
Private outputs are `.local/reports/20261028T011006Z-web-passive-213764/`
as `report.json` and browser-readable `report.html`, both mode 0600. The ZAP
container exited. The scan did not authenticate, submit forms, run active
attack rules, or verify backend authorization.

| Warning group | Evidence and interpretation | Owner / follow-up |
| --- | --- | --- |
| CSP (four alert variants) | The running image's shared header only defines `frame-ancestors`, `object-src`, and `base-uri`. ZAP reports missing `form-action` and broad script/style/resource behavior. The nginx source now adds `form-action 'self'`; broader source allowlists need the frontend's inline and external-resource requirements mapped first. | `myscoutee-nginx` with frontend; verify the form rule after deployment, then design the remaining policy against real flows. |
| Server version and page banner | The `Server` header and the nginx 404 page reveal `nginx/1.29.6`; the two warnings describe the same exposure. | Source fix: `server_tokens off` in backend and template gateway configs. Both existing-image gateway tests pass. Rebuild/deploy and rescan before claiming the running image is fixed. |
| Permissions Policy | Header absent on five observed responses. This is a defense-in-depth setting, with no demonstrated exploit in this scan. | `myscoutee-nginx`; select a policy based on used browser features before changing the header. |
| Cross-origin isolation headers | COEP, COOP, or CORP absent on seven observed responses. The application requirement and effect on OAuth/media flows were not established. | Frontend and nginx; review those flows before choosing a policy. |
| Dangerous JavaScript function | ZAP found `bypassSecurityTrustHtml(` in one built JavaScript bundle. A call site and untrusted input path were not established. | Frontend; map the built bundle to source before classifying it as a vulnerability. |
| Caching | Static assets were cacheable; entry pages carried `Cache-Control: no-cache`. No sensitive cached response was shown. | No change from this evidence. |
| Suspicious comment, timestamp, modern-app notice | The comment is the public GitHub Pages route note; the timestamp matches the scan-time response date; the modern-app notice is informational. | No change from this evidence. |

These observations are not a claim that the deployed application is vulnerable
to a particular exploit. Recheck any source-level change against its own built
image and the same anonymous routes.

The gateway test fixture was updated to mount its real route inventory,
response policy, and partition snapshot, so it can exercise the current
gateway configuration. The shared nginx source adds `form-action 'self'` after
a source search found no cross-origin HTML form action. A separate
`myscoutee-nginx:msc130-security-candidate` image was built from that source;
its local image ID is
`sha256:2726f834d2658fb008a639b757c806cf658ffddbc4bc20ef8979d118e937ae59`.
`tests/gateway-test.py` passed with this image against both backend and
template source trees. This is a local candidate, not a published image or a
change to the KVM deployment. A running-app ZAP rerun awaits deployment through
the owning workflow.

### Step 6: recovery scope decision

The earlier plan treated an isolated MongoDB/MinIO restore as an independent
security test. That was too broad for this assessment. A restore would test a
specific deployment's recovery procedure, not establish a missing MyScoutee
application feature. Depending on the installation, the owner may use a full
disk or VM backup instead of an application-level archive. The package/Compose
backup flow and the KVM's Mongo migration/reset backup serve different purposes;
neither should be assumed to be the other's recovery contract.

**Decision:** Skip a separate MSC-130 restore exercise. No recovery gap,
deployment owner, or acceptance question was identified that would make it
meaningful here. No backup was opened, no restore was run, and no claim is made
that any deployment's recovery is verified. Reopen only if a concrete recovery
requirement or defect is brought into scope; that test belongs with the owning
deployment procedure.

### Tasks 7-9: separate entry decisions

The former combined integration line was replaced by three independent tasks.
No tool was started and no integration was changed for these tasks.

**Task 7, second factor:** The standalone service does not create a MyScoutee
session. A product task must specify who needs an additional factor, when, and
how recovery and sessions work before backend integration can be assessed.

**Task 8, security events:** Step 4 found no specified operator-wide event or
alert question. CodeForge's Elastic data is synthetic or belongs to CodeForge;
it cannot stand in for an approved MyScoutee event feed.

**Task 9, web edge:** A later source review found existing nginx controls; see
the dated Step 9 result below. IDS, IPS, EDR, and other host/network
candidates stay in the coverage inventory until scoped.

### Step 9: existing web-edge protection review

Read-only review of `myscoutee-nginx` source at
`4f5b65bbbb5e4ded69771f41990346711930fc9b` and its existing native test
on 2026-10-28; no container, KVM scan, or new rule engine was started. The public
gateway includes a generated known-route map, a 30 requests/s per-IP limit
(burst 120), and a separate 2 requests/s limit on unknown routes (burst 10).
The native edge module counts unknown-route attempts and missing static assets
per client IP. At 100 attempts within a 600-second window it persists an
automatic ban; subsequent public requests receive 403. Operator IPv4/IPv6
blocks also return 403, with the operator message taking precedence. The
existing native test exercises threshold crossing, another IP remaining
available, internal monitoring staying available, ban persistence across
container replacement, and operator updates. These are source and test
observations, not a fresh live check of the running KVM.

This is meaningful WAF-like filtering for route probing and request floods.
The reviewed rules do not inspect request bodies for generic SQL injection or
XSS signatures. The ban is per observed client IP and each proxy instance has
its own state, so deployment topology and trusted client-IP handling matter.
No new ModSecurity/CRS or managed WAF is justified by the current ZAP header
warnings alone. Reuse the existing control; revisit a generic rule engine only
for a named threat it does not cover and representative legitimate traffic.
