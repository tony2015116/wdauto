library(wdauto)

env <- new.env(parent = asNamespace("wdauto"))
for (name in ls(asNamespace("wdauto"), all.names = TRUE)) {
  fn <- get(name, envir = asNamespace("wdauto"))
  if (!is.function(fn)) next
  environment(fn) <- env
  env[[name]] <- fn
}

expect_error <- function(expr, pattern) {
  failure <- tryCatch(force(expr), error = identity)
  stopifnot(inherits(failure, "error"), grepl(pattern, conditionMessage(failure), fixed = TRUE))
}

local({
  release <- function(version) list(version = version, downloads = list(chromedriver = list(
    list(platform = "win64", url = paste0("win64/", version)),
    list(platform = "win32", url = paste0("win32/", version))
  )))
  builds <- list("156.0.8078" = release("156.0.8078.81"))
  milestones <- function() list("156" = release("156.0.8076.11"))
  stopifnot(identical(env$build_release("156.0.8078.79", "win32", builds, milestones)$url,
                      "win32/156.0.8078.81"))
  stopifnot(identical(env$build_release("156.0.8080.1", "win64", builds, milestones)$url,
                      "win64/156.0.8076.11"))
  expect_error(env$build_release("156.0.8078.79", "unknown", builds), "No ChromeDriver for")

  base <- tempfile()
  dir.create(base)
  on.exit(unlink(base, recursive = TRUE))
  drivers <- file.path(base, "chromedriver", c("155", "156.0.8078.9/win64", "156.0.8078.11/win64", "156.0.8078.99/win32"))
  for (dir in drivers) dir.create(dir, recursive = TRUE)
  stopifnot(all(file.create(file.path(drivers, "chromedriver.exe"))))
  versions <- setNames(c("155.0.8010.9", "156.0.8078.9", "156.0.8078.11", "156.0.8078.99"),
                       file.path(drivers, "chromedriver.exe"))
  executed <- character()
  env$installed_driver_version <- function(path) {
    executed <<- c(executed, path)
    if (path %in% names(versions)) unname(versions[[path]]) else NA_character_
  }
  chosen <- env$find_cached_driver(file.path(base, "chromedriver"),
                                   list(version = "156.0.8078.1", platform = "win64"))
  stopifnot(identical(chosen, file.path(drivers[3L], "chromedriver.exe")),
            identical(executed, chosen))
  # A driver from the same milestone is reused offline when the build differs.
  chosen <- env$find_cached_driver(file.path(base, "chromedriver"),
                                   list(version = "156.0.8080.5", platform = "win64"))
  stopifnot(identical(chosen, file.path(drivers[3L], "chromedriver.exe")))
  # Drivers from older wdauto releases are stored by milestone.
  chosen <- env$find_cached_driver(file.path(base, "chromedriver"),
                                   list(version = "155.0.8010.20", platform = "win64"))
  stopifnot(identical(chosen, file.path(drivers[1L], "chromedriver.exe")))
  stopifnot(is.null(env$find_cached_driver(file.path(base, "chromedriver"),
                                           list(version = "157.0.1.1", platform = "win64"))))
  stopifnot(env$driver_compatible("156.0.8076.11", "156.0.8080.1"),
            !env$driver_compatible("155.0.8076.11", "156.0.8080.1"),
            !env$driver_compatible(NA_character_, "156.0.8080.1"))

  Sys.unsetenv("WDAUTO_MIRROR")
  old <- options(wdauto.mirror = NULL)
  stopifnot(identical(env$candidate_urls("https://example.org/x"), "https://example.org/x"))
  options(wdauto.mirror = "npmmirror")
  stopifnot(identical(env$candidate_urls("https://storage.googleapis.com/chrome-for-testing-public/1.2.3.4/win64/x.zip"),
                      c("https://cdn.npmmirror.com/binaries/chrome-for-testing/1.2.3.4/win64/x.zip",
                        "https://storage.googleapis.com/chrome-for-testing-public/1.2.3.4/win64/x.zip")),
            identical(env$candidate_urls("https://msedgedriver.microsoft.com/1/a.zip"),
                      "https://msedgedriver.microsoft.com/1/a.zip"))
  options(wdauto.mirror = c("https://example.org/a" = "https://mirror.test/b/"))
  stopifnot(identical(env$candidate_urls("https://example.org/a/c"),
                      c("https://mirror.test/b/c", "https://example.org/a/c")))
  options(wdauto.mirror = 1)
  expect_error(env$candidate_urls("https://example.org"), "wdauto.mirror must be")
  options(old)
  Sys.setenv(WDAUTO_MIRROR = "npmmirror")
  stopifnot(length(env$candidate_urls("https://chromedriver.storage.googleapis.com/x")) == 2L)
  Sys.unsetenv("WDAUTO_MIRROR")

  options(wdauto.mirror = c("https://official.test" = "https://mirror.test"))
  tried <- character()
  env$fetch_url <- function(url, ...) {
    tried <<- c(tried, url)
    if (startsWith(url, "https://mirror.test")) stop("blocked") else "ok"
  }
  stopifnot(identical(env$fetch_first("https://official.test/x"), "ok"),
            identical(tried, c("https://mirror.test/x", "https://official.test/x")))
  env$fetch_url <- function(url, ...) stop("offline")
  failure <- tryCatch(env$fetch_first("https://official.test/x"), error = identity)
  stopifnot(inherits(failure, "wdauto_download_error"),
            grepl("https://mirror.test/x: offline", conditionMessage(failure), fixed = TRUE))
  options(old)

  for (version in c("156.0.8078.9", "156.0.8078.11", "156.0.8079.1", "157.0.1.2")) {
    dir.create(file.path(base, "prune", version), recursive = TRUE)
  }
  env$prune_drivers(file.path(base, "prune"), keep = "156.0.8078.9", versions_to_keep = 2L)
  stopifnot(identical(sort(list.files(file.path(base, "prune"))),
                      c("156.0.8078.9", "156.0.8079.1", "157.0.1.2")))

  env$run_tool <- function(...) paste(
    "  TCP  127.0.0.1:4444  0.0.0.0:0  LISTENING  1001",
    "  TCP  [::1]:4444  [::]:0  LISTENING  1001",
    "  TCP  127.0.0.1:4444  127.0.0.1:8539  ESTABLISHED  1001",
    sep = "\r\n"
  )
  stopifnot(identical(env$listener_pids(), 1001L))

  env$require_windows <- function() NULL
  env$service_directory <- function(...) base
  env$ensure_browser_driver <- function(...) "driver"
  env$installed_selenium_jar <- function(...) "jar"
  env$owned_process <- function(state) if (!is.null(state)) TRUE
  env$read_service_state <- function(...) list(driver = "driver", jar = "jar", pid = 1001L)
  env$service_ready <- function(pid, ...) identical(pid, 1001L)
  env$service_idle <- function(...) FALSE
  env$launch_webdriver <- function(...) stop("Must not start a second process.")
  env$auto_cs(base, autostart = FALSE)
  env$ensure_browser_driver <- function(...) "new driver"
  expect_error(env$auto_cs(base, autostart = FALSE), "different binaries")
  # An idle service is restarted with the new driver after a browser update.
  events <- character()
  env$service_idle <- function(...) TRUE
  env$stop_service <- function(...) events <<- c(events, "stop")
  env$launch_webdriver <- function(browser, backend, jar, driver, ...) {
    events <<- c(events, paste("launch", backend, driver, is.null(jar)))
  }
  env$listener_pids <- function(...) integer()
  env$auto_cs(base, autostart = FALSE)
  stopifnot(identical(events, c("stop", "launch selenium new driver FALSE")))
  expect_error(env$auto_cs(base, autostart = FALSE, restart = "never"), "different binaries")
  events <- character()
  env$auto_cs(base, autostart = FALSE, backend = "chromedriver")
  stopifnot(identical(events, c("stop", "launch chromedriver new driver TRUE")))
  env$listener_pids <- function(...) 1001L
  env$read_service_state <- function(...) NULL
  expect_error(env$auto_cs(base, autostart = FALSE), "Port 4444 is in use")

  startup <- file.path(base, "startup")
  dir.create(startup)
  vbs <- file.path(startup, "wdauto_chrome.vbs")
  batch <- file.path(startup, "chrome_driver.bat")
  other <- file.path(startup, "other_workflow.bat")
  env$startup_file <- function(...) vbs
  env$legacy_startup_file <- function(...) batch
  env$read_service_state <- function(...) stop("Invalid wdauto process record: corrupt")
  writeLines("echo unrelated", batch)
  writeLines("echo another task", other)
  writeLines("not an rds", file.path(base, "service.rds"))
  warned <- FALSE
  withCallingHandlers(env$reset_cs(), warning = function(w) {
    warned <<- grepl("No process was stopped", conditionMessage(w))
    invokeRestart("muffleWarning")
  })
  stopifnot(warned, !file.exists(file.path(base, "service.rds")), file.exists(batch), file.exists(other))
  env$read_service_state <- function(...) NULL
  writeLines(c("@echo off", "rem wdauto managed startup"), batch)
  env$reset_cs()
  env$reset_cs()
  stopifnot(!file.exists(batch), file.exists(other))

  writeLines(c("@echo off", 'mshta vbscript:createobject("wscript.shell")',
               'java -Dwebdriver.chrome.driver="driver" -jar "selenium-server-standalone-3.141.59.jar"'),
             batch)
  stopifnot(env$owned_startup(batch))
  # Paths with Chinese characters must survive the startup entry round trip.
  chinese <- file.path(base, "驱动 dir")
  old <- options(wdauto.mirror = "npmmirror")
  env$configure_startup(base, drivers[1L])
  env$configure_startup(base, chinese, backend = "chromedriver")
  options(old)
  bytes <- readBin(vbs, "raw", file.size(vbs))
  lines <- env$read_text_lines(vbs)
  script <- parse(file.path(base, "startup.R"), encoding = "UTF-8")
  call <- script[[3L]]
  stopifnot(!file.exists(batch), env$owned_startup(vbs),
            identical(as.integer(bytes[1:2]), c(255L, 254L)),
            lines[[1L]] == "' wdauto managed startup",
            grepl("startup.R\"\"\", 0, False$", lines[[2L]]),
            length(script) == 3L,
            identical(script[[2L]][[2L]], "npmmirror"),
            identical(call[[2L]], chinese),
            identical(call$backend, "chromedriver"),
            identical(call$log, file.path(base, "startup.log")))
  writeLines("echo foreign", vbs)
  warned <- FALSE
  withCallingHandlers(env$configure_startup(base, chinese), warning = function(w) {
    warned <<- grepl("was preserved", conditionMessage(w))
    invokeRestart("muffleWarning")
  })
  stopifnot(warned, identical(readLines(vbs), "echo foreign"))

  log <- file.path(base, "run-startup.log")
  attempts <- 0L
  env$auto_cs <- function(...) {
    attempts <<- attempts + 1L
    if (attempts < 2L) stop("network not ready")
  }
  stopifnot(isTRUE(env$run_startup(chinese, log = log, attempts = 3L, wait = 0)), attempts == 2L)
  text <- readLines(log, encoding = "UTF-8")
  stopifnot(any(grepl("network not ready", text, fixed = TRUE)), any(text == "  ready"))
})

local({
  windows <- .Platform$OS.type == "windows"
  exe <- file.path(R.home("bin"), if (windows) "Rscript.exe" else "exec/R")
  marker <- "-Dwdauto.instance=regression-test"
  driver <- "driver fixture"
  jar <- "jar fixture"
  worker <- processx::process$new(exe, c("--vanilla", "--slave", "-e", 'cat("ready\\n"); flush.console(); Sys.sleep(25)', "--args",
    marker, jar, paste0("-Dwebdriver.chrome.driver=", driver)), stdout = "|")
  on.exit(worker$kill())
  worker$poll_io(10000)
  stopifnot(identical(worker$read_output_lines(1), "ready"))
  handle <- worker$as_ps_handle()
  state <- list(pid = worker$get_pid(), time = ps::ps_create_time(handle), marker = marker,
                java = normalizePath(ps::ps_exe(handle), winslash = "/"), driver = driver, jar = jar)
  stopifnot(!is.null(wdauto:::owned_process(state)))
  stale <- state
  stale$time <- state$time - 60
  stopifnot(is.null(wdauto:::owned_process(stale)))
  state$marker <- "-Dwdauto.instance=another-service"
  expect_error(wdauto:::owned_process(state), "could not be verified")
})
