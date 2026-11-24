# Changelog

## wdauto 0.2.0

### Bug fixes

- The login startup entry is now a UTF-16 VBScript file, so paths with
  Chinese or other non-ASCII characters (for example in the Windows user
  name) work. It also runs without a console window. Earlier `.bat`
  entries are replaced.
- A cached driver from the same browser milestone is reused, so starting
  the service no longer needs network access when Chrome has no
  exact-build ChromeDriver.
- [`reset_cs()`](https://tony2015116.github.io/wdauto/reference/reset_cs.md)
  warns instead of failing when the process record is damaged or cannot
  be verified, and still removes the startup entry.
- Only the newest driver versions and service logs are kept, and only
  the chosen cached driver is executed for verification.
- Tool failures report their output or timeout instead of an empty
  message.
- Edge WebDriver listens only on the loopback interface.

### New features

- `options(wdauto.mirror = "npmmirror")` or custom URL prefix rules try
  a mirror before the official download servers.
- `get_cd(zip = )` and `get_ss(jar = )` install manually downloaded
  files.
- ChromeDriver is downloaded directly for the exact Chrome version
  before the Chrome for Testing metadata is used.
- Selenium Server falls back to GitHub Releases.
- `auto_cs(backend = "chromedriver")` serves Chrome through ChromeDriver
  at `127.0.0.1:4444/wd/hub` without Java or Selenium.
- `auto_cs(restart = "if_idle")` restarts an idle service after a
  browser update instead of failing.
- The login launcher retries for about two minutes and rotates its log.
- [`get_cd()`](https://tony2015116.github.io/wdauto/reference/get_cd.md)
  and
  [`get_ss()`](https://tony2015116.github.io/wdauto/reference/get_ss.md)
  return the installed path invisibly.

### Earlier changes since 0.1.1

- Support Microsoft Edge with a dedicated WebDriver service and login
  startup entry.

- Scope Selenium process and login startup cleanup to `wdauto`-managed
  resources.

- Match ChromeDriver to the installed Chrome build and validate cached
  binaries.

- Verify Selenium readiness, report startup logs, and refresh the login
  launcher.

- Use Selenium 3.141.59 as the stable default for the existing pptsdd
  connection.

## wdauto 0.1.1

- create `wdauto` package.
