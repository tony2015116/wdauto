# wdauto <a href="https://tony2015116.github.io/wdauto/"><img src="man/figures/logo.svg" width="120" align="right" alt="wdauto logo"></a>

<!-- badges: start -->
[![Windows](https://badgen.net/badge/icon/windows?icon=windows&label)](https://microsoft.com/windows/)
[![GitHub R package version](https://img.shields.io/github/r-package/v/tony2015116/wdauto)](DESCRIPTION)
[![GitHub last commit](https://img.shields.io/github/last-commit/tony2015116/wdauto)](https://github.com/tony2015116/wdauto/commits/main/)
<!-- badges: end -->

`wdauto` prepares and starts the local Selenium WebDriver service used by
[pptsdd](https://github.com/tony2015116/pptsdd) to download reports through Chrome or Edge.
It runs on x86 and x64 Windows with R 4.1 or newer and the selected browser installed.
Chrome uses Selenium and requires Java on PATH. Edge uses Microsoft Edge WebDriver directly.

## Installation

```r
install.packages("pak")
pak::pkg_install("tony2015116/wdauto")
```

## Start or reuse Chrome

```r
library(wdauto)

driver_dir <- "C:/pptsdd-webdriver"
get_cd(driver_dir)
get_ss(driver_dir)
auto_cs(driver_dir)
```

`get_cd()` matches the installed Chrome milestone and Windows platform and
reuses a cached driver without network access. `get_ss()` prepares the
Selenium 3.141.59 standalone server, which accepts the legacy JSON Wire
protocol used by RSelenium. `auto_cs()` waits for the service at
`127.0.0.1:4444/wd/hub` to accept connections. Repeated calls reuse the
running managed service.

Clients that speak the W3C protocol can skip Java and Selenium:

```r
get_cd(driver_dir)
auto_cs(driver_dir, backend = "chromedriver")
```

ChromeDriver then serves the same address, `127.0.0.1:4444/wd/hub`.

## Start or reuse Edge

```r
get_cd(driver_dir, browser = "edge")
auto_cs(driver_dir, browser = "edge")
```

Edge uses a separate service at `127.0.0.1:4445` and its own login startup
entry. Select Edge in both the startup and download calls in pptsdd.

## Downloads in mainland China or offline

Driver and Selenium downloads try a mirror first and fall back to the
official servers:

```r
options(wdauto.mirror = "npmmirror")   # or Sys.setenv(WDAUTO_MIRROR = "npmmirror")
get_cd(driver_dir)
```

Any other mirror can be given as URL prefix replacements, for example
`options(wdauto.mirror = c("https://storage.googleapis.com/chrome-for-testing-public" = "https://my.mirror/cft"))`.
The option in effect when `auto_cs()` writes the startup entry is reused at
login. Without network access, install archives that were downloaded on
another computer:

```r
get_cd(driver_dir, zip = "chromedriver-win64.zip")
get_ss(driver_dir, jar = "selenium-server-standalone-3.141.59.jar")
```

## Login startup and browser updates

By default `auto_cs()` installs or updates a hidden login startup entry
(`wdauto_chrome.vbs` or `wdauto_edge.vbs` in the current user's Startup
folder). Pass `autostart = FALSE` for a one-time start. At login the driver is
resolved again and the start is retried for about two minutes while the
network comes up. Entries written by earlier wdauto releases are replaced.

When the browser updates while the service is running, the next `auto_cs()`
call restarts the service with the new driver if no session is open. Pass
`restart = "never"` to get an error instead.

## Stop or troubleshoot the service

Run `reset_cs()` to stop the managed service and remove its login startup
entry for Chrome. For Edge, use `reset_cs(browser = "edge")`. `reset_cs()`
still removes the startup entry when the process record is damaged.

The service logs are in `%LOCALAPPDATA%/wdauto/webdriver-*/`; the five newest
are kept. The login launcher writes to `%LOCALAPPDATA%/wdauto/startup.log` for
Chrome, or to `%LOCALAPPDATA%/wdauto/edge/startup.log` for Edge. If port 4444
is already in use after upgrading from an older version, stop the previous
Selenium process before starting the new one.
