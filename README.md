# RemotePath

**Discover Online Work. Build Your Path.**

RemotePath is an independent English-language guide to global online professions, work platforms, and tools, with practical context for people in Egypt. It is an information directory, not a job marketplace, recruiter, course provider, or guarantee of work or payment access.

## Catalog

- 15 categories
- 229 specializations, each with tailored AI learning guidance
- 51 online-work platforms
- 68 work tools

## Features

- Browse categories, profession pages, related tools, and platforms.
- Search all catalog types, ranked by relevance, with type and category filters.
- Explore filterable platform and tool directories with Egyptian availability fields.
- Copy a standalone learning prompt tailored to each profession.
- Responsive design, accessible navigation, metadata, sitemap, and GitHub Pages workflow.

## Technology and structure

Static HTML, CSS, vanilla JavaScript, and JSON; no build step, package manager, backend, or runtime dependency installation.

- HTML files are page shells; category, specialization, and directory views render from JSON.
- assets/css contains shared and responsive styles.
- assets/js contains routing, search, data loading, prompts, navigation, and SEO behavior.
- data contains the catalog and relationships.
- docs contains schema, validation, phase notes, and the [Egyptian Arabic GitHub Pages guide](docs/GITHUB_DEPLOYMENT_GUIDE_AR.md).
- .github/workflows/pages.yml uploads only the website files for deployment.

## Run locally on Windows

Open PowerShell in the project folder and run `.\scripts\serve_preview.ps1`. Visit http://127.0.0.1:8765/ and stop the server with Ctrl+C. Opening HTML via file:// is unsupported because browsers block JSON fetches. Production paths are configured for the repository site /RemotePath/.

## Publish

Set GitHub Pages to use GitHub Actions. The workflow runs on pushes to main and can be started from Actions. Review the Git remote and changes before the first push. This local handoff did not push or publish the repository.

## Notes

- Keep IDs, slugs, and relationship keys consistent; see docs/CONTENT_SCHEMA.md.
- Search needs JavaScript and working JSON fetches.
- Egypt availability distinguishes registration, project availability, and payment access. Unconfirmed is not a positive claim. Recheck official terms and payment methods because they change.
- RemotePath does not guarantee jobs, platform access, or income.

See [the Arabic final refinement report](docs/FINAL_REFINEMENT_REPORT_AR.md), [the QA checklist](docs/FINAL_QA_CHECKLIST.md), and [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) for checks and limitations.
- See the [final prompt patch report (Arabic)](docs/FINAL_PROMPT_PATCH_REPORT_AR.md) for prompt behavior, validation results, and remaining review limits.
