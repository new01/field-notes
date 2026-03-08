import { QuartzConfig } from "./quartz/cfg"
import * as Plugin from "./quartz/plugins"

const baseUrl = process.env.QUARTZ_BASE_URL ?? "example.com"

/**
 * Quartz 4 Configuration
 *
 * See https://quartz.jzhao.xyz/configuration for more information.
 */
const config: QuartzConfig = {
  configuration: {
    pageTitle: "Website Theme Demo",
    pageTitleSuffix: "",
    enableSPA: true,
    enablePopovers: true,
    analytics: null,
    locale: "en-US",
    baseUrl,
    ignorePatterns: ["private", "templates", ".obsidian"],
    defaultDateType: "modified",
    theme: {
      fontOrigin: "googleFonts",
      cdnCaching: true,
      typography: {
        title: "Atkinson Hyperlegible Mono",
        header: "Atkinson Hyperlegible Mono",
        body: "Ubuntu Mono",
        code: "IBM Plex Mono",
      },
      colors: {
        lightMode: {
          light: "#fffcf0",
          lightgray: "#e6e4d9",
          gray: "#878580",
          darkgray: "#6f6e69",
          dark: "#100f0f",
          secondary: "#73a5c9",
          tertiary: "#5e94bb",
          highlight: "rgba(115, 165, 201, 0.22)",
          textHighlight: "rgba(173, 131, 1, 0.3)",
        },
        darkMode: {
          light: "#100f0f",
          lightgray: "#282726",
          gray: "#878580",
          darkgray: "#cecdc3",
          dark: "#fffcf0",
          secondary: "#73a5c9",
          tertiary: "#8ab7d6",
          highlight: "rgba(115, 165, 201, 0.28)",
          textHighlight: "rgba(208, 162, 21, 0.38)",
        },
      },
    },
  },
  plugins: {
    transformers: [
      Plugin.FrontMatter(),
      Plugin.CreatedModifiedDate({
        priority: ["frontmatter", "git", "filesystem"],
      }),
      Plugin.SyntaxHighlighting({
        theme: {
          light: "github-light",
          dark: "github-dark",
        },
        keepBackground: false,
      }),
      Plugin.ObsidianFlavoredMarkdown({ enableInHtmlEmbed: false }),
      Plugin.GitHubFlavoredMarkdown(),
      Plugin.TableOfContents(),
      Plugin.CrawlLinks({ markdownLinkResolution: "shortest" }),
      Plugin.Description(),
      Plugin.Latex({ renderEngine: "katex" }),
    ],
    filters: [Plugin.RemoveDrafts()],
    emitters: [
      Plugin.AliasRedirects(),
      Plugin.ComponentResources(),
      Plugin.ContentPage(),
      Plugin.FolderPage(),
      Plugin.TagPage(),
      Plugin.ContentIndex({
        enableSiteMap: true,
        enableRSS: true,
      }),
      Plugin.Assets(),
      Plugin.Static(),
      Plugin.Favicon(),
      Plugin.NotFoundPage(),
      // Comment out CustomOgImages to speed up build time
      Plugin.CustomOgImages(),
    ],
  },
}

export default config
