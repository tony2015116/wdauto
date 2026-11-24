# Start a local WebDriver service

Starts, or reuses, the managed WebDriver service for one browser. Chrome
is served at `127.0.0.1:4444/wd/hub` and Edge at `127.0.0.1:4445`.

## Usage

``` r
auto_cs(
  dest_dir,
  autostart = TRUE,
  browser = c("chrome", "edge"),
  backend = c("selenium", "chromedriver"),
  restart = c("if_idle", "never")
)
```

## Arguments

- dest_dir:

  Directory containing the WebDriver binaries.

- autostart:

  Whether to install or update the hidden Windows login startup entry.
  Use FALSE to start the service without writing it.

- browser:

  Browser to manage, either `chrome` or `edge`.

- backend:

  Chrome only. `"selenium"` runs Selenium Server 3.141.59 on Java, which
  also accepts the legacy JSON Wire protocol used by RSelenium.
  `"chromedriver"` runs ChromeDriver directly at the same address (W3C
  protocol only) and needs neither Java nor
  [`get_ss()`](https://tony2015116.github.io/wdauto/reference/get_ss.md).

- restart:

  What to do when the running service uses a different driver, for
  example after a browser update. `"if_idle"` restarts it when it has no
  open sessions; `"never"` raises an error instead.

## Value

Invisibly NULL once the service is ready.

## Examples

``` r
if (FALSE) auto_cs("C:/pptsdd-webdriver") # \dontrun{}
```
