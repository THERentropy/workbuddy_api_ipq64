# workbuddy-ipq64

> 上游：**[linguo2625469/workbuddy2api-panel](https://github.com/linguo2625469/workbuddy2api-panel)**（`main` 分支，`Sliverkiss/workbuddy2api` 的面板增强分支）。
> 该分支内嵌了 `/panel/` 管理面板与成长任务接口，本插件对接的是这一版。

## 能做什么

| 能力 | 说明 |
| --- | --- |
| 服务生命周期 | 页面一键启停 / 重启、开机自启、5 分钟看门狗自动拉起 |
| 端口收敛 | 上游网关固定只监听 `127.0.0.1:7863`，对外只暴露自研代理端口（默认 `17863`） |
| 网页内加号 | 生成 OAuth 授权链接 → 浏览器登录 → 轮询落盘 `auths/workbuddy-<uid>.json` |
| 账号池状态 | 健康 / 限流冷却 / 积分冷却 / 降权 / 熔断 / 禁用、冷却剩余、成功率、积分与总额度、模型级限额台账、凭证有效期 |
| 成长任务 | 「成长任务」页扫描全账号待办（成长 17 项 + 开学季），一键排队执行，实时看队列进度 |
| 刷新余额 | 走上游面板全量查余额（余额恢复的冷却账号自动解冻） |
| 上游面板入口 | 状态页一键打开上游内嵌 `/panel/`（用任一把分发密钥登录），配置/日志/模型档位一应俱全 |
| 多密钥分发 | 每把密钥独立有效期、最大 IP 数、IP 白名单、模型白名单、Token 配额；库中仅存 SHA-256，明文只展示一次 |
| 调用审计 | 记录密钥、来源 IP、模型、状态码、首字延迟、耗时、Token、实际扣费（上游 `usage.credit`），JSONL 按天滚动 |
| 可视化设置 | 定时任务（含夜猫子 / 余额后台刷新）、并发与熔断降权、软限流冷却、上游三段超时、出站指纹、会话粘性、数据目录迁移等 |
| 固件皮肤 | 自动适配 asuswrt / rog / tuf / ts 皮肤（主色变量统一，按钮/描边/高亮一起跟随） |

## 架构

```
下游客户端 ──► wb2api-ctl serve :17863  ──► wb2api（上游） 127.0.0.1:7863 ──► CodeBuddy
               多密钥鉴权·限流·审计            账号池·协议转换·内嵌 /panel/
                      │
                      └─► <数据目录>/audit/audit-YYYYMMDD.jsonl
                          <数据目录>/keys.json（SHA-256）

软件中心页面 Module_workbuddy.asp ──► POST /_api/ ──► workbuddy_*.sh ──► wb2api-ctl 子命令
                                  └──► GET /_temp/workbuddy_*.json（脚本输出）
                                          └─ workbuddy_task.sh ──► wb2api-ctl panel /panel/api/*
```

上游内嵌面板的两条通道：

- `GET /panel/`、`GET /panel/app.js`：纯静态资源（不含密钥），代理层匿名放行，浏览器才能打开；
- `GET/POST /panel/api/*`：仍走本插件的分发密钥鉴权，转发时把 `Authorization` 换成上游 `api_key`，
  所以面板里填**任一把 `sk-…` 分发密钥**即可管理。

- **为什么要有 `wb2api-ctl`**：上游只支持一个全局 `api_key`，多密钥 / 配额 / 审计无法靠配置实现；同时路由器上既没有 `python3` 也没有 `jq`，用 busybox `sed/awk` 解析 JSON 极易出错。所以用一个 Go 静态二进制同时承担「反向代理鉴权网关 + 所有 JSON 处理」。
- **流式不破坏**：代理层使用 `FlushInterval: -1` 立即 flush，SSE 原样透传；用量数据靠 64KB 环形缓冲从响应尾部抓取，不缓存整条流。

## 目录结构

```
.
├── guard/                         自研 Go 模块（纯标准库，零第三方依赖）
│   ├── main.go                    子命令分发
│   ├── common.go                  环境变量、原子写、JSON 弱类型取值
│   ├── config.go                  渲染/合并上游 config.json（保留未知字段）
│   ├── login.go                   OAuth 登录编排 + 账号列表/删除/签到
│   ├── status.go                  查询上游 /healthz、/status、/v1/models
│   ├── keys.go                    多密钥库 + 全局 IP 策略
│   ├── ipfilter.go                CIDR 解析与匹配
│   ├── audit.go                   审计写入 / tail / 聚合统计 / 清理
│   ├── proxy.go                   反向代理：鉴权 → 限流 → 转发 → 审计（/panel/ 静态资源匿名放行）
│   ├── panel.go                   透传上游内嵌面板 /panel/api/*（成长任务扫描 / 队列 / 余额刷新）
│   └── migrate.go                 数据目录迁移
├── workbuddy/                     插件包源（build_ipq64.sh 会渲染成安装包）
│   ├── .valid                     平台标识，内容为 ipq64
│   ├── install.sh / uninstall.sh  安装与卸载
│   ├── version                    插件版本
│   ├── res/icon-workbuddy.png     软件中心图标
│   ├── webs/Module_workbuddy.asp  管理页面
│   ├── bin_64/                    CI 产物落点（wb2api、wb2api-login、wb2api-signin、wb2api-ctl）
│   └── scripts-ipq64/             平台脚本（构建时复制为 scripts/）
│       └── workbuddy_task.sh      成长任务：scan / run / queue
├── .github/workflows/build-ipq64.yml  交叉编译 + 打包 + Release
├── build_ipq64.sh                 打包脚本（对齐 rogsoft 约定）
├── check.sh                       本地自检
├── config.json.js                 软件中心插件元数据（打包时生成）
└── version                        版本号 + 安装包 md5
```

## 编译与打包

推荐复刻后直接用 GitHub Actions：推送或打 tag 后，workflow 会

1. 检出上游 `linguo2625469/workbuddy2api-panel`（默认 `main`，可手动指定 ref）；
2. `GOOS=linux GOARCH=arm64 CGO_ENABLED=0` 静态编译 `cmd/server`、`cmd/login`、`cmd/signin`；
3. 编译 `guard/` 为 `wb2api-ctl`；
4. 把二进制 gzip 成 `.gz`；
5. 执行 `build_ipq64.sh` 产出 `workbuddy.tar.gz`、`version`、`config.json.js`，打 tag 时自动发布 Release。

> 上游换过一版：旧上游 `Sliverkiss/workbuddy2api`（`master`）→ 现用面板分支
> `linguo2625469/workbuddy2api-panel`（`main`）。差异集中在 `internal/panel`（内嵌面板）、
> 成长任务接口，以及配置键改名（`schedule.cat_*` → `schedule.blackcat_*`、
> `school_*` 并入签到排程、新增 `schedule.balance_refresh_*` 与 `pool.degrade_*`）。

本地打包（需 `go` 与 `sh`）：

```sh
# 1. 编译上游（可按需切换 ref）
git clone https://github.com/linguo2625469/workbuddy2api-panel.git /tmp/wb2api && cd /tmp/wb2api
export GOOS=linux GOARCH=arm64 CGO_ENABLED=0
go build -trimpath -ldflags="-s -w" -o <仓库>/workbuddy/bin_64/wb2api        ./cmd/server
go build -trimpath -ldflags="-s -w" -o <仓库>/workbuddy/bin_64/wb2api-login  ./cmd/login
go build -trimpath -ldflags="-s -w" -o <仓库>/workbuddy/bin_64/wb2api-signin ./cmd/signin

# 2. 编译自研控制二进制
cd <仓库>/guard && go build -trimpath -ldflags="-s -w" -o ../workbuddy/bin_64/wb2api-ctl .

# 3. gzip 存放（不要用 UPX，aarch64 静态二进制加壳后会 SIGILL）
cd <仓库>/workbuddy/bin_64 && for f in *; do gzip -9 -c "$f" > "$f.gz" && rm -f "$f"; done

# 4. 打包
cd <仓库> && sh build_ipq64.sh

# 5. 自检
sh check.sh
```

## 体积

jffs 分区通常只有几十 MB，软件中心的安装空间要求是「解压后大小 + 安装包大小」。

### 方案：UPX 4.2.4（默认），gzip 作为回退

aarch64 静态二进制用 UPX 加壳有已知风险（[upx/upx#758](https://github.com/upx/upx/issues/758) 报告 4.2.2 会 SIGILL），所以**版本必须钉死在 4.2.4**，且升级前要在真机复测。

4.2.4 已在目标机型实测通过（TUF_6500 / ARMv8 rev4 / aarch64 / kernel 5.4.277）：

| 测试项 | 结果 |
| --- | --- |
| `version` / `key list` / `status` | 输出与未压缩版一致 |
| 连续执行 30 次（退出路径） | 0 次异常退出 |
| `serve` 长驻 + HTTP + 信号退出 | 正常服务、干净退出 |
| UPX(ctl) + UPX(login) 走真实 TLS | 成功取到 OAuth 授权链接 |

| 二进制 | 原始 | UPX 后 | gzip 后 |
| --- | --- | --- | --- |
| wb2api（上游网关） | 6.81 MB | 1.89 MB | 2.76 MB |
| wb2api-login | 4.69 MB | 1.40 MB | 2.01 MB |
| wb2api-signin | 4.81 MB | 1.46 MB | 2.09 MB |
| wb2api-ctl | 5.38 MB | 1.59 MB | 2.29 MB |
| **合计** | **21.7 MB** | **6.3 MB** | **9.2 MB** |

> 上表为旧上游实测值。panel 版上游把面板前端（`index.html` + `app.js`）用 `go:embed` 打进
> `wb2api`，且新增了成长任务 / 开学季逻辑，`wb2api` 会略大于表中数值（其余三个不变）。
> 具体以 CI 产物为准；两档打包策略与安装空间要求不变。

安装需求（jffs 常驻 + 安装包）：

| 打包方式 | jffs 常驻 | 安装需求 | 运行时额外内存 |
| --- | --- | --- | --- |
| **UPX（默认）** | 6.3 MB | **12.7 MB** | 0 |
| gzip | 8.7 MB | 17.4 MB | ≈ 22 MB（解压到 /tmp） |

**脚本同时兼容两种包型**：`wb_prep` 先找 `bin/<name>.gz`（gzip 包）解压到 `/tmp/wb-bin`，找不到就直接用 `bin/<name>`（UPX 包）。要出 gzip 包，在 Actions 手动触发时把 `pack` 填 `gzip`。

其余节流措施：

- 只打包 4 个二进制，未使用的 `cmd/credit`（积分日报）、`cmd/trial`（global 加油包）不打包；
- 审计日志默认 3 天、单文件 2 MB（jffs 最多约 6 MB）；
- 服务日志固定写 `/tmp`（内存盘），不占 jffs。


## 安装

- **方式一**：软件中心 → 离线安装 → 选择 `workbuddy.tar.gz`。
- **方式二**：上传到路由器 `/tmp` 后手动安装：

```sh
cd /tmp && tar -zxf workbuddy.tar.gz && chmod +x workbuddy/install.sh && sh workbuddy/install.sh
```

安装脚本会校验平台：必须是存在 `/koolshare`、内核 ≥ 4.1 且 `uname -m` 为 `aarch64/arm64/armv8l` 的机器。

## 卸载

软件中心有一条硬性规则（`ks_app_remove.sh`）：

```sh
ENABLED=$(dbus get <module>_enable)
if [ "${ENABLED}" == "1" ]; then
	echo "插件已经开启！你必须先将其关闭后才能进行卸载操作！"
	quit_ks_uninstall          # 直接退出，连插件的卸载脚本都不会被调用
fi
```

所以**插件处于开启状态时，软件中心根本不会调用本插件的 `uninstall.sh`**。

正确步骤：

1. 插件页面右上角的开关**拨到关闭**——拨动即生效（会立即写 dbus 并停止服务），不需要再点「保存并应用」
2. 回软件中心执行卸载

卸载行为：停服务、清 iptables 规则与 watchdog、删除全部文件（`/koolshare/bin/wb2api*`、`/koolshare/scripts/workbuddy_*`、`/tmp/wb-bin`、页面与图标），并清理 `workbuddy_*` 与 `softcenter_module_workbuddy_*` 的 dbus 键。

**数据目录默认保留**（凭证 / 密钥 / 审计日志）。要一并删除：

```sh
sh /koolshare/scripts/uninstall_workbuddy.sh --purge   # 需在卸载前执行
# 或卸载后手动
rm -rf /koolshare/etc/workbuddy
```

## 使用

1. 软件中心打开「WorkBuddy 网关」，打开右上角开关，点「启动」。
2. 「账号池」→「添加账号」→ 获取授权链接 → 浏览器登录 →「我已完成登录」。
3. 「密钥管理」→「新建密钥」，拿到明文（`sk-...`）后妥善保存，关闭后不可再查看。
4. 下游客户端配置：

```bash
OPENAI_BASE_URL=http://<路由器IP>:17863/v1
OPENAI_API_KEY=sk-xxxxxxxx   # 插件分发的密钥，不是上游 api_key
```

5. 「统计与日志」查看调用量、成功率、首字延迟、消耗积分与逐条审计。
6. 「成长任务」→「扫描待办」看各账号还没做完的成长/开学季任务 → 选并发 →「一键完成待办」，
   页面会显示队列进度（账号内串行、账号间并行）。任务是幂等的，重复点不会重复扣资源。
7. 需要更细的面板操作（模型档位、在线改配置、分频道日志）时，在「状态总览 → 上游内嵌面板」
   打开 `http://<路由器IP>:17863/panel/`，登录时填任一把 `sk-…` 分发密钥。

### 数据存放

默认 `/koolshare/etc/workbuddy`（jffs，重启保留）。上游的 `state.json` 落盘较频繁，插了 U 盘建议在「设置 → 数据存放」把目录改到 `/tmp/mnt/<盘符>/workbuddy` 并点「迁移到该目录」，减少闪存写入。

服务运行日志固定写 `/tmp/workbuddy.log`（内存盘，超过 512KB 自动截断），不占用闪存。

### 存放内容

```
<数据目录>/
├── config.json     上游网关配置（由插件渲染，0600）
├── keys.json       多密钥库（仅 SHA-256，0600）
├── guard.json      全局 IP 策略
├── auths/          账号凭证 workbuddy-<uid>.json（0600）
├── data/state.json 上游账号池状态
├── data/model.json 模型上下文/输出上限缓存（上游按需拉取后原子写回）
└── audit/          审计日志 audit-YYYYMMDD.jsonl
```

卸载默认保留数据目录；需要彻底清理请 `sh /koolshare/scripts/uninstall_workbuddy.sh --purge`（脚本卸载后已删除，可在卸载前执行）。

## 二进制说明

| 文件 | 来源 | 作用 |
| --- | --- | --- |
| `wb2api` | 上游 `cmd/server` | 账号池 + OpenAI 协议转换 + 内嵌 `/panel/` 面板，只监听 127.0.0.1 |
| `wb2api-login` | 上游 `cmd/login` | OAuth 设备授权的 `url` / `poll` 子命令 |
| `wb2api-signin` | 上游 `cmd/signin` | 批量手动签到（UPX 后仅 1.46 MB，故保留） |
| `wb2api-ctl` | 本仓库 `guard/` | 代理鉴权网关 + 配置渲染 + 登录编排 + 密钥 + 审计 |

> 上游还有 `cmd/credit`（积分日报），插件页面未使用，为省空间不打包。

## 合规与免责

- 本插件是**非官方**网关，使用 CodeBuddy 账号作为上游，**仅限本人授权账号、本机 / 私有环境使用**；请勿共享、转售或用于违反上游平台服务条款的用途。
- 凭证以明文保存在 `auths/`（权限 0600），请妥善保管，不要把端口与密钥暴露到公网。
- 项目仅供个人学习研究使用，作者不对账号风险、使用结果承担任何责任。
