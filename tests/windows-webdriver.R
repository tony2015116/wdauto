if (identical(Sys.getenv("WDAUTO_WINDOWS_SMOKE"), "true")) {
  library(wdauto)
  smoke_test <- function(browser, backend = "selenium") {
    edge <- browser == "edge"
    selenium <- !edge && backend == "selenium"
    stopifnot(.Platform$OS.type == "windows", !selenium || nzchar(Sys.which("java")))
    root <- tempfile("wdauto-windows-")
    dir.create(root)
    dest <- file.path(root, "webdriver")
    old_localappdata <- Sys.getenv("LOCALAPPDATA")
    old_appdata <- Sys.getenv("APPDATA")
    Sys.setenv(LOCALAPPDATA = root, APPDATA = root)
    passed <- FALSE
    on.exit({
      if (!passed) {
        for (log in list.files(root, pattern = "\\.log$", full.names = TRUE, recursive = TRUE)) {
          message(log, "\n", paste(tail(readLines(log, warn = FALSE), 30L), collapse = "\n"))
        }
      }
      try(suppressWarnings(reset_cs(browser)), silent = TRUE)
      Sys.setenv(LOCALAPPDATA = old_localappdata, APPDATA = old_appdata)
      unlink(root, recursive = TRUE)
    })

    driver <- get_cd(dest, browser)
    stopifnot(file.exists(driver), identical(get_cd(dest, browser), driver))
    if (selenium) stopifnot(file.exists(get_ss(dest)))
    auto_cs(dest, browser = browser, backend = backend)
    state_file <- file.path(wdauto:::service_directory(browser), "service.rds")
    state <- readRDS(state_file)
    auto_cs(dest, browser = browser, backend = backend)
    stopifnot(identical(readRDS(state_file)$pid, state$pid))
    entry <- wdauto:::startup_file(browser)
    stopifnot(wdauto:::owned_startup(entry), wdauto:::read_text_lines(entry)[[1L]] == "' wdauto managed startup")

    http <- function(path, body = NULL, method = NULL) {
      base <- if (edge) "http://127.0.0.1:4445" else "http://127.0.0.1:4444/wd/hub"
      request <- httr2::request(paste0(base, path))
      if (!is.null(body)) request <- httr2::req_body_json(request, body)
      if (!is.null(method)) request <- httr2::req_method(request, method)
      response <- httr2::req_perform(httr2::req_timeout(request, 40))
      httr2::resp_body_json(response)
    }
    output <- file.path(root, "csv")
    dir.create(output)
    download_path <- normalizePath(output, winslash = "\\", mustWork = TRUE)
    options <- list(args = c("--headless=new", "--disable-gpu"),
                    prefs = list(download.default_directory = download_path,
                                 download.prompt_for_download = FALSE))
    body <- if (edge) {
      list(capabilities = list(alwaysMatch = list(browserName = "MicrosoftEdge", "ms:edgeOptions" = options)))
    } else if (!selenium) {
      list(capabilities = list(alwaysMatch = list(browserName = "chrome", "goog:chromeOptions" = options)))
    } else {
      list(desiredCapabilities = list(browserName = "chrome", chromeOptions = options))
    }
    result <- http("/session", body)
    session_id <- result$sessionId
    if (is.null(session_id)) session_id <- result$value$sessionId
    stopifnot(is.character(session_id), length(session_id) == 1L, nzchar(session_id))
    path <- paste0("/session/", session_id)
    html <- '<a download="fixture.csv" href="data:text/csv,a,b%0A1,2">Download</a>'
    http(paste0(path, "/url"), list(url = paste0("data:text/html,", utils::URLencode(html, reserved = TRUE))))
    value <- http(paste0(path, "/element"), list(using = "css selector", value = "a"))$value
    element <- unname(unlist(value))[1L]
    http(paste0(path, "/element/", element, "/click"), method = "POST", body = structure(list(), names = character()))
    csv <- file.path(output, "fixture.csv")
    for (attempt in seq_len(40L)) {
      if (file.exists(csv)) break
      Sys.sleep(0.25)
    }
    stopifnot(identical(readLines(csv, warn = FALSE), c("a,b", "1,2")))
    http(path, method = "DELETE")

    batch <- wdauto:::startup_file(browser)
    other <- file.path(dirname(batch), "unrelated.bat")
    writeLines("echo unrelated", other)
    reset_cs(browser)
    reset_cs(browser)
    stopifnot(!file.exists(state_file), !file.exists(batch), file.exists(other),
              !ps::ps_is_running(ps::ps_handle(state$pid, time = state$time)))
    passed <- TRUE
    message(browser, " (", backend, ") WebDriver session and CSV download passed.")
  }
  smoke_test("chrome")
  smoke_test("chrome", backend = "chromedriver")
  smoke_test("edge")
}
