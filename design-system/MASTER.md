# EchoFlow Labs — Design System (MASTER)

Canonical visual and content rules for the static site at `https://www.eflabs.tech/`.

## Brand direction

- Mature, premium, human-centered language learning—not playful or childlike.
- Hero line: **English, in your flow.**
- Supporting idea: understand what you read and hear without breaking rhythm.
- Honest product status only; no fake metrics, ratings, testimonials, or App Store links until real.
- Approved English Lens status copy: **App Store launch is in progress** (not “submission”, not implying public download today).

## Color tokens

### Decorative (buttons, fills, illustrations)

| Token | Hex | Role |
|-------|-----|------|
| Indigo 600 `#4f46e5` | Primary button fill | CTAs |
| Indigo 700 `#4338ca` | Button hover | — |
| Mint 400 `#5eead4` | Launch badge fill, listening visual | Progress |
| Warm 400 `#f59e0b` | In-development badge fill | Accent wash |
| Navy 950 `#0b1220` | Dark surfaces | Depth |

### Semantic contrast (body text, UI chrome)

Use these for links, eyebrows, icons, focus, and status **text**—not raw sky/indigo/warm decorative hues.

| Token | Light | Dark | Requirement |
|-------|-------|------|-------------|
| `--link` | `#3730a3` | `#a5b4fc` | ≥4.5:1 on surface |
| `--link-hover` | `#1e3a8a` | `#c7d2fe` | ≥4.5:1 on surface |
| `--text-accent` | `#0369a1` | `#7dd3fc` | ≥4.5:1 on surface (eyebrows) |
| `--icon-accent` | `#0369a1` | `#7dd3fc` | ≥4.5:1 on surface (list icons) |
| `--focus-ring` | `#1d4ed8` | `#60a5fa` | ≥3:1 against surface |
| `--status-warm-text` | `#92400e` | `#fcd34d` | ≥4.5:1 on badge/surface |

Surfaces: `--color-surface` `#f8fafc` / `#0b1220` (dark); text `--color-text` / `--color-text-muted`.

## Typography

- **Stack:** system UI only. No remote fonts.
- **Body:** 17px (`1.0625rem`), line-height 1.65.
- **Scale:** h1 hero up to 3.25rem; section h2 up to 2.125rem; card h3 1.375rem; prose h2 1.625rem; prose h3 1.25rem.

## Layout

- Max content width: 72rem; horizontal padding 1rem.
- **In-page anchors:** `section[id]` use `scroll-margin-top: var(--anchor-scroll-margin)` — `5.5rem` desktop, `10.5rem` at ≤700px (two-row sticky header).
- Bento product grid: 2 columns from 768px.

## Components

- **Sticky header:** min-height 4rem; at ≤700px stacks brand + 3-column nav grid (all links visible), 44px targets.
- **Buttons:** primary (indigo fill), secondary (bordered). Min 44×44px.
- **Badges:** mint = launch in progress; warm = in development (text via `--status-warm-text`).
- **Phone frames:** real screenshots below fold use `loading="lazy"` and `decoding="async"`.

## Motion

- Micro transitions 180ms; wave animation on Listening concept only.
- `prefers-reduced-motion: reduce` disables animation and smooth scroll.

## Accessibility

- Skip link to `#main`.
- Visible `:focus-visible` rings using `--focus-ring`.
- Semantic landmarks; meaningful `alt` on screenshots.
- No horizontal overflow on body.

## Content rules

- **English Lens:** iOS 26; **Learn with EchoFlow** is an **Action extension** in the share sheet **actions** list (enable via **Edit Actions**). Only when a **host app exports selected plain text**—not every app with a share sheet.
- Paste/type in the main app when installed; do not imply reading unshared app content or first-level text-menu injection.
- **EchoFlow Listening:** in development; concept art only.
- **Privacy (device):** state categorically—no local prompt/result history; source text not in ordinary logs/analytics/crash metadata.
- **Contact:** `harvey@eflabs.tech`.

## Assets

- App icon and screenshots under `assets/images/` (PNG + WebP).
- Favicon: `favicon-32.png`; `apple-touch-icon.png`.
