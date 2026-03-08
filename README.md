# Website Theme Demo

Quartz-based repo for a personal website that will eventually publish from Obsidian notes.

This repo already includes:

- a customized Quartz layout and theme
- a seeded demo content set for validating rendering and navigation
- local development, build, test, and formatting scripts
- GitHub Actions for CI and GitHub Pages deployment

## Quick Start

```bash
nvm use
npm ci
npm run dev
```

Useful commands:

- `npm run dev` starts the local Quartz server
- `npm run build` creates the static site in `public/`
- `npm run check` runs TypeScript and Prettier checks
- `npm test` runs the existing Quartz test suite
- `npm run format` fixes formatting issues

## Publish To GitHub

1. Create a new GitHub repository and push this repo to it.
2. In GitHub, enable Pages and set the source to `GitHub Actions`.
3. If the site should live under a path, set the repository variable `QUARTZ_BASE_URL` to the full host and subpath, for example `cyne-wulf.io/home`.
4. If the site later moves to a custom domain root, update `QUARTZ_BASE_URL` to that domain.
5. If no variable is set, the deploy workflow falls back to `<owner>.github.io/<repo>`.

## Launch Checklist

- Replace the demo notes in [`content/`](/Users/adevine/codingProjects/web-publishing-test/content) with real published notes.
- Update [`quartz.config.ts`](/Users/adevine/codingProjects/web-publishing-test/quartz.config.ts) analytics and any launch-time plugins.
- Review footer links in [`quartz.layout.ts`](/Users/adevine/codingProjects/web-publishing-test/quartz.layout.ts) so they match the public profiles you want exposed.
- Replace default social/share images in [`quartz/static/`](/Users/adevine/codingProjects/web-publishing-test/quartz/static).

## Notes

- The site is derived from [Quartz](https://quartz.jzhao.xyz/), with local theme and layout customizations.
- `public/` is build output and should stay untracked.
