#!/usr/bin/env bash
set -euo pipefail
umask 077

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE="$ROOT/.local"
TRIVY_IMAGE="aquasec/trivy:0.76.1"
ZAP_IMAGE="ghcr.io/zaproxy/zaproxy:2.17.0"
IMAGE_INPUT_DIR=""

usage() {
  cat <<'EOF'
MyScoutee Security Assessment
  ./lab.sh check
  ./lab.sh scan-source <source-directory>
  ./lab.sh scan-image <local-image:tag>
  ./lab.sh scan-web-passive

Reports and scanner cache stay in .local/ (private, ignored by Git).
EOF
}

new_report_dir() {
  mkdir -p -m 700 "$STATE/reports" "$STATE/cache/trivy"
  local dirname
  dirname="$(date -u +%Y%m%dT%H%M%SZ)-$1-$$"
  REPORT="$STATE/reports/$dirname"
  mkdir -m 700 "$REPORT"
}

check_docker() {
  command -v docker >/dev/null || { echo 'Docker CLI is missing' >&2; exit 1; }
  docker info --format 'Docker server: {{.ServerVersion}}' >/dev/null || {
    echo 'Docker daemon is unavailable' >&2; exit 1;
  }
}

lock_trivy_cache() {
  command -v flock >/dev/null || { echo 'flock is required' >&2; exit 1; }
  exec 9>"$STATE/trivy.lock"
  flock -n 9 || { echo 'Another Trivy scan owns the local cache' >&2; exit 1; }
}

render_trivy_html() {
  docker run --rm --network none --user "$(id -u):$(id -g)" \
    --mount "type=bind,src=$REPORT,dst=/report" \
    "$TRIVY_IMAGE" convert --format template --template '@contrib/html.tpl' \
      --output /report/trivy.html /report/trivy.json
  chmod 600 "$REPORT/trivy.html"
}

scan_source() {
  [[ $# -eq 1 && -d "$1" ]] || { usage >&2; exit 2; }
  local source
  source="$(realpath -- "$1")"
  check_docker
  new_report_dir source
  lock_trivy_cache
  docker run --rm --user "$(id -u):$(id -g)" \
    --mount "type=bind,src=$source,dst=/source,readonly" \
    --mount "type=bind,src=$REPORT,dst=/report" \
    --mount "type=bind,src=$STATE/cache/trivy,dst=/cache" \
    "$TRIVY_IMAGE" fs --scanners vuln,misconfig,secret \
      --skip-dirs '**/.git' --skip-dirs '**/node_modules' \
      --skip-dirs '**/build' --skip-dirs '**/dist' \
      --skip-dirs '**/coverage' --skip-dirs '**/.angular' \
      --skip-dirs '**/.agent' --skip-dirs '**/.local' \
      --cache-dir /cache --format json --output /report/trivy.json /source
  chmod 600 "$REPORT/trivy.json"
  render_trivy_html
  printf 'Reports: %s/trivy.json and %s/trivy.html\n' "$REPORT" "$REPORT"
}

scan_image() {
  [[ $# -eq 1 && -n "$1" ]] || { usage >&2; exit 2; }
  local image="$1"
  check_docker
  docker image inspect "$image" >/dev/null || { echo 'Local image not found' >&2; exit 2; }
  new_report_dir image
  lock_trivy_cache
  IMAGE_INPUT_DIR="$(mktemp -d "$STATE/image-input.XXXXXXXX")"
  trap '[[ ! -e "$IMAGE_INPUT_DIR/image.tar" ]] || unlink -- "$IMAGE_INPUT_DIR/image.tar"; rmdir -- "$IMAGE_INPUT_DIR"' EXIT
  docker image save -o "$IMAGE_INPUT_DIR/image.tar" "$image"
  docker run --rm --user "$(id -u):$(id -g)" \
    --mount "type=bind,src=$IMAGE_INPUT_DIR,dst=/source,readonly" \
    --mount "type=bind,src=$REPORT,dst=/report" \
    --mount "type=bind,src=$STATE/cache/trivy,dst=/cache" \
    "$TRIVY_IMAGE" image --input /source/image.tar \
      --scanners vuln,misconfig,secret --cache-dir /cache \
      --format json --output /report/trivy.json
  chmod 600 "$REPORT/trivy.json"
  render_trivy_html
  printf 'Reports: %s/trivy.json and %s/trivy.html\n' "$REPORT" "$REPORT"
}

scan_web_passive() {
  [[ $# -eq 0 ]] || { usage >&2; exit 2; }
  local target
  target="$(python3 - "$ROOT/config/web-baseline.json" <<'PY'
import json
import sys
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, build_opener

config = json.load(open(sys.argv[1], encoding='utf-8'))
if config.get('schemaVersion') != 1:
    sys.exit('Unsupported web baseline configuration version')
target = config.get('targetUrl', '')
url = urlsplit(target)
if (url.scheme not in ('http', 'https') or url.hostname not in ('localhost', '127.0.0.1')
        or not url.port or url.username or url.password or url.query or url.fragment):
    sys.exit('Web baseline target must be an explicit loopback URL with a port and no credentials or query')
markers = config.get('expectedHtmlMarkers')
if not isinstance(markers, list) or not markers or not all(isinstance(item, str) and item for item in markers):
    sys.exit('Web baseline requires nonempty HTML identity markers')

class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, message, headers, newurl):
        return None

try:
    with build_opener(NoRedirect).open(target, timeout=5) as response:
        if response.status != 200 or 'text/html' not in response.headers.get('Content-Type', ''):
            sys.exit('Web baseline target is not a MyScoutee HTML page')
        body = response.read(1024 * 1024 + 1)
        if len(body) > 1024 * 1024 or not all(marker.encode() in body for marker in markers):
            sys.exit('Web baseline target identity does not match MyScoutee')
except OSError as error:
    sys.exit('Web baseline target unavailable or redirected: ' + str(error))
print(target)
PY
  )"
  check_docker
  new_report_dir web-passive
  docker run --rm --network host \
    --mount "type=bind,src=$REPORT,dst=/zap/wrk" \
    "$ZAP_IMAGE" zap-baseline.py -t "$target" -m 1 -T 5 -I \
      -J report.json -r report.html
  chmod 600 "$REPORT"/*
  printf 'Reports: %s/report.json and %s/report.html\n' "$REPORT" "$REPORT"
}

command="${1:-help}"
if [[ $# -gt 0 ]]; then shift; fi
case "$command" in
  help|-h|--help) usage ;;
  check) [[ $# -eq 0 ]] || { usage >&2; exit 2; }; check_docker; echo 'Docker available; no scanner was started' ;;
  scan-source) scan_source "$@" ;;
  scan-image) scan_image "$@" ;;
  scan-web-passive) scan_web_passive "$@" ;;
  *) usage >&2; exit 2 ;;
esac
