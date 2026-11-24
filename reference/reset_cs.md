# Stop the managed browser driver and remove its login startup entry

`reset_cs()` is the recovery tool: an unreadable process record or a
process that cannot be verified produces a warning, and the startup
entry is still removed.

## Usage

``` r
reset_cs(browser = c("chrome", "edge"))
```

## Arguments

- browser:

  Browser to stop, either `chrome` or `edge`.

## Value

Invisibly NULL.

## Examples

``` r
if (FALSE) reset_cs() # \dontrun{}
```
