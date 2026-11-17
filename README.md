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

`get_cd()` matches the installed Chrome build and Windows platform. `get_ss()`
prepares the Selenium 3.141.59 standalone server used by this workflow.
`auto_cs()` waits for the service at `127.0.0.1:4444` to accept connections.
Repeated calls reuse the running managed service when it uses the requested binaries.

By default `auto_cs()` installs or updates the current user's Windows login
startup entry. Pass `autostart = FALSE` for a one-time start without editing
that entry. The launcher resolves the driver again at login. The startup entry
runs after the account logs in. For a `pptsdd` browser download task, Selenium
must already be running when the task starts.

## Start or reuse Edge

```r
get_cd(driver_dir, browser = "edge")
auto_cs(driver_dir, browser = "edge")
```

Edge uses a separate service at `127.0.0.1:4445` and its own Windows login
startup entry. Select Edge in both the startup and download calls in pptsdd
when using this service.

## Stop or troubleshoot the service

Run `reset_cs()` to stop the managed Selenium service and remove its login
startup entry for Chrome. For Edge, use `reset_cs(browser = "edge")`. If Chrome updates while Selenium is running and a different
driver is needed, let active downloads finish, then run `reset_cs()` and
`auto_cs(driver_dir)`.

The service logs are in `%LOCALAPPDATA%/wdauto/webdriver-*/`. The login launcher
writes to `%LOCALAPPDATA%/wdauto/startup.log` for Chrome, or to
`%LOCALAPPDATA%/wdauto/edge/startup.log` for Edge. If port 4444 is already in use
after upgrading from an older version, check whether the previous Selenium
process is still running and stop that instance before starting the new one.
