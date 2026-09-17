# 无 Mac 装原生 App 到 iPhone —— 云端编译方案

原理：GitHub Actions 提供免费的 **macOS 云构建机**，编译在本目录的 iOS 工程；产物自动上传 **TestFlight**，手机扫码下载安装。**全程不需要 Mac，不掉签，苹果官方渠道。**

费用：苹果开发者账号 **¥688/年**（这是无法绕过的，任何"免 Mac 装 App"的路都要么花钱要么掉签）。

## 你要做的 5 步

### 第 1 步：注册苹果开发者账号（不需要 Mac）

手机或电脑浏览器打开 `developer.apple.com/programs/zh-cn/` → 注册 → 用 Apple ID 登录 → 支付 ¥688。
需要实名信息 + 银联/支付宝，通常 24-48 小时内开通。

### 第 2 步：把本目录推到 GitHub

1. 注册/登录 GitHub，新建一个仓库（Public 免费；Private 也有免费额度够用）
2. 把 `broadcast/ios-app/` 整个目录的内容作为仓库根上传（保持目录结构，含 `.github` 文件夹）

### 第 3 步：生成 App Store Connect API 密钥（网页操作，5 分钟）

1. 打开 `appstoreconnect.apple.com` → 用户和访问 → 集成 → App Store Connect API
2. 生成密钥，角色选 **Admin**，下载 `.p8` 文件，记下页面上的 **Key ID** 和 **Issuer ID**
3. 回到 App Store Connect 首页 → 成员资格 → 记下 **Team ID**（10 位）
4. 编辑仓库里的 `ios-app/exportOptions.plist`，把 `REPLACE_WITH_YOUR_TEAM_ID` 换成你的 Team ID

### 第 4 步：配置 GitHub Secrets

仓库 → Settings → Secrets and variables → Actions → New repository secret，添加 3 个：

| Name | Value |
|------|-------|
| `ASC_KEY_ID` | 第 3 步的 Key ID |
| `ASC_ISSUER_ID` | 第 3 步的 Issuer ID |
| `ASC_KEY_P8` | 用记事本打开 .p8 文件，全文粘贴（含 BEGIN/END 行） |

### 第 5 步：构建 + 装机

1. 仓库 → Actions → 「iOS Build & TestFlight」→ Run workflow（推送代码也会自动触发）
2. 等 10-20 分钟构建完成，构建产物自动进 TestFlight
3. 首次构建后：App Store Connect → 我的 App → 创建 App（名字"喊话中心"，Bundle ID `com.kf.Broadcast`，填一次即可）
4. iPhone 上 App Store 搜 **TestFlight** 安装（苹果官方免费 App）
5. App Store Connect → 我的 App → TestFlight → 添加自己为内部测试员 → 会收到邮件/链接 → 打开即装
6. 以后更新代码推送后自动重新构建；构建 90 天过期时重跑一次 Actions 即可

## 目录结构（本目录 = GitHub 仓库根）

```
ios-app/
├── .github/workflows/ios-build.yml   # 云端编译流水线
├── Sources/                          # App 源码（SwiftUI）
│   ├── BroadcastApp.swift
│   ├── ApiService.swift              # 网络层（默认连你的外网地址）
│   ├── HomeView.swift                # 主界面
│   └── SettingsView.swift            # 设置页（可改服务器地址）
├── project.yml                       # XcodeGen 工程定义
└── exportOptions.plist               # 导出配置（要填你的 Team ID）
```

## 常见问题

- **构建失败 signing 报错**：确认 Team ID 已填、API 密钥角色是 Admin、账号已同意最新协议（登录 developer.apple.com 会提示）
- **TestFlight 找不到构建**：处理完 Apple 的合规问卷（首次上传后 App Store Connect 里有一份加密合规问卷，选"标准加密豁免"即可，工程里已预置声明）
- **想改服务器地址**：App 内设置页可改，不用重新构建
- **证书/账号到期**：688/年 到期续费，App 继续用
