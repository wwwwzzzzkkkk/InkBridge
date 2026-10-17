# InkBridge macOS 原生 Liquid Glass 设计合同

## Outcome

- User problem: 当前 Mac 顶部是一整块深蓝自定义玻璃悬浮栏，未采用 macOS 26 原生 Liquid Glass；标题、模式和连接状态拥挤在同一胶囊中。
- Desired feeling: 文档优先、安静、专业，像原生 macOS 文档工具；Liquid Glass 负责层级而不是成为视觉主体。
- Platforms and devices: macOS 14 及以上；重点适配 macOS 26/27 的原生 Liquid Glass，同时保持 14/15 可用。
- Affected modes and states: PDF、白板、已连接、未连接、USB/Wi-Fi 切换、PDF 搜索、窗口最小/常用/宽屏、全屏。

## Reference state

- Document/page/zoom: 实时白板 100%；PDF 验证使用正文白纸页和深色图像页。
- Window or screen size: 最小 720×520；基线约 1066×768；另检查宽屏/全屏。
- Appearance: 系统浅色和深色外观；不强制深蓝工具栏。
- Tool and connection state: 白板、已连接、自动传输正在 Wi-Fi/USB 间切换。
- Baseline screenshot: 2026-08-13 运行中的笔迹桥，自定义 46pt 深蓝玻璃悬浮栏。
- Approved prototype: `/Users/zhekuan/.codex/visualizations/2026/08/12/019ff6fe-f6fb-7452-8821-c89abb4d93a9/inkbridge-mac-liquid-glass-directions.html` 中方向 A。
- Latest approved reference: 用户提供的 macOS Preview 统一标题栏截图 `/var/folders/gg/f08_vf1n1q1_672y59x84xg00000gn/T/TemporaryItems/NSIRD_screencaptureui_jxtxAO/截屏2026-08-20 05.03.32.png`；交通灯、标题和工具控件位于同一原生栏，背景为较深灰材质，文字不发光。

## Layout contract

- Top chrome budget: 约 50pt 的单层原生 unified titlebar/toolbar；交通灯、模式、标题、连接、搜索和收起入口共享同一行，不再存在独立的交通灯黑栏与下方 46pt 状态栏。
- Bottom chrome budget: 无新增底部栏。
- Safe-area behavior: PDF/白板继续铺入 full-size content；顶部控件由原生 `NSToolbar` 管理，交通灯、拖动和全屏行为不被 SwiftUI 浮层替代。
- Content-under-glass behavior: 标题栏使用窗口内、保持不透明的系统 header/toolbar 材质，macOS 26 的工具控件使用原生 Liquid Glass；不会透出窗口后方桌面或其他应用。搜索浮层仍使用窗口内 `.glassEffect(.regular)` 并采样当前 PDF/白板；macOS 14/15 回退系统材质。
- Minimum supported window: 720×520；标题先中间截断，连接状态压缩为传输图标，固定操作仍可达。

## Component contract

- Hierarchy and groups: 左侧是 PDF/白板模式选择；中部是单行文档标题和小型房间号；右侧是连接/传输菜单、PDF 搜索和工具栏显示控制。文件、历史、缩放、撤销、导出继续位于系统菜单。
- Typography roles: 模式使用系统紧凑分段选择；标题 12pt semibold、80% 语义主色；房间号 10pt medium monospaced、60% 主色；连接状态 78% 主色。标题、房间号和连接状态均不再使用描边、发光或高光阴影。
- Color roles: 系统强调色表示当前模式；绿色圆点表示已连接，橙色表示等待/切换；不再使用大面积固定深蓝和蓝绿渐变。
- Material recipe: 标准 SwiftUI/AppKit 工具栏为主。macOS 26 由系统提供 Liquid Glass；macOS 14/15 使用系统统一工具栏材质。仅搜索浮层使用单层 `.regularMaterial`、语义前景色和轻分离阴影。
- Normal/selected/disabled/loading/error states: 模式同时用选择位置和文本表示；连接菜单同时显示状态圆点、传输图标和帮助文本；切换中不改变工具栏几何；PDF 搜索在白板或未打开 PDF 时不可用。
- Keyboard, pointer, touch, and stylus behavior: 保留原生窗口拖动、缩放、全屏、工具栏隐藏、键盘焦点、`⌘F`、PDFKit 选择/复制/上下文菜单、触控板滚动/捏合；白板和网络输入路由不变。

## Implementation boundary

- Visual-only changes: 删除自定义悬浮顶部栏与深蓝 LiquidGlass 背景组件；新增系统 `.toolbar` 内容、原生模式选择、标题/房间状态、连接菜单和语义搜索浮层。
- Behavior that must remain unchanged: PDF/白板同步、实时笔迹、历史、搜索逻辑、文档传输、USB/Wi-Fi 偏好与自动切换、配对界面。
- Native APIs/frameworks: SwiftUI `.toolbar`、系统 `Picker`/`Menu`/`Button`、macOS 26 `.glass` 按钮、AppKit unified `NSToolbar`、全尺寸内容窗口，以及搜索浮层 `.glassEffect(.regular)`；PDFKit/AppKit 画布保持不变。
- Files expected to change: `MacPDFAnnotator/Sources/ContentView.swift`、`MacPDFAnnotator/Sources/MacPDFAnnotatorApp.swift`、本设计合同。

## Acceptance evidence

