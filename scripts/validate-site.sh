#!/usr/bin/env bash
# Focused static-site validation for EchoFlow Labs (no page logic duplication).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "OK: $*"; }

echo "=== EchoFlow Labs site validation ==="

# Required files
required=(
  index.html
  404.html
  CNAME
  robots.txt
  sitemap.xml
  assets/css/site.css
  support/english-lens/index.html
  privacy/english-lens/index.html
  .github/workflows/pages.yml
)
for f in "${required[@]}"; do
  [[ -f "$f" ]] || fail "missing required file: $f"
done
ok "required files present"

# CNAME / canonical domain
grep -qx 'www.eflabs.tech' CNAME || fail "CNAME must be www.eflabs.tech"
ok "CNAME"

# Forbidden localhost links in HTML
if grep -RIn --include='*.html' -E 'https?://(localhost|127\.0\.0\.1)' . 2>/dev/null; then
  fail "localhost URLs in HTML"
fi
ok "no localhost links"

# No remote scripts, fonts, or analytics CDNs in HTML/CSS (site files only)
site_globs=(--include='*.html' --include='*.css')
if grep -RIn "${site_globs[@]}" -E '<(script[^>]+src=|link[^>]+href=)[^>]*(googleapis|gstatic|googletagmanager|google-analytics|cloudflare|unpkg|jsdelivr)' \
  --exclude-dir=.validate-venv --exclude-dir=.git . 2>/dev/null; then
  fail "remote script/font/analytics dependency detected"
fi
if grep -RIn --include='*.html' -E '<script[^>]+src=' --exclude-dir=.validate-venv --exclude-dir=.git . 2>/dev/null; then
  fail "external script src found"
fi
ok "no production CDN scripts/fonts/analytics"

# Internal asset references (root-absolute paths)
html_files=(index.html 404.html support/english-lens/index.html privacy/english-lens/index.html)
for hf in "${html_files[@]}"; do
  while IFS= read -r ref; do
    path="${ref#/}"
    [[ -e "$path" ]] || fail "broken ref in $hf: $ref"
  done < <(grep -oE '(href|src)="/[^"#?]+' "$hf" | sed -E 's/^(href|src)="?//' | tr -d '"' | sort -u)
done
ok "internal href/src targets exist"

# Privacy page factual anchors (substring checks)
privacy="privacy/english-lens/index.html"
for phrase in Supabase Redis "seven days" "usage ledger" "sell your personal" harvey@eflabs.tech; do
  grep -q "$phrase" "$privacy" || fail "privacy page missing: $phrase"
done
ok "privacy factual anchors"

# Support page anchors
support="support/english-lens/index.html"
for phrase in "Learn with EchoFlow" Supabase "plain English" harvey@eflabs.tech; do
  grep -q "$phrase" "$support" || fail "support page missing: $phrase"
done
ok "support factual anchors"

# Sitemap URLs
for url in https://www.eflabs.tech/ https://www.eflabs.tech/support/english-lens/ https://www.eflabs.tech/privacy/english-lens/; do
  grep -q "$url" sitemap.xml || fail "sitemap missing $url"
done
ok "sitemap URLs"

css="assets/css/site.css"

# CSS brace balance (site stylesheets only; no external tools)
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY'
import re
import sys
from pathlib import Path

def check_css(path: Path) -> None:
    raw = path.read_text(encoding="utf-8")
    cleaned = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)
    depth = 0
    for ch in cleaned:
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth < 0:
                sys.exit(f"CSS brace imbalance in {path}: unexpected '}}'")
    if depth != 0:
        sys.exit(f"CSS brace imbalance in {path}: {depth} unclosed '{{'")

for css_path in Path("assets/css").glob("*.css"):
    check_css(css_path)
print("css brace balance ok")
PY
  ok "CSS brace balance"
fi

# Repository hygiene
[[ ! -d .impeccable ]] || fail ".impeccable/ must not be published (use .gitignore)"
grep -q 'echoflow-labs.github.io' README.md || fail "README must document DNS CNAME target echoflow-labs.github.io"
grep -q 'configure-pages' .github/workflows/pages.yml || fail "pages workflow must run actions/configure-pages"
grep -qE '"@type": "Offer"|PreOrder|priceCurrency' index.html && fail "index JSON-LD must not claim price/offer/availability"
grep -qi 'magic-link' support/english-lens/index.html && fail "support must not mention magic-link (password reset only)"
grep -qi 'App Store submission' index.html support/english-lens/index.html && fail "use approved status: App Store launch is in progress"
grep -qi 'Install or update English Lens' support/english-lens/index.html && fail "support must not instruct install before public availability"
grep -qi 'user-facing feature' privacy/english-lens/index.html && fail "privacy must state device facts categorically"
grep -qi 'designed not' privacy/english-lens/index.html && fail "privacy must not hedge with designed not"
grep -qi 'children under 13' privacy/english-lens/index.html && fail "unsupported children policy statement"
grep -qi 'app row' support/english-lens/index.html index.html && fail "Learn with EchoFlow is in actions list, not app row"
grep -q 'App Store launch is in progress' index.html || fail "index must use approved launch status wording"
grep -q 'validate-site.sh' .github/workflows/pages.yml || fail "Pages workflow must run scripts/validate-site.sh"
grep -q -- '--link:' "$css" || fail "site.css must define semantic --link token"
grep -q 'anchor-scroll-margin' "$css" || fail "site.css must define scroll-margin anchor tokens"
grep -q 'loading="lazy"' index.html || fail "below-fold screenshots should lazy-load"
if grep -RIn --include='*.html' -i 'property="og:description"[^>]*share extension' . 2>/dev/null; then
  fail 'og:description must not say "share extension" (use Action extension)'
