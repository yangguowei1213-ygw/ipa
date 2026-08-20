# iOS 26 键盘（TrollStore unsigned IPA）

这是一个面向 iPhone XR / iOS 16.3 的轻量 UIKit 自定义输入法示例。它包含宿主设置 App、Keyboard Extension、App Group 词库和 GitHub Actions 无签名打包。

> **重要边界**：TrollStore 改变安装验证路径，但不会给普通 App 授予 root、platform-application 或 Apple 私有 entitlement。本项目不遍历/终止其他进程，也不伪造权限；iOS 密码框自动回退系统键盘，这是不可绕过的安全机制。`--no-codesign` 只是关闭签名，不是越狱权限。

## 1. Windows 11 初始化

PowerShell：

```powershell
mkdir IOS26Keyboard
cd IOS26Keyboard
git init
git remote add origin https://github.com/YOUR_NAME/YOUR_REPO.git
# 将本仓库全部文件复制到当前目录
 git add .
git commit -m "Initial iOS 26 keyboard"
git branch -M main
git push -u origin main
```

项目由 `project.yml` 生成，不需要提交 `.xcodeproj`。Action 会在 macOS runner 安装 XcodeGen。

## 2. 功能与限制

- `KeyboardExtension/KeyboardViewController.swift`：系统毛玻璃背景、Light/Dark 自适应键帽、字母/删除/换行/切换键盘、Shift、按键气泡、点击音和轻触觉。
- 使用 `textDocumentProxy` 插入文本和删除字符；不读取或上传用户输入内容。
- `SharedWordStore.swift` 使用 `group.com.app.keyboard` 的 `UserDefaults`，限制词库读取数量以降低键盘扩展内存占用。
- 宿主 App `SettingsView` 可保存每行一个自定义词语。
- 完全访问权限在 Extension Info.plist 中声明为 `RequestsOpenAccess=YES`。用户必须在系统设置中手动启用；未授权时不要假设网络、剪贴板或共享数据可用。
- iOS 会在安全输入框中自动禁用第三方键盘；这是预期行为。

## 3. GitHub Actions 打包

`.github/workflows/build_ipa.yml` 在 `macos-latest` 上执行：

1. checkout；2. 安装 XcodeGen；3. `xcodegen generate`；4. `xcodebuild build` + `CODE_SIGNING_ALLOWED=NO`；5. 组装 `Payload/iOS26Keyboard.app` 并上传 `iOS-Keyboard-IPA-unsigned` artifact。

推送到 `main` 或在 Actions 页面选择 **Run workflow** 即可触发。下载 artifact 后解压 IPA，并通过 TrollStore 导入。未签名包在部分 iOS/TrollStore 版本上可能需要设备端重新处理；这不是项目代码能够保证的安装行为。

## 4. Windows 预览与测试

Windows 不能运行 Xcode 或 iOS Simulator，Chrome 也不能直接渲染 Swift/UIKit。可选方案：

- 用浏览器做静态视觉预览：将键盘布局按 QWERTY 三行和底栏做 HTML/CSS mock；这只能验证间距/颜色，不能验证 `textDocumentProxy`、安全区域和系统键盘生命周期。
- 用 GitHub Actions 构建后，在真实 iPhone 上安装测试；这是验证输入法最可靠的方法。
- 安装后打开“设置 → 通用 → 键盘 → 键盘 → 添加新键盘”，选择本 App；进入“完全访问”按需求开启，然后在任意普通文本框长按地球键切换。

## 5. 本地检查

Windows 可执行：

```powershell
rg "SIGKILL|task_for_pid|private entitlement" .
# 确认没有误加入私有进程控制代码
 git diff --check
```

真正的 Xcode 编译只能在 macOS runner 或实体 Mac 上完成。请不要在密码框、支付字段中测试第三方键盘的可用性；系统回退属于正常安全策略。
