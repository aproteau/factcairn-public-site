# Factcairn — website handoff

Concept marketing sites for **Factcairn**, an evidence platform with three products:
**factcairnDeal** (M&A readiness + sell-side process), **factcairnComply** (continuous compliance) and
**factcairnRespond** (RFPs and security questionnaires).

Status: concept mockups, November 2026. Static HTML, no build step, no JavaScript framework.

---

## 1. What's in this package

```
factcairn-handoff/
├── HANDOFF.md                  ← this file
├── site/                       ← deploy this folder as-is
│   ├── index.html              ← platform site   (factcairn)
│   ├── deal/index.html         ← factcairnDeal
│   ├── comply/index.html       ← factcairnComply
│   ├── respond/index.html      ← factcairnRespond
│   ├── assets/
│   │   ├── icons/              ← favicons: SVG + PNG 32 / 180 (Apple) / 512 (social, PWA)
│   │   └── logos/              ← marks and wordmarks (SVG)
│   ├── staticwebapp.config.json← Azure Static Web Apps settings (headers, 404)
│   └── robots.txt              ← blocks indexing for now (see §6)
└── source/                     ← original design-canvas files (.dc.html + canvas.json)
```

Each page is one self-contained HTML file: inline styles, inline SVG logos, fonts from Google Fonts.
Pages link to each other with relative paths, so the site also works opened straight from disk.

---

## 2. Brand

### Name and wordmarks
| Use | Written as | Style |
|---|---|---|
| Platform / company | **factcairn** (lowercase in the logo, "Factcairn" in sentences) | Space Grotesk 700, ink `#0E1B2C` |
| Products | **factcairnDeal**, **factcairnComply**, **factcairnRespond** — one word, no space | "factcairn" Space Grotesk 400 in grey `#5B6676`; product name Space Grotesk 700 in the product color |

Letter-spacing on wordmarks: −0.03em. On dark backgrounds, "factcairn" turns into a lighter tint (e.g. `#9FC3BD` on the Comply dark header).

### Logo mark — the cairn
A rounded square (32×32, radius 8) with three stacked stones; the top stone carries the accent tint.
The same mark is used for every product; only the colors change.

```svg
<rect width="32" height="32" rx="8" fill="BG"/>
<ellipse cx="16"   cy="23.2" rx="8.6" ry="3.2" fill="STONE"/>
<ellipse cx="15.2" cy="17"   rx="6"   ry="2.7" fill="STONE"/>
<ellipse cx="16.4" cy="11.4" rx="3.8" ry="2.4" fill="TOP"/>
```

| Mark | BG | Stone | Top stone | File |
|---|---|---|---|---|
| factcairn | `#0E1B2C` | `#F7F6F2` | `#E8B04B` | `logos/factcairn-mark.svg` |
| factcairn on dark | `#F7F6F2` | `#0E1B2C` | `#D9982B` | `logos/factcairn-mark-on-dark.svg` |
| Deal | `#1D4ED8` | `#FFFFFF` | `#BFD3FB` | `logos/factcairn-deal-mark.svg` |
| Comply | `#0F766E` | `#FFFFFF` | `#99F6E4` | `logos/factcairn-comply-mark.svg` |
| Respond | `#C2410C` | `#FFFFFF` | `#FED7AA` | `logos/factcairn-respond-mark.svg` |

The wordmark SVGs use live text in Space Grotesk. Before print or use in design tools, convert the text to
outlines (Figma, Illustrator or Inkscape: "Object to path").

### Colors
| Site | Accent | Dark | Page background | Muted text | Notes |
|---|---|---|---|---|---|
| Platform | `#D9982B` / `#E8B04B` (gold) | `#0E1B2C` (ink navy) | `#F7F6F2` | `#4A5565` | Gold is used only on dark navy or as a large surface |
| Deal | `#1D4ED8` | `#0B1F4D` | `#F5F7FB` | `#4A5565` | |
| Comply | `#0F766E` / `#5EEAD4` on dark | `#0B2E2B` | `#F3F7F6` | `#3F5C58` | |
| Respond | `#C2410C` | `#2A1810` | `#FBF7F3` | `#5C4A40` | |

Shared status colors: high/failing `#B4380A`, attention `#8A5A0B` on `#FFF7E6`, passing `#0F766E` on `#ECF8F5`.
All text colors were chosen to meet WCAG AA contrast (4.5:1) on their backgrounds.

### Typography
- Headings and wordmarks: **Space Grotesk** 500 / 600 / 700, letter-spacing −0.02em
- Body and UI: **Inter** 400 / 500 / 600
- Data, codes, fact samples: **JetBrains Mono** 400 / 500
- Scale used: H1 60–64px · H2 38–42px · H3 18–24px · body 15–19px · labels 12–13px uppercase with 0.12em tracking

### Shapes and layout
- Max content width 1200px, side padding 32px, section padding 72–96px vertical
- Radius: buttons 10px, cards 16–20px, CTA banners 24px, chips 999px
- Buttons: 15px/600 text, padding 15×22px; primary = solid accent, secondary = 1px outline
- Layout is flex-wrap throughout, so every section stacks naturally on phones (no media queries needed)

---

## 3. Site map and content

All copy is final concept copy, written into the HTML. Section order per page:

**Platform** (`/`) — dark hero "Answer once. Prove once. Reuse everywhere." with a sources → fact graph → products diagram ·
the problem · the seven building blocks (sources & policies, facts with provenance, frameworks & requests, mapping & gaps,
continuous checks, cited responses, secure workspaces) · three product cards · "one verified fact, three requests" example ·
trust by design · developer/connector section with a C# connector sample · design-partner CTA · footer.

