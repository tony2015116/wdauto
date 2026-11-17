library(wdauto)

env <- new.env(parent = asNamespace("wdauto"))
selected <- c("build_release", "find_cached_driver", "owned_startup", "auto_cs", "reset_cs",
              "configure_startup", "listener_pids", "service_ready")
for (name in selected) {
  fn <- get(name, envir = asNamespace("wdauto"))
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
  env$installed_driver_version <- function(path) unname(versions[[path]])
  chosen <- env$find_cached_driver(file.path(base, "chromedriver"),
                                   list(version = "156.0.8078.1", platform = "win64"))
  stopifnot(identical(chosen, file.path(drivers[3L], "chromedriver.exe")))

  env$run_tool <- function(...) paste(
    "  TCP  127.0.0.1:4444  0.0.0.0:0  LISTENING  1001",
    "  TCP  [::1]:4444  [::]:0  LISTENING  1001",
    "  TCP  127.0.0.1:4444  127.0.0.1:8539  ESTABLISHED  1001",
    sep = "\r\n"
  )
  stopifnot(identical(env$listener_pids(), 1001L))

  env$require_windows <- function() NULL
  env$service_directory <- function() base
  env$ensure_chromedriver <- function(...) "driver"
  env$installed_selenium_jar <- function(...) "jar"
  env$owned_process <- function(state) if (!is.null(state)) TRUE
  env$read_service_state <- function(...) list(driver = "driver", jar = "jar", pid = 1001L)
  env$service_ready <- function(pid) identical(pid, 1001L)
  env$launch_selenium <- function(...) stop("Must not start a second process.")
  env$auto_cs(base, autostart = FALSE)
  env$ensure_chromedriver <- function(...) "new driver"
  expect_error(env$auto_cs(base, autostart = FALSE), "different binaries")
  env$read_service_state <- function(...) NULL
  expect_error(env$auto_cs(base, autostart = FALSE), "Port 4444 is in use")

  batch <- file.path(base, "chrome_driver.bat")
  other <- file.path(base, "other_workflow.bat")
  env$startup_file <- function() batch
  writeLines("echo unrelated", batch)
  writeLines("echo another task", other)
  env$reset_cs()
  stopifnot(file.exists(batch), file.exists(other))
  writeLines(c("@echo off", "rem wdauto managed startup"), batch)
  env$reset_cs()
  env$reset_cs()
  stopifnot(!file.exists(batch), file.exists(other))

  writeLines(c("@echo off", 'mshta vbscript:createobject("wscript.shell")',
               'java -Dwebdriver.chrome.driver="driver" -jar "selenium-server-standalone-3.141.59.jar"'),
             batch)
  stopifnot(env$owned_startup(batch))
  env$configure_startup(base, drivers[1L])
  env$configure_startup(base, drivers[3L])
  startup <- parse(file.path(base, "startup.R"))
  stopifnot(env$owned_startup(batch), length(startup) == 2L,
            identical(startup[[2L]][[2L]], drivers[3L]))
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
