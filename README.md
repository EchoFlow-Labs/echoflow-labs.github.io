# EchoFlow Labs — Public Site

Production static landing site for [EchoFlow Labs](https://www.eflabs.tech/). Hosted on **GitHub Pages** from this repository root. **CSS** is built with Tailwind v4 + [shadcn/ui](https://ui.shadcn.com/) theme tokens (`components.json`, `src/styles/globals.css`); HTML stays static (no client JS).

## Local development

```bash
cd /path/to/echoflow-labs.github.io
npm ci && npm run build   # writes assets/css/site.css
python3 -m http.server 8080
# Open http://127.0.0.1:8080/
```

Run validation:

```bash
chmod +x scripts/validate-site.sh
./scripts/validate-site.sh
```

## Architecture and content boundaries

| Path | Purpose |
|------|---------|
| `index.html` | Home: hero, products, English Lens, Listening (in dev), principles, contact |
| `support/english-lens/` | User support for English Lens |
| `privacy/english-lens/` | Product privacy disclosures |
| `assets/css/site.css` | Shared styles (tokens, components, a11y) |
| `assets/images/` | App icon, screenshots (PNG + WebP) |
| `404.html` | GitHub Pages friendly not-found page |
| `CNAME` | Custom domain for Pages |
| `robots.txt`, `sitemap.xml` | SEO |
| `design-system/MASTER.md` | Design system source of truth |
| `DESIGN.md` | Brand direction (getdesign / Voltagent-inspired) |
| `components.json` | shadcn/ui project config |
| `src/styles/` | CSS source (build → `assets/css/site.css`) |

No client-side JavaScript on the marketing site, no CMS, no backend calls, no analytics.

## DNS and GitHub Pages settings

Intended production setup:

1. **GitHub repository** → Settings → Pages → Source: **GitHub Actions** (workflow `.github/workflows/pages.yml`).
2. **Custom domain:** `www.eflabs.tech` (stored in `CNAME`).
3. **DNS (example):**
   - `www` → CNAME → **`echoflow-labs.github.io`** (GitHub Pages hostname for this repository).
   - Apex `eflabs.tech` → configure separately (registrar redirect to `https://www.eflabs.tech/`, or GitHub Pages apex `A`/`AAAA` records when you enable apex hosting). Apex records are not stored in this repo.
4. Enforce **HTTPS** in Pages settings once DNS validates.

Canonical URLs in HTML use `https://www.eflabs.tech/`.

## Deployment and rollback

- **Deploy:** push to `main`; the Pages workflow uploads the repo root as the artifact and deploys.
- **Rollback:** revert the offending commit on `main` and push, or re-run the workflow from a previous commit via GitHub UI.
- **Preview:** use local `python3 -m http.server` or a fork/branch Pages environment if enabled.

## Supply chain

GitHub Actions use official `actions/checkout@v4`, `actions/configure-pages@v5`, `actions/upload-pages-artifact@v3`, and `actions/deploy-pages@v4` **version tags** rather than commit SHAs. Pin to full SHAs after verifying on GitHub if your security policy requires it.

## Contact

harvey@eflabs.tech
