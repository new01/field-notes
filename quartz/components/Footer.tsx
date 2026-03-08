// @ts-ignore
import darkmodeScript from "./scripts/darkmode.inline"
import { QuartzComponent, QuartzComponentConstructor, QuartzComponentProps } from "./types"
import style from "./styles/footer.scss"
import { version } from "../../package.json"
import { i18n } from "../i18n"
import { concatenateResources } from "../util/resources"

const footerThemeToggleScript = `
document.addEventListener("nav", () => {
  const updateThemeToggleLabel = (theme) => {
    for (const toggle of document.getElementsByClassName("footer-theme-toggle-label")) {
      toggle.textContent =
        theme === "dark"
          ? "Light mode (not well supported)"
          : "Dark mode (recommended)"
    }
  }

  updateThemeToggleLabel(document.documentElement.getAttribute("saved-theme") ?? "dark")

  const handleThemeChange = (event) => {
    updateThemeToggleLabel(event.detail.theme)
  }

  document.addEventListener("themechange", handleThemeChange)
  window.addCleanup(() => document.removeEventListener("themechange", handleThemeChange))
})
`

interface Options {
  links: Record<string, string>
  showAttribution?: boolean
}

export default ((opts?: Options) => {
  const Footer: QuartzComponent = ({ displayClass, cfg }: QuartzComponentProps) => {
    const year = new Date().getFullYear()
    const links = opts?.links ?? []
    const showAttribution = opts?.showAttribution ?? true
    return (
      <footer class={`${displayClass ?? ""}`}>
        {showAttribution && (
          <p>
            {i18n(cfg.locale).components.footer.createdWith}{" "}
            <a href="https://quartz.jzhao.xyz/">Quartz v{version}</a> © {year}
          </p>
        )}
        <ul>
          {Object.entries(links).map(([text, link]) => (
            <li>
              <a href={link}>{text}</a>
            </li>
          ))}
          <li>
            <button class="footer-theme-toggle darkmode" type="button">
              <span class="footer-theme-toggle-label">Light mode (not well supported)</span>
            </button>
          </li>
        </ul>
      </footer>
    )
  }

  Footer.beforeDOMLoaded = darkmodeScript
  Footer.afterDOMLoaded = concatenateResources(footerThemeToggleScript)
  Footer.css = style
  return Footer
}) satisfies QuartzComponentConstructor
