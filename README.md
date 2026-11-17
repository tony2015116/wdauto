# wdauto <a href="https://tony2015116.github.io/wdauto/"><img src="man/figures/logo.svg" width="120" align="right" alt="wdauto logo"></a>

<!-- badges: start -->
[![Windows](https://badgen.net/badge/icon/windows?icon=windows&label)](https://microsoft.com/windows/)
[![GitHub R package version](https://img.shields.io/github/r-package/v/tony2015116/wdauto)](DESCRIPTION)
[![GitHub last commit](https://img.shields.io/github/last-commit/tony2015116/wdauto)](https://github.com/tony2015116/wdauto/commits/main/)
<!-- badges: end -->

`wdauto` prepares and starts the local Selenium WebDriver service used by
[pptsdd](https://github.com/tony2015116/pptsdd) to download reports through Chrome.
It runs on x86 and x64 Windows with R 4.1 or newer and an installed Google Chrome.
Java must be available on PATH to start Selenium.

## Installation

```r
install.packages("pak")
pak::pkg_install("tony2015116/wdauto")
```

## Start or reuse the service

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

## Stop or troubleshoot the service

Run `reset_cs()` to stop the managed Selenium service and remove its login
startup entry. If Chrome updates while Selenium is running and a different
driver is needed, let active downloads finish, then run `reset_cs()` and
`auto_cs(driver_dir)`.

The service logs are in `%LOCALAPPDATA%/wdauto/selenium-*/`. The login launcher
writes to `%LOCALAPPDATA%/wdauto/startup.log`. If port 4444 is already in use
after upgrading from an older version, check whether the previous Selenium
process is still running and stop that instance before starting the new one.
