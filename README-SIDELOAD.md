# Windows 电脑给 iPhone 装原生 App（0 元，无 Mac）

原理：GitHub 云端 Mac 编译出未签名 ipa（免费）→ Windows 上的 Sideloadly 用你自己的
Apple ID 签名 → 数据线装进 iPhone。全程 0 元。

限制（苹果规则，无法绕过）：
- 免费 Apple ID 签的 App **7 天过期**，过期连电脑重签一次
- 一个免费 Apple ID 同时最多 3 个自签 App
- iOS 16+ 首次安装需打开"开发者模式"

## 第一步：云端编译出 ipa（一次性配置）

1. 注册/登录 GitHub（免费）
2. 新建仓库，把 `broadcast/ios-app/` 里的内容全部上传为仓库根
   （本地有 git 就用命令；没有就网页上传，注意保留 `.github/workflows` 子目录）
3. 仓库 → Actions → 如果提示启用，点启用 → 选「iOS Build (unsigned ipa, free)」→ Run workflow
4. 等 10-20 分钟 → 运行成功页底部 **Artifacts** → 下载 `Broadcast-unsigned-ipa`
5. 解压得到 `Broadcast-unsigned.ipa`

## 第二步：Windows 安装 Sideloadly 并装到手机

1. 下载安装 Sideloadly：https://sideloadly.io（Windows 版）
2. 下载安装 iTunes（苹果官网版本，微软商店版缺驱动）：https://www.apple.com.cn/itunes/
   （装一个即可，目的是 USB 驱动）
3. iPhone 用数据线连电脑，手机上点"信任此电脑"
4. 打开 Sideloadly：
   - 拖入 `Broadcast-unsigned.ipa`
   - Apple ID 填你自己的（普通免费 Apple ID 即可）
   - 点 Start，输入 Apple ID 密码（6 位验证码如果开了两步验证）
5. 手机上：设置 → 隐私与安全性 → 开发者模式 → 打开（重启一次手机，iOS 16+ 首次需要）
6. 桌面出现「喊话中心」图标 → 打开即可用（免费签名的 App 一般不需要再点信任；
   如果提示不受信任：设置 → 通用 → VPN与设备管理 → 信任你的 Apple ID 证书）

## 第三步：7 天续签（二选一）

- 手动：App 打不开了 → 重新插数据线跑一次 Sideloadly（App 数据不丢）
- 自动（推荐）：改用 AltStore——Windows 装 AltServer（https://altstore.io）常驻后台，
  手机装 AltStore，同一 WiFi 下手机充电锁屏时**自动续签**，基本无感

## 什么时候值得升级到付费方案

- 嫌 7 天续签麻烦 / 要装到很多人手机上 → 苹果开发者账号 ¥688/年，
  走本目录 `README-NO-MAC.md` 的 TestFlight 方案（扫码下载，90 天，不掉签，无需电脑）
- 系统默认连接你的外网地址，App 内设置页可随时改成局域网或云服务器地址
