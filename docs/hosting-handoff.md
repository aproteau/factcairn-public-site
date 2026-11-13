# factcairn.com — Website hosting and deployment handoff

Nov 13, 2026 · @Alex

## Purpose

This doc sets up hosting for factcairn.com: three static sites (www, deal, comply) on Azure Static Web Apps, deployed from one GitHub repo, with custom domains, a staging environment and pull-request previews. It is the same setup as e-nergik.com and tchin.ai, with what went wrong there already fixed.

How to use it:

- Give Claude Code this doc and the factcairn design handoff doc. The design doc decides what the pages look like and say; this doc decides how they are built, deployed and hosted.
- Steps marked **(Claude Code)** are repo work Claude Code does. Steps marked **(you)** happen in the Azure portal, GitHub settings or the domain registrar; Claude Code cannot do them unless it has the Azure CLI and a login.
- Do the steps in order. Each ends with a check.

## Architecture

One repo, `aproteau/factcairn-public-site`, deploys three independent sites to three Azure Static Web Apps on the Free plan (0 $/month). Each site has its own domain, deployment token, staging environment and previews; they share only the brand files in `shared/`.

&#91;embedded content: hosting architecture · 1 repo, 3 Static Web Apps, 4 domains\]

Each site folder deploys only to its own app; `factcairn.com` and `www.factcairn.com` share the www app, the only one using both of its free domain slots.

| Site | Folder | Azure Static Web App | Custom domains | GitHub secret |
| --- | --- | --- | --- | --- |
| Company site | `sites/www` | `factcairn-www` | `factcairn.com`, `www.factcairn.com` | `AZURE_SWA_TOKEN_WWW` |
| Deal | `sites/deal` | `factcairn-deal` | `deal.factcairn.com` | `AZURE_SWA_TOKEN_DEAL` |
| Comply | `sites/comply` | `factcairn-comply` | `comply.factcairn.com` | `AZURE_SWA_TOKEN_COMPLY` |

| Branch or event | Goes to | Search engines |
| --- | --- | --- |
| Push to `main` | Production (the custom domains) | Indexed |
| Push to `staging` | The `staging` environment of each app, a stable URL | Blocked (noindex) |
| Pull request into `main` or `staging` | A temporary preview URL, posted on the PR, deleted when it closes | Blocked (noindex) |

Why three apps and not one: a Static Web App serves the same files on every domain it has and cannot route by hostname, and the Free plan allows only 2 custom domains per app. If Deal or Comply later becomes a real web app (sign-in, database), point its subdomain at that app (for example an Azure App Service) and move its marketing page to `www.factcairn.com`.

## Prerequisites

