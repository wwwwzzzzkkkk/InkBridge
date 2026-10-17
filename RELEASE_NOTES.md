# 笔迹桥 1.6.10 开发快照

GitHub 上传日期：2026-10-18。产品版本保持 1.6.10，应用协议 v2，中继版本 12。

## 包含内容

- macOS 原生 PDF 阅读与批注、无限白板、液态玻璃工具栏和搜索。
- HarmonyOS 平板应用，含 ArkTS/ArkUI 外壳、原生触控笔输入和 C++ 录屏编码。
- PDF/白板实时笔迹、视口与撤销/重做同步，Wi-Fi/USB 自动切换。
- 平板到 Mac 的全局有线投屏：2400×1600、3:2、60 fps、30 Mbps H.264；支持任一端发起。
- Mac 发送 PDF 后优先使用华为笔记打开，批注导出后回传并在 Mac 选择保存位置。
- 原生 LiveView 胶囊控制器与投屏动作；当前应用仍需要开通华为 LiveView 调测/正式权益。

## 下载附件

- `InkBridge-macOS-1.6.10.zip`：Apple Silicon macOS 应用，使用本地 ad-hoc 签名，未经过 Apple 公证。运行中继需要安装 Node.js 22.13+。
- `InkBridge-HarmonyOS-1.6.10-debug-signed.hap`：DevEco 调试签名平板安装包，面向已授权的调试设备；不是可供任意设备安装的 AppGallery 正式发行包。
- `SHA256SUMS.txt`：上述附件的 SHA-256 校验值。

证书、私钥、密码和独立签名 Profile 不进入源码仓库。HAP 作为编译后的调试应用附件提供。

## 本次验证

- 上传副本 `npm ci` 成功，协议回归 35/35 通过。
- Node 脚本及 Bash/Zsh 构建脚本语法检查通过。
- macOS Swift 构建、App 打包及严格代码签名检查通过。
- HarmonyOS `default/entry/debug` 类型检查与 hvigor 构建通过；构建系统复用了最新源码对应的现有签名 HAP。
- 应用源码与原工作区逐文件核对；仅仓库说明、依赖入口及构建脚本做了克隆环境适配。

本次为仓库归档上传，没有重新进行平板安装或触控笔行为验收。既有真机测试及限制见 `HANDOFF.md`。
