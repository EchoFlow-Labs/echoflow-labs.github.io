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
  terms/english-lens/index.html
  assets/images/english-lens-oauth-logo-120.png
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
html_files=(index.html 404.html support/english-lens/index.html privacy/english-lens/index.html terms/english-lens/index.html)
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

# Modern auth and account deletion (semantic, not exact copy fixtures)
privacy="privacy/english-lens/index.html"
support="support/english-lens/index.html"
grep -qi 'October 23, 2026' "$privacy" || fail "privacy last-updated should reflect 2026-10-23"
grep -qi 'email-based authentication' "$privacy" && fail "privacy must not describe Supabase auth as email-only"
grep -qi 'email-based sign-in' "$support" && fail "support must not describe sign-in as email-only"
grep -qi 'registered email' "$privacy" && grep -qi 'verify requests using reasonable means' "$privacy" && fail "privacy must not require email-only deletion verification"
for bad in 'email/password' 'email and password' 'password reset' 'forgot your password' 'in-app password'; do
  if grep -qi "$bad" "$privacy" "$support"; then
    fail "current-app copy must not promote email/password auth ($bad)"
  fi
done
grep -qi 'If it is missing, update the app' "$support" && fail "support must not claim sign-in buttons disappear when disabled"
grep -qi 'provider has been enabled for your build' "$support" && fail "support must not imply sign-in buttons are hidden until enabled"
if grep -qi 'may appear when enabled' "$support" "$privacy"; then
  fail "sign-in methods are always shown; do not say they appear only when enabled"
fi
for topic in Google Apple passkey Keychain Settings; do
  grep -qi "$topic" "$privacy" || fail "privacy missing auth/deletion topic: $topic"
done
for rollout in 'configuration is completed' 'enabling providers' 'setup finishes' 'provider configuration' 'configuration progresses' 'not ready yet' 'every environment yet'; do
  if grep -qi "$rollout" "$privacy" "$support"; then
    fail "public copy must not describe internal provider rollout ($rollout)"
  fi
done
grep -qi 'delete' "$privacy" || fail "privacy must describe account deletion"
grep -qi 'deletion-safety' "$privacy" || fail "privacy must disclose minimal deletion-safety record retention"
grep -qi 'reattach' "$privacy" && fail "privacy must not overclaim deletion-safety blocks reattachment to new accounts"
grep -qi 'Apple credential registration' "$privacy" || fail "privacy must scope deletion-safety to Apple credential registration"
grep -qi 'indefinitely' "$privacy" || fail "privacy must state deletion-safety record retention period"
grep -qi 'Settings' "$support" || fail "support must document Settings account deletion"
grep -qi 'delete' "$support" || fail "support must describe account deletion"
grep -qi 'Google' "$support" && grep -qi 'Apple' "$support" && grep -qi 'passkey' "$support" || fail "support must mention Google, Apple, and passkey sign-in"
grep -qi 'Keychain' "$support" || fail "support must mention Keychain session bridge"
ok "modern auth and deletion semantics"

terms="terms/english-lens/index.html"
grep -qi 'October 23, 2026' "$terms" || fail "terms last-updated should reflect 2026-10-23"
grep -qi 'prompt injection' "$terms" || fail "terms must cover abuse/prompt attacks"
grep -qi 'privacy/english-lens/' "$terms" || fail "terms must link to privacy policy"
grep -qi 'harvey@eflabs.tech' "$terms" || fail "terms must list contact email"
grep -qi 'does not currently offer' "$terms" || fail "terms must state no current paid subscription or IAP"
grep -qi 'not legal advice' "$terms" && fail "terms header must not include legal-advice disclaimer"
grep -Eqi '\$50|fifty U\.S\. dollars' "$terms" && fail "terms must not invent a specific liability cap"
grep -q '/terms/english-lens/' "$privacy" || fail "privacy must link to terms"
grep -q '/terms/english-lens/' "$support" || fail "support must link to terms"
grep -q '/terms/english-lens/' index.html || fail "home footer must link to terms"
ok "terms page semantics"

oauth_logo="assets/images/english-lens-oauth-logo-120.png"
if command -v python3 >/dev/null 2>&1; then
  python3 - <<PY
import struct
import sys
from pathlib import Path
p = Path("$oauth_logo")
data = p.read_bytes()
if len(data) >= 1_000_000:
    sys.exit(f"OAuth logo exceeds 1MB: {len(data)} bytes")
if data[:8] != b"\\x89PNG\\r\\n\\x1a\\n":
    sys.exit("OAuth logo is not a PNG")
# IHDR width/height at byte 16-24
if len(data) < 24:
    sys.exit("OAuth logo PNG too small")
w, h = struct.unpack(">II", data[16:24])
if w != h or w != 120:
    sys.exit(f"OAuth logo must be 120x120 square, got {w}x{h}")
print("oauth logo ok")
PY
  ok "OAuth logo asset"
fi

# Sitemap URLs
for url in https://www.eflabs.tech/ https://www.eflabs.tech/support/english-lens/ https://www.eflabs.tech/privacy/english-lens/ https://www.eflabs.tech/terms/english-lens/; do
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
grep -qE 'max-width:\s*700px' "$css" || fail "missing <=700px header breakpoint in site.css"
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

  for path in / /support/english-lens/ /privacy/english-lens/ /terms/english-lens/ /assets/css/site.css; do
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://127.0.0.1:${port}${path}") || fail "HTTP smoke curl transport error for $path"
    [[ "$code" == "200" ]] || fail "HTTP $code for $path"
  done
  trap - EXIT INT TERM
  smoke_cleanup
  srv=""
  ok "local HTTP smoke"
fi

echo "=== All checks passed ==="