- [ ] **GitHub repo** `aproteau/factcairn-public-site` (https://github.com/aproteau/factcairn-public-site, created), with `main` as the default branch. Claude Code needs push access to it.
- [ ] **Azure subscription** where you can create resources, and access to the Azure portal (or the Azure CLI, `az`, logged in).
- [ ] **Domain** `factcairn.com` registered, and access to its DNS settings (Namecheap: Domain List → Manage → Advanced DNS).
- [ ] **Design handoff doc** for factcairn: brand, pages and copy for each site.
- [ ] **Email addresses** used on the sites (for example `contact@factcairn.com`) exist, or are planned before launch.

Open decisions to settle before launch, not before starting:

- Canonical address of the company site: `factcairn.com` (recommended, and assumed below) or `www.factcairn.com`.
- Languages: one language, or French at `/` and English under `/en/` as on e-nergik.com.
- Whether Deal and Comply are marketing sites (this setup) or will become sign-in apps (see Architecture).

## Step 1 — Repository scaffold (Claude Code)

Plain static HTML and CSS, no build tool: each site folder is deployed as is, after the workflow copies `shared/` into it. Create this layout on a branch and open a pull request into `main`:

```text
factcairn-public-site/
  shared/                     brand files used by every site (from the design handoff)
    site.css                  tokens and components
    site.js                   small scripts (mobile menu), optional
    fonts/, logo/             font files and logo SVGs
  sites/
    www/                      factcairn.com
      index.html, 404.html, robots.txt, sitemap.xml, staticwebapp.config.json
      assets/                 images used only by this site (favicon, og-image.png)
    deal/                     deal.factcairn.com, same files
    comply/                   comply.factcairn.com, same files
  .github/workflows/
    deploy-www.yml, deploy-deal.yml, deploy-comply.yml
  scripts/serve.sh            local preview: copies shared/ into a site, then serves it
  .gitignore                  sites/*/shared/  (the copies are made at deploy time)
  README.md
```

Rules for the pages:

1. Link shared files with root paths and a version placeholder: `<link rel="stylesheet" href="/shared/site.css?v=DEV">`. The workflow replaces `DEV` with a hash of `shared/`, so browsers never keep an old stylesheet. Don't hand-edit version numbers.
2. Links between sites are absolute (`https://deal.factcairn.com/`); links within a site are root-relative (`/contact/`).
3. Every page has a `<title>`, a meta description, `<link rel="canonical">` with the full production URL, and the `og:` tags with an absolute `og:image` URL.
4. Each site has a bilingual-or-single-language `404.html` and its own `sitemap.xml` listing only its own pages with full URLs.

`staticwebapp.config.json` for each site (same for all three):

```json
{
  "trailingSlash": "auto",
  "routes": [
    { "route": "/shared/*", "headers": { "Cache-Control": "public, max-age=604800" } },
    { "route": "/assets/*", "headers": { "Cache-Control": "public, max-age=604800" } }
  ],
  "responseOverrides": { "404": { "rewrite": "/404.html", "statusCode": 404 } },
  "globalHeaders": {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=()"
  }
}
```

`robots.txt` for each site (production version; the workflow overwrites it on staging and previews):

```text
User-agent: *
Allow: /
Disallow: /404.html
Sitemap: https://factcairn.com/sitemap.xml
```

This is the company site's file; for the others, put `https://deal.factcairn.com/sitemap.xml` and `https://comply.factcairn.com/sitemap.xml` on the `Sitemap:` line.

`scripts/serve.sh` for local preview:

```bash
#!/usr/bin/env bash
# Usage: scripts/serve.sh www|deal|comply   then open http://localhost:8080
set -euo pipefail
site="sites/$1"
rm -rf "$site/shared" && cp -r shared "$site/shared"
cd "$site" && python3 -m http.server 8080
```

**Check:** `scripts/serve.sh www` shows the company site with its styles and fonts; the same for `deal` and `comply`.

## Step 2 — Deployment workflows (Claude Code)

One workflow per site, so a change to one site never redeploys the others. Each runs only when its own folder, `shared/` or its own workflow file changes. This is the www file; the deal and comply files are identical except for the three names in the table under it.

`.github/workflows/deploy-www.yml`:

```yaml
name: Deploy factcairn.com

# main -> production. staging -> the "staging" environment.
# Pull requests into main or staging -> a temporary preview URL posted on the PR.
on:
  push:
    branches: [main, staging]
    paths: ['sites/www/**', 'shared/**', '.github/workflows/deploy-www.yml']
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches: [main, staging]
    paths: ['sites/www/**', 'shared/**', '.github/workflows/deploy-www.yml']
  workflow_dispatch:

env:
  SITE: sites/www

jobs:
  deploy:
    if: github.event_name != 'pull_request' || github.event.action != 'closed'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write   # lets the deploy action post the preview URL on the PR
    steps:
      - uses: actions/checkout@v5

      - name: Copy shared brand files into the site
        run: rm -rf "$SITE/shared" && cp -r shared "$SITE/shared"

      - name: Version shared files (cache busting)
        run: |
          V=$(find shared -type f -print0 | sort -z | xargs -0 cat | sha256sum | cut -c1-10)
          find "$SITE" -name '*.html' -exec sed -i "s/?v=DEV/?v=$V/g" {} +

      - name: Keep staging and previews out of search engines
        if: github.ref != 'refs/heads/main'
        run: |
          jq '.globalHeaders["X-Robots-Tag"] = "noindex, nofollow"' "$SITE/staticwebapp.config.json" > cfg.json
          mv cfg.json "$SITE/staticwebapp.config.json"
          printf 'User-agent: *\nDisallow: /\n' > "$SITE/robots.txt"

      - name: Deploy
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_SWA_TOKEN_WWW }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: upload
          app_location: sites/www
          api_location: ''
          output_location: ''
          skip_app_build: true
          production_branch: main   # any other branch deploys to an environment named after it

  close_preview:
    if: github.event_name == 'pull_request' && github.event.action == 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_SWA_TOKEN_WWW }}
          action: close
```

| File | `name:` | Folder (in `paths`, `SITE` and `app_location`) | Secret |
| --- | --- | --- | --- |
| `deploy-www.yml` | Deploy factcairn.com | `sites/www` | `AZURE_SWA_TOKEN_WWW` |
| `deploy-deal.yml` | Deploy deal.factcairn.com | `sites/deal` | `AZURE_SWA_TOKEN_DEAL` |
| `deploy-comply.yml` | Deploy comply.factcairn.com | `sites/comply` | `AZURE_SWA_TOKEN_COMPLY` |

Why these lines matter:

- `production_branch: main` is what keeps a push to `staging` from overwriting production. Never remove it.
- `pull-requests: write` lets Azure post the preview URL on the PR; without it the deploy works but the comment fails.
- `workflow_dispatch` lets you run a deploy by hand from the Actions tab (pick `main` for production).
- The jobs fail until the secrets exist (Step 4). That is expected on the first pull request.

**Check:** the three files pass a YAML linter, and each names its own folder and secret in all four places.

## Step 3 — Create the three Azure Static Web Apps (you)

Create one resource group and three Static Web Apps on the Free plan, with **Other** as the deployment source, so Azure doesn't add its own workflow to the repo.

**In the Azure portal:**

1. Create a resource group: name `rg-factcairn-web`, region Canada Central (the group's region only stores metadata).
2. Create a resource → **Static Web App**, three times:
   - Subscription: yours; Resource group: `rg-factcairn-web`
   - Name: `factcairn-www`, then `factcairn-deal`, then `factcairn-comply`
   - Plan type: **Free**
   - Region for Azure Functions and staging details: **Central US** (same as the energik apps)
   - Deployment source: **Other**
3. Open each app → **Overview** and note its **URL** (`https://<name>-<random>.<n>.azurestaticapps.net`). You need these hostnames for DNS in Step 6.

**Or with the Azure CLI** (Cloud Shell in the portal works, `>_` icon):

```bash
az group create --name rg-factcairn-web --location canadacentral
for s in www deal comply; do
  az staticwebapp create --name factcairn-$s --resource-group rg-factcairn-web \
    --location centralus --sku Free
done
for s in www deal comply; do
  echo "factcairn-$s: $(az staticwebapp show -n factcairn-$s -g rg-factcairn-web --query defaultHostname -o tsv)"
done
```

Without `--source`, the CLI creates the app with no linked repo, the same as **Other** in the portal.

**Check:** the three apps show in `rg-factcairn-web`, each with a default URL that shows the Azure placeholder page.

## Step 4 — Connect GitHub to Azure (you)

Each app has a deployment token. GitHub Actions sends the site to Azure with it, so it goes into a repository secret, never into the repo or a chat.

1. In Azure, open `factcairn-www` → **Overview** → **Manage deployment token** (in the toolbar; on a narrow window it hides under **…**) → copy.
2. In GitHub, open `aproteau/factcairn-public-site` → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**: name `AZURE_SWA_TOKEN_WWW`, value the token.
3. Repeat for `factcairn-deal` → `AZURE_SWA_TOKEN_DEAL` and `factcairn-comply` → `AZURE_SWA_TOKEN_COMPLY`.

With the CLI and the GitHub CLI (`gh`), logged in to both:

```bash
for s in www deal comply; do
  token=$(az staticwebapp secrets list -n factcairn-$s -g rg-factcairn-web --query properties.apiKey -o tsv)
  gh secret set "AZURE_SWA_TOKEN_${s^^}" --repo aproteau/factcairn-public-site --body "$token"
done
```

If a token is ever exposed (pasted in a chat, shown in a screenshot), reset it in the same **Manage deployment token** panel and update the secret.

**Check:** Settings → Secrets and variables → Actions lists the three secrets.

## Step 5 — First deployment and checks (Claude Code, then you)

1. **(Claude Code)** Push the scaffold branch and open a pull request into `main`. The three workflows run; each posts a comment "Azure Static Web Apps: Your stage site is ready!" with a preview URL.
2. **(you)** Open the three preview URLs and check the pages against the design handoff.
3. **(you)** Merge the pull request only after the last commit's checks are green. Merging while a push is still in progress leaves that push out of `main`.
4. **(Claude Code)** Confirm the merge reached production: every commit of the branch is in `origin/main` (`git merge-base --is-ancestor <last commit> origin/main`), and the three "Deploy" runs on `main` succeeded.
5. **(Claude Code)** Create the staging branch from `main`: `git push origin main:staging`. Three more runs deploy the `staging` environments.

**Checks (Claude Code, on the default `azurestaticapps.net` URLs):**

```bash
for url in <www default URL> <deal default URL> <comply default URL>; do
  curl -sI "$url/" | grep -iE '^(HTTP|x-robots-tag)'          # 200, and no X-Robots-Tag in production
  curl -s  "$url/" | grep -o 'site.css?v=[^"]*'                # a hash, never ?v=DEV
  curl -sI "$url/does-not-exist" | head -1                       # 404
done
```

On a staging URL the same headers must show `x-robots-tag: noindex, nofollow`.

## Step 6 — Custom domains and DNS (you)

Add each domain in Azure first, then create its DNS record, then let Azure validate it; HTTPS certificates are issued automatically and free. Do the subdomains first (simple CNAMEs), the bare `factcairn.com` last.

**DNS records to create** (Namecheap: Domain List → `factcairn.com` → Manage → Advanced DNS → Add new record; type only the host part, Namecheap adds `.factcairn.com`):

| Type | Host | Value | Points to |
| --- | --- | --- | --- |
| CNAME | `www` | default hostname of `factcairn-www` | company site |
| CNAME | `deal` | default hostname of `factcairn-deal` | Deal |
| CNAME | `comply` | default hostname of `factcairn-comply` | Comply |
| TXT | `@` (or the host Azure shows) | the validation code Azure shows | proves you own `factcairn.com` |
| ALIAS | `@` | default hostname of `factcairn-www` | company site, bare domain |

Before adding them, delete Namecheap's default parking records on `www` and `@` (a CNAME to `parkingpage.namecheap.com` and a URL Redirect). Keep any MX and TXT records used for email.

**In Azure, for each app** → **Settings** → **Custom domains** → **+ Add** → **Custom domain on other DNS**:

1. `factcairn-deal`: add `deal.factcairn.com` (CNAME validation) → create the CNAME → **Add**.
2. `factcairn-comply`: add `comply.factcairn.com` the same way.
3. `factcairn-www`: add `www.factcairn.com` the same way.
4. `factcairn-www`: add `factcairn.com` → Azure shows a **TXT** code → create the TXT record → wait for **Validated** (minutes to a few hours) → create the ALIAS record.
5. `factcairn-www` → Custom domains: select `factcairn.com` → **Set as default**, so `www.factcairn.com` redirects to it.

The Free plan allows 2 custom domains per app, so `factcairn-www` is full after step 4. A registrar without ALIAS or ANAME records cannot point the bare domain at a Static Web App; move the domain's DNS to Azure DNS and use an alias record there.

With the CLI, the same as steps 1 to 4:

```bash
az staticwebapp hostname set -n factcairn-deal   -g rg-factcairn-web --hostname deal.factcairn.com
az staticwebapp hostname set -n factcairn-comply -g rg-factcairn-web --hostname comply.factcairn.com
az staticwebapp hostname set -n factcairn-www    -g rg-factcairn-web --hostname www.factcairn.com
az staticwebapp hostname set -n factcairn-www    -g rg-factcairn-web --hostname factcairn.com \
  --validation-method dns-txt-token --no-wait
az staticwebapp hostname show -n factcairn-www -g rg-factcairn-web --hostname factcairn.com --query validationToken -o tsv
```

**Check** (any machine):

```bash
dig +short CNAME deal.factcairn.com          # the factcairn-deal default hostname
curl -sI https://factcairn.com/ | head -1     # HTTP/2 200
curl -sI https://www.factcairn.com/ | grep -i '^location'   # redirect to https://factcairn.com/
```

## Step 7 — Staging and previews (day to day)

Each app keeps a permanent **staging** copy at `https://<app default host>-staging.<region>.azurestaticapps.net`, deployed from the `staging` branch, and a temporary preview per pull request at `https://<app default host>-<PR number>.<region>.azurestaticapps.net`. Both are hidden from search engines by the workflow, but anyone with the address can open them; password protection needs the Standard plan (about 9 USD per app per month).

The routine, for every change:

1. Work on a branch; open a pull request into `main` (or into `staging` to stage work that should not go live yet).
2. Check the preview URL Azure posts on the pull request.
3. Merge when the latest commit's checks are green; production updates within a minute or two.
4. To hold a bigger change back: merge it into `staging`, review it on the staging URLs, then open a pull request from `staging` into `main`.

The Free plan keeps at most 3 preview environments per app, `staging` included. Close or merge stale pull requests, or delete old environments under the app's **Environments** page, if new previews stop appearing.

## Launch checklist and troubleshooting

- [ ] Three Static Web Apps on the Free plan, source **Other**
- [ ] Three secrets in the repo; three workflows green on `main`
- [ ] `staging` branch deployed; its URLs send `x-robots-tag: noindex`
- [ ] Four custom domains **Ready** in Azure; `factcairn.com` set as default
- [ ] Email addresses on the pages exist and receive mail
- [ ] Privacy page, and legal notice if wanted, with the company's real details (no placeholders)
- [ ] Each site's `sitemap.xml` uses its production URLs

| Symptom | Cause | Fix |
| --- | --- | --- |
| A page looks unstyled for some visitors after a CSS change | Their browser kept the old `site.css` (cached 7 days) | The workflow versions shared files; never link `site.css` without `?v=DEV` |
| The preview URL is not posted on the PR | The deploy job lacks `pull-requests: write` | Keep the `permissions` block in each workflow |
| A change is missing on the live site after a merge | The PR was merged before its last push arrived | Merge only when the latest commit's checks are green; check with `git merge-base --is-ancestor` |
| A push to `staging` changed production | `production_branch: main` was removed | Put it back in the deploy step |
| A workflow did not run | The change was outside its `paths` | Expected; run it by hand from Actions (`workflow_dispatch`) if needed |
| Deploy fails with an authentication or token error | Secret missing, misnamed or reset | Copy the token again (Step 4), check the secret's name |
| Custom domain stuck on **Validating** | DNS record missing, wrong host, or not propagated | Check the record with `dig`; remove conflicting parking records; wait up to a few hours |
| New previews stop appearing | 3 preview environments already used | Close old PRs or delete environments in Azure |

## Prompt for Claude Code

Start a Claude Code session on `aproteau/factcairn-public-site` and paste this, with the two links filled in:

```text
Build and publish the factcairn.com websites.

Hosting and deployment handoff: <link to this doc>
Design handoff: <link to the design handoff doc>

Read both docs first. Follow the hosting handoff exactly for the repo layout, the three
workflows, staticwebapp.config.json, robots.txt, the cache-busting placeholder and the
staging setup. Follow the design handoff for the brand, pages and copy of each site
(www, deal, comply).

Do Steps 1 and 2 on a branch and open one pull request into main. Tell me when the three
preview URLs are posted, and list what I must do in Azure, GitHub and Namecheap (Steps 3,
4 and 6) with the exact values. Don't merge pull requests yourself. After I merge, confirm
every commit reached main, create the staging branch, and run the Step 5 checks.
```

The secrets (Step 4) can be added before or after the first pull request; the workflows fail until they exist, then pass on the next push.
