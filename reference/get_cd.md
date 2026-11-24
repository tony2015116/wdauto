# Download a browser WebDriver

Resolves the WebDriver that matches the installed browser and stores it
in `dest_dir`. A cached driver for the same browser milestone is reused
without network access. Set `options(wdauto.mirror = "npmmirror")` (or
the `WDAUTO_MIRROR` environment variable) to try a mirror before the
official download servers. A named character vector of URL prefixes and
their replacements can be used for any other mirror.

## Usage

``` r
get_cd(dest_dir, browser = c("chrome", "edge"), zip = NULL)
```

## Arguments

- dest_dir:

  Directory containing the WebDriver binaries.

- browser:

  Browser to manage, either `chrome` or `edge`.

- zip:

  Optional path to a driver archive that was downloaded manually, for
  computers without access to the download servers.

## Value

Invisibly, the path of the driver executable.

## Examples

``` r
if (FALSE) get_cd("C:/pptsdd-webdriver") # \dontrun{}
```
