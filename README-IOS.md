# iOS 原生 App 装机指南

## 先弄懂苹果的规则（重要）

iPhone 不像安卓能直接装安装包。任何原生 App 装上 iPhone 只有三种途径：

| 途径 | 费用 | 有效期 | 需要的条件 |
|------|------|--------|-----------|
| **Xcode + 免费 Apple ID（自己装机）** | 0 元 | **7 天**，过期重新 Run 一次 | 一台 Mac |
| TestFlight / Ad Hoc | ¥688/年（苹果开发者账号） | 90 天 / 1 年 | 一台 Mac + 账号 |
| App Store 上架 | ¥688/年 + 审核 | 永久 | Mac + 审核 |

App 源码已全部写好（本目录 4 个 Swift 文件），**必须有 Mac 才能编译装机**，没有 Mac 见文末替代方案。

## 有 Mac：从零到装上手机（约 15 分钟）

1. **装 Xcode**：Mac 上 App Store 搜索 Xcode 安装（约 10GB）
2. **建工程**：Xcode → File → New → Project → iOS → App
   - Product Name：`Broadcast`，Interface 选 **SwiftUI**，Language 选 **Swift**
3. **换源码**：删除 Xcode 自动生成的 `ContentView.swift`，把本目录的 4 个文件拖进工程（勾选 Copy items if needed）
4. **允许 HTTP**（如果你以后要填 `http://192.168.x.x` 局域网地址）：
   选中工程 Target → Info → 添加 `App Transport Security Settings` → 里面加 `Allow Arbitrary Loads = YES`
   （默认的外网地址是 https，不加也能跑；填局域网 http 地址时必须加）
5. **登录 Apple ID**：Xcode → Settings → Accounts → 左下角 + 号登录你的 Apple ID（免费）
6. **连 iPhone**：数据线连接，手机上点"信任"；Xcode 顶部设备选择器选你的手机
7. **签名**：Target → Signing & Capabilities → Team 选你的 Apple ID，勾 Automatically manage signing
   - 手机上：设置 → 通用 → VPN与设备管理 → 信任你的开发者证书（首次需要）
8. **运行**：点 ▶ Run，App 装进手机

> App 内默认已填好你的外网地址 `https://78723823a408a3.lhr.life`（设置页可随时改）。
> 7 天过期后：连 Mac 重新 Run 一次即可。

## 没有 Mac 的替代方案

| 方案 | 说明 |
|------|------|
| **PWA（已在运行，推荐先用）** | Safari 打开 https://78723823a408a3.lhr.life → 添加到主屏幕。界面和功能与本 App 一致 |
| 借/找一台 Mac | 按上面步骤一次编译即可 |
| 云 Mac 按小时租 | 搜索"云真机/Mac 云编译"服务，远程编译出 ipa 再侧载，操作门槛高 |
| 找有开发者账号的团队代签 | 付费服务，注意选择靠谱的 |

## App 功能清单

- 设备列表（在线绿点/离线灰点），下拉刷新，自动记住上次选择
- 我的称呼记忆、快捷短语一键填入、500 字内编辑
- 一键发送 + 震动反馈 + Toast 提示
- 发送记录（待送达/已送达/已播报状态实时显示）
- 设置页：服务器地址可改 + 连接测试（切局域网/外网无需重新装 App）