**factcairnDeal** (`/deal/`) — hero "Be deal-ready before there's a deal." with a readiness-score and fix-list mock ·
six-stage lifecycle (hygiene → handoff) · "found early, fixed cheap" cards · buyer DRL mock + features · advisor
multi-mandate workspace · pricing (Readiness / Deal activation / Advisor firm) · CTA.

**factcairnComply** (`/comply/`) — dark hero "Compliance that stays proven." with a live SOC 2 controls mock · framework chips
(SOC 2, ISO 27001, Québec Law 25, PIPEDA, HIPAA) · Connect / Monitor / Prove · features · trust center mock ·
pricing (Essentials / Growth / Platform bundle) · CTA.

**factcairnRespond** (`/respond/`) — hero "Answer every RFP from what's actually true." with a cited answer and a blocked
outdated claim · source-rules table (authoritative / reference / internal / restricted) · 5-step workflow ·
features · pricing (Team / Business / Platform bundle) · CTA.

### Placeholders and things that are not real
- Every price reads **[PRICE]**.
- Northwind Freight, Projects Falcon / Orca / Lark, Bellwood Tech and the Regional Transit Authority RFP are **fictional sample data** shown inside UI mockups.
- There are **no testimonials or customer logos** on purpose; the CTA is a "design partner program".
- Sign in, Privacy and Security footer links point to `#`.
- The email forms are **not wired** (buttons are `type="button"`). See §6.

---

## 4. Run it locally

Simplest: double-click `site/index.html`.

With a local web server (needs Node.js), in PowerShell:
```powershell
cd factcairn-handoff\site
npx serve .
# then open http://localhost:3000
```

---

## 5. Deploy

### Option A — Azure Static Web Apps (recommended; Free tier is enough)

**One-time setup with Azure CLI (PowerShell):**
```powershell
az login
az group create --name rg-factcairn --location canadacentral
az staticwebapp create --name factcairn-web --resource-group rg-factcairn --location eastus2 --sku Free
# Static Web Apps has a limited region list; static content is served globally anyway.

$token = az staticwebapp secrets list --name factcairn-web --query "properties.apiKey" -o tsv
```

**Deploy (and redeploy after every change):**
```powershell
npm install -g @azure/static-web-apps-cli
cd factcairn-handoff
swa deploy .\site --env production --deployment-token $token
```

**Alternative — GitHub:** push the `site` folder to a repo, then in the Azure Portal create the Static Web App
from that repo with *App location* = `site`, *Api location* = empty, *Output location* = empty, Build preset = "Custom".
Every push to `main` redeploys.

**Custom domain:**
1. Register `factcairn.com` and/or `factcairn.ai` (both were unregistered when checked on 12 Nov 2026 — not reserved until you buy them).
2. Apex domain (`factcairn.com`): in the Portal → Static Web App → *Custom domains* → Add → choose TXT validation, then point an
   ALIAS/ANAME record (or Azure DNS alias) at the app.
3. `www`: add a CNAME `www → <app-name>.<random>.azurestaticapps.net`, then:
   ```powershell
   az staticwebapp hostname set --name factcairn-web --hostname www.factcairn.com
   ```
   HTTPS certificates are issued automatically.

### Option B — any static host
Upload the contents of `site/` to Azure Storage static website, Cloudflare Pages, Netlify or GitHub Pages.
No build command, publish directory = `site`. `staticwebapp.config.json` is ignored by other hosts (harmless).

### Option C — subdomains per product
To serve `deal.factcairn.com` etc., deploy the platform once and each product folder as its own site, then change the
cross-site links (`../deal/index.html` → `https://deal.factcairn.com/`). Paths (`factcairn.com/deal/`) are simpler and
keep one domain's SEO, so they're recommended for now.

---

## 6. Before a public launch

- [ ] Register the domains; run a trademark search on "Factcairn" (CIPO in Canada, USPTO in the US).
- [ ] Remove the `Disallow: /` line from `robots.txt` when you want search engines to index the site.
- [ ] Wire the email forms: e.g. an Azure Function (Static Web Apps managed API, folder `api/`), HubSpot forms or Formspree.
      Change the buttons to `type="submit"` and give the forms an `action`.
- [ ] Privacy policy (Québec Law 25: name a person in charge of personal information, describe collection and consent).
- [ ] Self-host the fonts (download from Google Fonts, serve from `assets/fonts/`) if you want no third-party requests.
- [ ] French version (`/fr/…`) — the copy is written to translate cleanly.
- [ ] Replace [PRICE] placeholders, or remove pricing sections.
- [ ] Real social share images (1200×630) instead of the 512px icon set in `og:image`.
- [ ] Analytics (Azure Application Insights, Plausible or similar) and a cookie notice if needed.
- [ ] Point Sign in / Privacy / Security links to real pages.

---

## 7. Editing or regenerating

- **Small text changes:** edit the HTML in `site/` directly; all styles are inline, so each section is self-contained.
- **Design changes:** the original canvas is in Claude (Design artifact "Factcairn — Platform, Deal, Comply & Respond websites").
  The files in `source/` are those canvas artboards; this package was produced by converting them to plain HTML
  (the `<helmet>` block becomes `<head>`, the `<x-dc>` content becomes `<body>`, links `*.dc.html` become folder paths).
- **Regenerating with an AI assistant:** give it this file plus the `site/` folder and ask for changes "keeping the brand
  rules in §2 and the section structure in §3".