fi
ok "repository hygiene and copy accuracy"

# Mobile header layout contract (CSS structure, not pixel fixtures)
grep -q 'max-width: 700px' "$css" || fail "missing <=700px header breakpoint in site.css"
grep -q 'grid-template-columns' "$css" || fail "missing mobile nav grid in site.css"
grep -q 'brand__name' "$css" || fail "missing single-line brand helper in site.css"
if grep -E '\.nav[^{]*\{[^}]*nowrap' "$css" 2>/dev/null; then
  fail ".nav must not use flex-wrap: nowrap (mobile links must wrap/grid)"
fi
if grep -E '\.nav a[^{]*\{[^}]*display:\s*none' "$css" 2>/dev/null; then
  fail "nav links must not be display:none in CSS"
fi
for anchor in '#products' '#english-lens' '#listening' '#principles' '#contact'; do
  grep -q "href=\"$anchor\"" index.html || fail "index nav missing $anchor"
done
ok "mobile nav structural contract"

# HTML well-formed (lightweight)
if command -v xmllint >/dev/null 2>&1; then
  for xf in sitemap.xml; do
    xmllint --noout "$xf" || fail "xml parse: $xf"
  done
fi
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY'
from html.parser import HTMLParser
from pathlib import Path

class Check(HTMLParser):
    def __init__(self):
        super().__init__()
        self.stack = []
    def handle_starttag(self, tag, attrs):
        if tag not in ("meta", "link", "img", "br", "hr", "input", "source", "area", "col", "embed", "param", "track", "wbr"):
            self.stack.append(tag)
    def handle_endtag(self, tag):
        if tag in ("meta", "link", "img", "br", "hr", "input", "source", "area", "col", "embed", "param", "track", "wbr"):
            return
        if not self.stack:
            raise SystemExit(f"unexpected closing {tag}")
        if self.stack[-1] != tag:
            raise SystemExit(f"mismatched close {tag}, expected {self.stack[-1]}")
        self.stack.pop()
    def close(self):
        super().close()
        if self.stack:
            raise SystemExit(f"unclosed tags: {self.stack}")

for path in Path(".").rglob("*.html"):
    if ".git" in path.parts or ".validate-venv" in path.parts:
        continue
    p = Check()
    p.feed(path.read_text(encoding="utf-8"))
    p.close()
print("html parse ok")
PY
fi

# HTTP smoke (local server; trap guarantees cleanup)
if command -v python3 >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
  port=8765
  srv=""
  smoke_cleanup() {
    if [[ -n "$srv" ]] && kill -0 "$srv" 2>/dev/null; then
      kill "$srv" 2>/dev/null || true
      wait "$srv" 2>/dev/null || true
    fi
  }
  trap smoke_cleanup EXIT INT TERM

  if command -v lsof >/dev/null 2>&1 && lsof -iTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
    fail "HTTP smoke port $port is already in use"
  fi

  python3 -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1 &
  srv=$!
  if ! kill -0 "$srv" 2>/dev/null; then
    fail "failed to start HTTP smoke server on 127.0.0.1:$port"
  fi

  ready=0
  for _ in $(seq 1 30); do
    if curl -sf --max-time 2 "http://127.0.0.1:${port}/" -o /dev/null; then
      ready=1
      break
    fi
    sleep 0.2
  done
  [[ "$ready" == "1" ]] || fail "HTTP smoke server not ready on 127.0.0.1:$port"

  for path in / /support/english-lens/ /privacy/english-lens/ /assets/css/site.css; do
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://127.0.0.1:${port}${path}") || fail "HTTP smoke curl transport error for $path"
    [[ "$code" == "200" ]] || fail "HTTP $code for $path"
  done
  trap - EXIT INT TERM
  smoke_cleanup
  srv=""
  ok "local HTTP smoke"
fi

echo "=== All checks passed ==="
