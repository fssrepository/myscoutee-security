# MyScoutee Security Assessment

Security checks and evidence for the actual MyScoutee product. This repository
holds scanner entry points, the ordered assessment, and decisions about existing
controls or candidate integrations.

**Status: active assessment.** Three Docker-based checks are available. This
repository does not modify the MyScoutee application or install a SIEM.
Scanner results require human review.

## Quick start

Docker is required. Scanner containers are short-lived and do not start an
application server. Source directories are mounted read-only. Reports and the
scanner cache stay in the Git-ignored `.local/` directory.

```sh
./lab.sh check
./lab.sh scan-source ../myscoutee-backend/config/packaging
./lab.sh scan-image <local-myscoutee-image:tag>
./lab.sh scan-web-passive
```

The image scan accepts an existing local image. The web target and its expected
MyScoutee page markers are committed in [config/web-baseline.json](config/web-baseline.json).
The command verifies that page before starting a time-limited, passive ZAP
baseline. Start the target application separately; an unrelated service on the
same port fails the identity check. No active-scan or external-web-target command
is provided.

Each run writes to a separate `.local/reports/<id>/` directory. Trivy source
and image scans produce `trivy.json` and a browser-readable `trivy.html` using
Trivy's own HTML template. Open the HTML file locally in a browser. Reports
may contain secret matches, so they must not be published automatically.
The image scan reads a temporary tar archive; the scanner receives no Docker
socket. Source scans skip `.git`, `node_modules`, `build`, `dist`, `coverage`,
`.angular`, `.agent`, and `.local` at any depth. Scan a built image separately
to inspect its contents.

## Guides

- [Ordered security assessment plan](guides/development/security/test-plan.md)
- [Assessment results and progress](guides/development/security/assessment-results.md)
- [MyScoutee Security Assessment guide (English PDF)](guides/publication/manuals/MyScoutee_Security_Assessment_Guide_EN.pdf)
- [Guide source and regeneration](guides/publication/manuals/README.md)
- [Integration points and assessment plan](guides/development/security/README.md)
- [Tool and method coverage matrix](guides/development/security/coverage-matrix.md)
- [Historical tool verification](guides/development/security/verification.md)

The publication-ready PDF and its editable generator live under
`guides/publication/manuals/`. Internal decisions and evidence live under
`guides/development/security/`, following the sibling repositories' guide
convention.

## Ownership boundary

Authentication, authorization, payments, and business decisions belong to the
MyScoutee application. This assessment can inspect and reuse evidence from
`myscoutee-2fa`, `myscoutee-elastic`, `myscoutee-sonarqube`, and `myscoutee-ci`
without copying their implementations. A scanner finding is not a confirmed
vulnerability, and a clean report is not a security certification.
