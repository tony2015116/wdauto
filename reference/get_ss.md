# Download Selenium Server

Only needed for the default `backend = "selenium"` of
[`auto_cs()`](https://tony2015116.github.io/wdauto/reference/auto_cs.md)
with Chrome. The JAR is downloaded from the configured mirror (see
[`get_cd()`](https://tony2015116.github.io/wdauto/reference/get_cd.md)),
the Selenium release bucket, or GitHub Releases, in that order.

## Usage

``` r
get_ss(dest_dir, jar = NULL)
```

## Arguments

- dest_dir:

  Directory containing the WebDriver binaries.

- jar:

  Optional path to a `selenium-server-standalone-3.141.59.jar` that was
  downloaded manually.

## Value

Invisibly, the path of the Selenium JAR.

## Examples

``` r
if (FALSE) get_ss("C:/pptsdd-webdriver") # \dontrun{}
```
