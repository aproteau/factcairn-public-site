# factcairn-public-site

Static marketing sites for Factcairn, deployed to Azure Static Web Apps (Free plan) by GitHub Actions.

| Site | Folder | Azure Static Web App | Domain | Secret |
| --- | --- | --- | --- | --- |
| Company / platform | `sites/www` | `factcairn-www` | `factcairn.com`, `www.factcairn.com` | `AZURE_SWA_TOKEN_WWW` |
| factcairnDeal | `sites/deal` | `factcairn-deal` | `deal.factcairn.com` | `AZURE_SWA_TOKEN_DEAL` |
| factcairnComply | `sites/comply` | `factcairn-comply` | `comply.factcairn.com` | `AZURE_SWA_TOKEN_COMPLY` |
| factcairnRespond | `sites/respond` | `factcairn-respond` | `respond.factcairn.com` | `AZURE_SWA_TOKEN_RESPOND` |

All four apps are in resource group `rg-factcairn-web`.

- `shared/` holds brand files used by every site (`site.css`, logos). The workflows copy it into each site at deploy
  time and replace `?v=DEV` with a hash of `shared/`, so always link shared files as `/shared/...?v=DEV`.
- Links between sites are absolute (`https://deal.factcairn.com/`); links within a site are root-relative.

## Branches

| Branch or event | Goes to |
| --- | --- |
| Push to `main` | Production |
| Push to `staging` | Each app's `staging` environment |
| Pull request into `main` or `staging` | A temporary preview URL, posted on the PR |

Staging and previews always send `X-Robots-Tag: noindex` and a blocking `robots.txt`. Production does too until the
repository variable `INDEX_PRODUCTION` is set to `true` (Settings → Secrets and variables → Actions → Variables);
set it at launch, then re-run the four deploys from the Actions tab.

## Local preview

```bash
scripts/serve.sh www     # or deal, comply, respond — then open http://localhost:8080
```

## Docs

- `docs/hosting-handoff.md` — hosting, deployment and DNS setup.
- `docs/design-handoff/HANDOFF.md` — brand rules, page structure and pre-launch checklist; `source/` holds the design-canvas files.
