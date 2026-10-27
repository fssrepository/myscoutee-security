# MSC-130 laboratory verification - 2026-10-27

This record describes the first runnable security sandbox. Scanner outputs are
private under `.local/reports/` and are deliberately not committed. Counts are
raw tool observations, not confirmed product vulnerabilities.

## Inputs and checks

| Check | Exact input | Result |
| --- | --- | --- |
| Shell and environment | `bash -n lab.sh`; `./lab.sh check` | Passed; Docker daemon available. |
| Source scan | Backend `config/packaging` at `62d7f776551253301eb39188dc5db419a6ff0df8` | Trivy 0.76.1 completed. No result entries in this narrow scope. |
| Source scan | Frontend submodule at `9f21466c3359de6add31de92cc3f06f965cc291e` | Trivy 0.76.1 completed; one npm result entry, zero reported issues under default production-dependency selection. Generated folders were skipped. |
| Historical image scan | Image ID `sha256:7f3dcb88d11918786d7df6a3c9f64847e3f611becf470cff668ed30d99f469ad`, then locally tagged `myscoutee-nginx:1.5.1-prod` | Trivy 0.76.1 completed. Raw report: 196 package alerts (47 HIGH, 81 MEDIUM, 64 LOW, 4 UNKNOWN); no secret/configuration alerts. This tag does not identify a current image or planned release. No triage or deployed-image claim. |
| Web passive scan | Running sibling CodeForge at `http://127.0.0.1:8088/` | ZAP 2.17.0 completed; zero FAIL, seven WARN, 61 PASS. This validates the lab command, not MyScoutee application security. |
| PDF | English 0.1.1 guide | Eight A4 pages generated and visually inspected after rendering. Includes a practitioner workflow and image-alert triage example. |

The historical image scan's raw alerts do not assess the published 1.5.0
release image. Findings from a scan of that exact release digest need review
against package versions, available fixes, and runtime exposure.
The ZAP baseline must be repeated on a designated MyScoutee test deployment
before any main-application web finding is reported. Source scans skip generated
directories; this is why the image scan is a separate route.

## Scanner provenance and private outputs

- Trivy image: `aquasec/trivy:0.76.1`; pulled digest
  `sha256:790fd66d1697395d8693d1acaa1ea702406a20f109b6fc7bac8db623eca6c06c`.
- ZAP image: `ghcr.io/zaproxy/zaproxy:2.17.0`; pulled digest
  `sha256:030d3df57735dacbb83464854758e674dd9ad01d79d12a129a8e58b1fd384238`.
- Reports and cache live only in gitignored `.local/`; report directories use
  mode 0700 and successful scan output files use mode 0600. The image archive
  was removed after the successful image scan.

No backend or template application files were changed by this laboratory task.