- 2026-08-13 已构建并启动真实桌面 App，在系统深色外观下检查约 1066×768 白板和 720×520 白板/PDF：内容保持主视觉；模式、标题/房间、Wi-Fi 状态、搜索和收起操作无重叠或裁切。
- 工具栏收起/展开已在真实 App 通过：收起后保留标准标题栏与交通灯，并显示左上角“桥”恢复按钮。
- PDF 白纸正文、蓝色批注、页间/页面外区域已检查；PDFKit 文字层仍出现在辅助功能树中，页面滚动区保持原生。
- PDF 搜索浮层在 720×520 下已检查；查询 `research` 得到 9 项，前后导航在 1/9 与 2/9 间正确切换，Escape 可关闭搜索。
- 白板模式下搜索按钮正确禁用，PDF 模式且已有文档时正确启用。实时笔迹像素回归、协议回归 28/28 与 Swift 全量构建通过。
- 连接状态在真实 App 中为 Wi-Fi 已连接；连接菜单保留自动/Wi-Fi/USB 选择，以及 PDF 传输状态、取消和重试操作，顶栏仍使用固定的紧凑状态标签。
- 桌面 App 已重新打包，bundle 中继与白板资源和工作区一致，并通过 ad-hoc 严格签名验证。
- 2026-08-13 液态玻璃采样修正：真实 PDF 正文滚动到顶部状态栏下方后，玻璃内可见被模糊/折射的当前 PDF 文字；切换白板后采样改为白板网格与笔迹。窗口保持不透明，未再出现窗口后方应用文字。720×520、收起与重新展开均通过。
- 2026-08-13 状态文字与搜索动效优化：顶栏在深色外观下增加 10% 黑色、浅色外观下增加 8% 白色的单层自适应可读性色调，保留当前 PDF/白板采样；标题、房间号和连接状态对比度增强。搜索胶囊以顶部中央为锚点，从 `0.68` 缩放和 `-14pt` 位移向下展开，使用 0.34 秒、0.18 bounce 的系统弹簧；系统“减少动态效果”开启时退化为 0.12 秒淡入淡出。
- Apple 官方依据：SwiftUI `Animation.spring(duration:bounce:blendDuration:)`、`AnyTransition.scale(scale:anchor:)`、`View.transition(_:)` 和 `accessibilityReduceMotion`。
- 真实 App 再次检查 PDF 白纸正文与实时白板背景；`⌘F`、查询 `research` 1/9、Escape 关闭正常。Swift 构建、协议回归 28/28、白板实时笔迹像素测试、桌面 App 重打包与严格签名验证通过。
- 2026-08-13 紧凑材质与外部点击优化：状态栏由 52pt 收窄至 46pt；深色自适应色调由 10% 增至 16%，浅色由 8% 增至 14%，并补充 0.5pt 顶部高光、16% 底部边界和更清晰的低位阴影，使玻璃更厚但仍能采样 PDF/白板。搜索打开时使用窗口内本地鼠标事件观察，仅在点击搜索胶囊之外时收起；事件继续传给 PDFKit/白板，不添加全屏透明遮罩。
- 真实 App 已验证：搜索栏内部输入 `research` 保持展开并返回 1/9；点击 PDF 空白处自动收起；Escape 仍可关闭。协议 28/28、白板实时笔迹像素测试、Swift 构建、桌面 App 重打包和启动前严格签名均通过。
- 2026-08-20 统一标题栏：撤销“窗口内状态栏向交通灯上移”的尝试，改用原生 `NSToolbar` 结构。真实 App 中交通灯、PDF/白板选择、中央标题/房间、连接菜单、搜索和收起按钮处于同一栏；深灰背景与参考截图一致，文字无高光阴影。720×520 PDF/白板均无裁切，搜索 `research` 为 1/9，点击 PDF 空白失焦后自动收起，工具栏收起/展开通过。
- 2026-08-23 标题栏命中修复：SwiftUI unified window 会保留/恢复 `fullSizeContentView`，导致 PDF 内容命中层进入原生 toolbar 区域，鼠标无法操作顶部按钮。窗口配置现每次显式执行 `styleMask.remove(.fullSizeContentView)` 并设置 `isMovableByWindowBackground = false`；原生标题栏仍可拖动，模式、搜索、连接和收起按钮优先接收鼠标事件。真实 App 已验证 PDF/白板切换、搜索打开/Escape 关闭、收起/展开。
- 2026-08-23 状态与搜索动效：底部状态胶囊采用 0.38 秒、0.16 bounce 的球形 morph 转场；活动态从横向 20%/纵向 72% 的近圆形材质球展开到完整胶囊，移除时反向缩回。普通恢复/导出提示显示 2.8 秒，错误提示 4.2 秒；“减少动态效果”下改为 0.14 秒淡入淡出。搜索栏保留 0.34 秒轻弹簧，从标题栏中央下方展开，点击 PDF/白板文档区使搜索框失焦并反向收起。
- 2026-08-23 搜索外部点击可靠性：PDFKit 点击不保证文本框失焦，因此搜索关闭不再依赖焦点。搜索胶囊背景安装窗口本地鼠标观察器，延迟 0.25 秒启用，使用实际胶囊边界外扩 6pt 判断外部点击；监听始终返回原始事件，并在 `dismantleNSView` 中注销，不拦截 PDFKit。曾尝试读取 `NSApp.currentEvent.eventNumber` 过滤初始点击，但 macOS 27 会在布局阶段抛出 AppKit 异常，已移除。真实 App 连续 6 轮外部点击关闭均成功，搜索内部点击保持展开并从 1/22 导航到 2/22。
- 待人工补验：宽屏/全屏、非活动窗口、系统浅色外观、USB 实际切换，以及 PDF 深色图像区域；自动化验收期间 Mac 锁屏，未将这些状态误报为已通过。
- Known deviations: 原型中的“12 ms”不显示，因为当前协议没有可靠 RTT 指标；系统工具栏在 macOS 14/15 不是 Liquid Glass，而是相应系统版本的原生材质。系统窗口标题已隐藏，避免与工具栏中央文档标题重复；标题栏、交通灯和窗口行为仍为原生。
