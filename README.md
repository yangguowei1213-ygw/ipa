# BackgroundCleaner

一个 SwiftUI iOS 16 示例应用，提供设备状态与清理操作界面。

## 重要限制
TrollStore 主要改变安装/签名验证路径，并不会自动授予 `platform-application`、`com.apple.private.security.no-sandbox` 等 Apple 私有 entitlement，也不会让普通第三方 App 获得 root。iOS 的进程隔离、AMFI、权限检查和系统服务接口仍然有效。因此本项目**不伪造或请求私有 entitlement**，也不提供跨进程 SIGKILL 代码；那样既不能保证在 iPhone XR/iOS 16.3 工作，也可能破坏系统或造成数据丢失。

应用按钮执行的是安全、诚实的本地状态操作。若要实现真正的系统级能力，需要受支持的系统组件/越狱环境与设备特定研究，不能通过 GitHub Actions 的 `--no-codesign` 获得。

## Windows 初始化
```powershell
mkdir BackgroundCleaner; cd BackgroundCleaner
git init
git remote add origin https://github.com/YOUR_NAME/YOUR_REPO.git
# 将本仓库文件复制进来
git add .; git commit -m "Initial iOS app"; git branch -M main; git push -u origin main
```

## GitHub Actions
工作流在 macOS runner 上安装 XcodeGen，生成 Xcode 项目，执行 unsigned archive，并上传 IPA artifact。下载 artifact 后可尝试导入 TrollStore；未签名构建不等于获得 root 或私有权限。

## 本地预览
Windows 无法运行 Xcode/iOS Simulator。可以使用 SwiftUI Preview（需要 macOS）或将界面逻辑移植到 Web 做视觉预览；Chrome 不能直接编译 SwiftUI。推荐通过 GitHub Actions 构建后安装到测试设备验证。
