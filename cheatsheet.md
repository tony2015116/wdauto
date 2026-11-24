## Services one per browser

[TABLE]

    install.packages("pak")
    pak::pkg_install("tony2015116/wdauto")
    library(wdauto)
    driver_dir <- "C:/webdriver"

Windows (x86 / x64) and R ≥ 4.1. Use `"selenium"` only for RSelenium and
other clients of the legacy JSON Wire protocol; tidypptsdd ≥ 0.1.8 uses
`"chromedriver"`.

## [Drivers](https://tony2015116.github.io/wdauto/reference/get_cd.md) match the installed browser

**[get_cd](https://tony2015116.github.io/wdauto/reference/get_cd.md)**(dest_dir,
browser = "chrome", zip = NULL)

Downloads the ChromeDriver or EdgeDriver for the installed browser into
`dest_dir` and returns its path invisibly.

- A cached driver of the same milestone is reused **without network
  access**
- The newest three driver versions are kept
- `zip = "chromedriver-win64.zip"` — install an archive downloaded
  elsewhere

**[get_ss](https://tony2015116.github.io/wdauto/reference/get_ss.md)**(dest_dir,
jar = NULL)

Selenium Server 3.141.59 for `backend = "selenium"`; falls back to
GitHub Releases. `jar =` installs a local JAR.

    get_cd(driver_dir)
    get_cd(driver_dir, browser = "edge")
    # Selenium backend only
    get_ss(driver_dir)

## [Service](https://tony2015116.github.io/wdauto/reference/auto_cs.md) start or reuse

**[auto_cs](https://tony2015116.github.io/wdauto/reference/auto_cs.md)**(dest_dir,
autostart = TRUE, browser = "chrome", backend = "selenium", restart =
"if_idle")

Starts the managed service, or reuses the running one, and waits until
it accepts connections.

| Argument | Effect |
|----|----|
| `backend` | Chrome only: `"chromedriver"` (no Java) or `"selenium"` |
| `autostart = FALSE` | start once, without the login startup entry |
| `restart = "never"` | error instead of restarting after a browser update |

    auto_cs(driver_dir, backend = "chromedriver")
    auto_cs(driver_dir, browser = "edge")

## Mirrors and offline slow or blocked networks

Downloads try the mirror first and always fall back to the official
servers.

    options(wdauto.mirror = "npmmirror")
    # or as an environment variable
    Sys.setenv(WDAUTO_MIRROR = "npmmirror")
    # no network at all: files from
    # another computer
    get_cd(driver_dir, zip = "D:/driver.zip")
    get_ss(driver_dir, jar = "D:/selenium.jar")

Other mirrors: a named vector of URL prefixes and their replacements,
see
[`?get_cd`](https://tony2015116.github.io/wdauto/reference/get_cd.md).

The mirror option in effect when `auto_cs()` writes the startup entry is
reused at login.

## Login and updates runs on its own

- Startup entry: `wdauto_chrome.vbs` / `wdauto_edge.vbs` in the current
  user's Startup folder, hidden, Unicode paths
- At login the driver is resolved again; the start is retried for about
  two minutes while the network comes up
- After a browser update, the next `auto_cs()` restarts the service with
  a matching driver **if no session is open**
- Entries written by wdauto 0.1.x (`.bat`) are replaced

## [Stop and troubleshoot](https://tony2015116.github.io/wdauto/reference/reset_cs.md)

**[reset_cs](https://tony2015116.github.io/wdauto/reference/reset_cs.md)**(browser
= "chrome")

Stops the managed service and removes its startup entry, even when the
process record is damaged.

    reset_cs()
    reset_cs(browser = "edge")

| Symptom | Check |
|----|----|
| Port in use | Another WebDriver (often an old Selenium) is running; stop it |
| No service after login | `%LOCALAPPDATA%/wdauto/startup.log` (Edge: `.../wdauto/edge/`) |
| Driver errors | `%LOCALAPPDATA%/wdauto/webdriver-*/`, newest five kept |
| Download fails | `wdauto.mirror`, or `zip =` |
