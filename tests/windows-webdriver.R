if (identical(Sys.getenv("WDAUTO_WINDOWS_SMOKE"), "true")) {
  library(wdauto)
  local({
    stopifnot(.Platform$OS.type == "windows", nzchar(Sys.which("java")))
    root <- tempfile("wdauto-windows-")
    dir.create(root)
    dest <- file.path(root, "webdriver")
    old_localappdata <- Sys.getenv("LOCALAPPDATA")
    old_appdata <- Sys.getenv("APPDATA")
    Sys.setenv(LOCALAPPDATA = root, APPDATA = root)
    on.exit({
      try(reset_cs(), silent = TRUE)
      Sys.setenv(LOCALAPPDATA = old_localappdata, APPDATA = old_appdata)
      unlink(root, recursive = TRUE)
    })

    get_cd(dest)
    get_ss(dest)
    auto_cs(dest)
    state_file <- file.path(root, "wdauto", "service.rds")
    state <- readRDS(state_file)
    auto_cs(dest)
    stopifnot(identical(readRDS(state_file)$pid, state$pid))

    http <- function(path, body = NULL, method = NULL) {
      request <- httr2::request(paste0("http://127.0.0.1:4444/wd/hub", path))
      if (!is.null(body)) request <- httr2::req_body_json(request, body)
      if (!is.null(method)) request <- httr2::req_method(request, method)
      response <- httr2::req_perform(httr2::req_timeout(request, 40))
      httr2::resp_body_json(response)
    }
    output <- file.path(root, "csv")
    dir.create(output)
    download_path <- normalizePath(output, winslash = "\\", mustWork = TRUE)
    # Match the legacy session request currently made by pptsdd through RSelenium.
    result <- http("/session", list(desiredCapabilities = list(browserName = "chrome",
      chromeOptions = list(args = c("--headless=new", "--disable-gpu"),
                           prefs = list(download.default_directory = download_path,
                                        download.prompt_for_download = FALSE)))))
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

    batch <- wdauto:::startup_file()
    other <- file.path(dirname(batch), "unrelated.bat")
    writeLines("echo unrelated", other)
    reset_cs()
    reset_cs()
    stopifnot(!file.exists(state_file), !file.exists(batch), file.exists(other),
              !ps::ps_is_running(ps::ps_handle(state$pid, time = state$time)))
  })
}
