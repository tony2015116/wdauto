# Get started with wdauto

[中文](https://tony2015116.github.io/wdauto/articles/wdauto-zh.html)

wdauto keeps a local WebDriver service running on Windows so that R
code, such as [tidypptsdd](https://github.com/tony2015116/tidypptsdd),
can drive Chrome or Edge. It needs x86 or x64 Windows, R 4.1 or newer,
and the browser you want to use.

| Browser | Address | Runs |
|----|----|----|
| Chrome, `backend = "chromedriver"` | `127.0.0.1:4444/wd/hub` | ChromeDriver, no Java needed |
| Chrome, `backend = "selenium"` (default) | `127.0.0.1:4444/wd/hub` | Selenium Server 3.141.59 on Java, for RSelenium |
| Edge | `127.0.0.1:4445` | Microsoft Edge WebDriver |

## Install

``` r

install.packages("pak")
pak::pkg_install("tony2015116/wdauto")
library(wdauto)
```

## Start Chrome

Choose a folder for the drivers.
[`get_cd()`](https://tony2015116.github.io/wdauto/reference/get_cd.md)
downloads the ChromeDriver that matches the installed Chrome, and
[`auto_cs()`](https://tony2015116.github.io/wdauto/reference/auto_cs.md)
starts the service and waits until it accepts connections.

``` r

driver_dir <- "C:/webdriver"

get_cd(driver_dir)
auto_cs(driver_dir, backend = "chromedriver")
```

Calling
[`auto_cs()`](https://tony2015116.github.io/wdauto/reference/auto_cs.md)
again reuses the running service. Clients that still use RSelenium and
the legacy JSON Wire protocol need the Selenium backend, which also
needs Java on `PATH`:

``` r

get_cd(driver_dir)
get_ss(driver_dir)
auto_cs(driver_dir)
```

## Start Edge

``` r

get_cd(driver_dir, browser = "edge")
auto_cs(driver_dir, browser = "edge")
```

Edge runs as a separate service with its own startup entry, so Chrome
and Edge can run at the same time.

## Download behind a slow or blocked network

Downloads try a mirror first and fall back to the official servers. In
mainland China, set the mirror before the first download:

``` r

options(wdauto.mirror = "npmmirror")   # or Sys.setenv(WDAUTO_MIRROR = "npmmirror")
get_cd(driver_dir)
```

Other mirrors are given as URL prefix replacements:

``` r

options(wdauto.mirror = c(
  "https://storage.googleapis.com/chrome-for-testing-public" = "https://my.mirror/cft"
))
```

Without any network access, install archives that were downloaded on
another computer:

``` r

get_cd(driver_dir, zip = "chromedriver-win64.zip")
get_ss(driver_dir, jar = "selenium-server-standalone-3.141.59.jar")
```

A cached driver for the same browser milestone is reused without network
access, so the service can start offline after the first download.

## Start at login and survive browser updates

By default
[`auto_cs()`](https://tony2015116.github.io/wdauto/reference/auto_cs.md)
writes a hidden startup entry for the current Windows account
(`wdauto_chrome.vbs` or `wdauto_edge.vbs` in the Startup folder). At
login it resolves the driver again and retries for about two minutes
while the network comes up. The mirror option in effect when the entry
was written is reused. Use `autostart = FALSE` for a one-time start.

When Chrome or Edge updates, the next
[`auto_cs()`](https://tony2015116.github.io/wdauto/reference/auto_cs.md)
call restarts the service with a matching driver if no browser session
is open. Use `restart = "never"` to get an error instead.

## Stop and troubleshoot

``` r

reset_cs()                  # Chrome
reset_cs(browser = "edge")  # Edge
```

[`reset_cs()`](https://tony2015116.github.io/wdauto/reference/reset_cs.md)
stops the managed service and removes its startup entry, even when the
process record is damaged.

| Problem | Check |
|----|----|
| Port 4444 or 4445 is in use | Another WebDriver, often an old Selenium started before upgrading, is running. Stop it, then call [`auto_cs()`](https://tony2015116.github.io/wdauto/reference/auto_cs.md) again. |
| The service does not start at login | `%LOCALAPPDATA%/wdauto/startup.log` (Chrome) or `%LOCALAPPDATA%/wdauto/edge/startup.log` (Edge). |
| The driver fails during a session | The service logs in `%LOCALAPPDATA%/wdauto/webdriver-*/`; the five newest are kept. |
| Downloads fail | Set `options(wdauto.mirror = "npmmirror")`, or install an archive with `zip =`. |
