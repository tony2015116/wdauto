## 服务 每个浏览器一个

[TABLE]

    install.packages("pak")
    pak::pkg_install("tony2015116/wdauto")
    library(wdauto)
    driver_dir <- "C:/webdriver"

需要 Windows（x86 / x64）和 R ≥ 4.1。只有 RSelenium 等使用旧 JSON Wire
协议的客户端才需要 `"selenium"`；tidypptsdd ≥ 0.1.8 使用
`"chromedriver"`。

## [驱动](https://tony2015116.github.io/wdauto/reference/get_cd.md) 匹配已安装的浏览器

**[get_cd](https://tony2015116.github.io/wdauto/reference/get_cd.md)**(dest_dir,
browser = "chrome", zip = NULL)

把与已安装浏览器匹配的 ChromeDriver 或 EdgeDriver 下载到
`dest_dir`，并（不可见地）返回驱动路径。

- 同一大版本的驱动下载过一次后，**不联网**也能直接复用
- 只保留最新的 3 个驱动版本
- `zip = "chromedriver-win64.zip"` — 安装在其他电脑上下载好的压缩包

**[get_ss](https://tony2015116.github.io/wdauto/reference/get_ss.md)**(dest_dir,
jar = NULL)

为 `backend = "selenium"` 准备 Selenium Server
3.141.59，下载失败时回退到 GitHub Releases；`jar =` 安装本地 JAR 文件。

    get_cd(driver_dir)
    get_cd(driver_dir, browser = "edge")
    # 仅 Selenium 后端需要
    get_ss(driver_dir)

## [服务](https://tony2015116.github.io/wdauto/reference/auto_cs.md) 启动或复用

**[auto_cs](https://tony2015116.github.io/wdauto/reference/auto_cs.md)**(dest_dir,
autostart = TRUE, browser = "chrome", backend = "selenium", restart =
"if_idle")

启动由 wdauto
管理的服务；服务已在运行时直接复用。返回前会等到服务可以连接。

| 参数 | 作用 |
|----|----|
| `backend` | 仅 Chrome：`"chromedriver"`（不需要 Java）或 `"selenium"` |
| `autostart = FALSE` | 只启动这一次，不写开机启动项 |
| `restart = "never"` | 浏览器升级后直接报错，而不是自动重启 |

    auto_cs(driver_dir, backend = "chromedriver")
    auto_cs(driver_dir, browser = "edge")

## 镜像与离线安装 网络慢或无法访问

下载时先试镜像，失败后总会回退到官方地址。

    options(wdauto.mirror = "npmmirror")
    # 或设置为环境变量
    Sys.setenv(WDAUTO_MIRROR = "npmmirror")
    # 完全不能联网时：安装在其他
    # 电脑上下载好的文件
    get_cd(driver_dir, zip = "D:/driver.zip")
    get_ss(driver_dir, jar = "D:/selenium.jar")

其他镜像：用“网址前缀 = 替换前缀”的命名向量指定，见
[`?get_cd`](https://tony2015116.github.io/wdauto/reference/get_cd.md)。

`auto_cs()` 写入开机启动项时生效的镜像设置，开机后会继续沿用。

## 开机自启与升级 无需手动处理

- 启动项：当前用户启动文件夹中的 `wdauto_chrome.vbs` /
  `wdauto_edge.vbs`，不弹窗口，用户名含中文也能用
- 登录后重新匹配驱动；网络还没就绪时，约两分钟内多次重试
- 浏览器升级后，下一次调用 `auto_cs()`
  时，**如果没有正在使用的会话**，会自动换上匹配的驱动重启
- wdauto 0.1.x 写入的 `.bat` 启动项会被自动替换

## [停止与排查](https://tony2015116.github.io/wdauto/reference/reset_cs.md)

**[reset_cs](https://tony2015116.github.io/wdauto/reference/reset_cs.md)**(browser
= "chrome")

停止由 wdauto 管理的服务并删除开机启动项；进程记录损坏时也能删除启动项。

    reset_cs()
    reset_cs(browser = "edge")

| 现象 | 检查 |
|----|----|
| 端口被占用 | 有其他 WebDriver（常见于旧版 Selenium）在运行，先停止它 |
| 开机后没有服务 | `%LOCALAPPDATA%/wdauto/startup.log`（Edge：`.../wdauto/edge/`） |
| 驱动出错 | `%LOCALAPPDATA%/wdauto/webdriver-*/`，保留最新 5 份 |
| 下载失败 | 设置 `wdauto.mirror`，或用 `zip =` |
