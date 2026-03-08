---
title: Markdown Playground
description: A dense note that exercises common Quartz and Obsidian-flavored markdown features.
tags:
  - demo
  - markdown
  - obsidian
---

This page is meant to stress the common authoring surfaces: **bold**, _italic_, **_both_**, `inline code`, ==highlighted text==, and ~~strikethrough~~.

It also links outward to [[showcase/technical-demo|the technical demo]] and [[showcase/knowledge-graph|the graph/transclusion demo]] so backlinks, popovers, and the local graph have something real to work with.

## Callouts and Quotes

> [!note] Standard Callout
> Quartz should render Obsidian-style callouts without extra setup.
>
> This one includes a [[journal/launch-log|wikilink]] and a footnote reference.[^callout]

> [!tip]- Collapsible Callout
> Collapsible callouts are useful for hiding long explanations, setup notes, or spoilers.
>
> - They can contain lists
> - `inline code`
> - and links to [[showcase/technical-demo#Math and Diagrams]]

> [!warning] Nested Formatting
> Blockquotes and callouts should preserve **emphasis**, _italics_, and ==highlighting==.

> Plain blockquotes still matter when you want tone without the stronger chrome of a callout.

For the full type gallery, see [[showcase/callout-gallery|Callout Gallery]].

## Lists and Tasks

- Bullet one
- Bullet two with an embedded reference to [[showcase/knowledge-graph]]
- Bullet three with `inline code`

1. Ordered items should render cleanly.
2. They should also maintain spacing around paragraphs.
3. And they give the table of contents another section to jump to.

- [x] Task lists are supported via GitHub Flavored Markdown
- [ ] Unchecked tasks should stay interactive-looking on the page
- [ ] Backlinks should show which notes point here after the site builds

## Tables and Footnotes

| Feature   | Syntax      | Why it matters                           |
| --------- | ----------- | ---------------------------------------- | --- | --- | ------------------------------ |
| Wikilinks | `[[note]]`  | Enables graph relationships and popovers |
| Callouts  | `> [!info]` | Recreates Obsidian-style note structure  |
| Footnotes | `[^id]`     | Useful for dense reference writing       |
| Tables    | `           | a                                        | b   | `   | Good for comparisons and specs |

Here is a sentence with a footnote for testing.[^table]

## Block Reference Target

This paragraph is a reusable block that other notes can transclude. ^playground-block

%% Quartz should ignore this Obsidian comment block in the rendered output. %%

[^callout]: Footnotes should render at the bottom of the page with jump links.

[^table]: This confirms GFM footnotes are active in the current Quartz config.
