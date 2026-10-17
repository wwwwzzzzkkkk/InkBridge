# InkBridge 统一液态玻璃设计约定

## Outcome

- User problem: 平板与 Mac 工具栏密度、颜色和材质不一致，长文件名会被两侧控件挤压或遮挡。
- Desired feeling: PDF 始终是视觉主体；深海军蓝、蓝色与薄荷绿组成克制、沉浸的跨端玻璃界面。
- Platforms and devices: HarmonyOS 6 横屏平板；macOS 可缩放窗口与全屏。
- Affected modes and states: PDF、白板、已连接、等待连接、顶部栏展开/收起、画笔/橡皮二级菜单、PDF 搜索。

## Reference state

- Document/page/zoom: `Economic impact of biofouling on a naval surface ship.pdf`，100%，正文页。
- Window or screen size: MatePad Pro 13.2 横屏；Mac 最小 720×520、常用笔记本窗口与全屏。
- Appearance: 深海军蓝透明玻璃，主色 `#4F8FF7`，辅色 `#58D3B7`。
- Tool and connection state: PDF、画笔第 3 档、Wi-Fi 已连接。
- Baseline screenshot: 2026-08-09 安装前实机画笔与橡皮菜单：`/tmp/inkbridge-pen-menu-baseline.jpeg`、`/tmp/inkbridge-eraser-menu-baseline.jpeg`。
- Approved prototype: `/Users/zhekuan/.codex/visualizations/2026/08/02/019fc04f-fab8-7a72-93ef-b200ef07dabb/inkbridge-unified-glass.html`

## Layout contract

- Top chrome budget: 平板 46–48vp 加顶部安全区；Mac 46pt，距窗口顶部 10pt。
- Bottom chrome budget: 平板 50vp 加系统导航指示区。
- Safe-area behavior: PDF 延伸到系统栏后方；顶部栏与底部工具栏分别增加运行时 avoid-area，不写死状态栏或小白条高度。
- Content-under-glass behavior: PDF 保持渲染并延伸到玻璃栏下，模糊仅作用于栏和二级菜单。
- Minimum supported window: Mac 720×520；窄宽度下标题先省略，不允许覆盖左右控件。

## Component contract

- Hierarchy and groups: 两端顶部栏仅保留模式、几何居中文件名、房间/连接状态和收起按钮；平板底栏一级操作只显示图标；Mac 文件、历史、搜索、缩放、导出与连接选项进入系统菜单。
- Typography roles: 文件名 12pt/vp semibold 单行；房间号 9pt/vp 等宽；连接状态 10–11pt/vp。
- Color roles: 蓝色表示主选择，薄荷绿表示连接成功，橙色表示等待，红色仅用于清除或错误。
- Material recipe: 单层原生背景模糊、低透明深蓝遮罩、上缘高光和轻阴影；禁止嵌套模糊。
- Normal/selected/disabled/loading/error states: 状态不只依赖颜色，保留图标、文字或固定位置；USB/Wi-Fi 切换不得改变顶部栏几何尺寸。
- Motion: 顶部栏使用 520ms ease-in-out 共享几何动画，从右向左卷收为左上角圆形按钮，再从左向右展开；内容随边界裁剪而不是突然替换。画笔与橡皮二级菜单以底部工具栏为锚点，使用 240ms 上浮/淡入/96%→100% 缩放展开和 180ms 反向收拢，菜单之间切换时连续交叉过渡。系统启用“减少动态效果”时立即切换。
- Mode alignment: Mac 的“PDF 批注 / 实时白板”和平板的“PDF / 白板”均使用固定高度的居中内容框，不依赖按钮默认文字内边距。
- Keyboard, pointer, touch, and stylus behavior: Mac 保留 PDFKit 文本选择、复制、`⌘F`、缩放与菜单；平板保留笔、单指平移、双指缩放、悬停、防误触与重按临时橡皮逻辑。

## Implementation boundary

- Visual-only changes: 顶部栏结构、工具图标、玻璃参数、顶部栏收起/展开、平板二级菜单动效和 Mac 菜单位置。
- Behavior that must remain unchanged: PDF/白板同步、笔迹协议、文档坐标、压力采样、USB/Wi-Fi 传输与自动切换。
- Native APIs/frameworks: ArkUI `backgroundEffect`、avoid area、`animateTo`、`TransitionEffect`；SwiftUI Material、Commands；PDFKit。
- Files expected to change: `HarmonyPad/entry/src/main/ets/pages/Index.ets`、`MacPDFAnnotator/Sources/ContentView.swift`、`MacPDFAnnotator/Sources/MacPDFAnnotatorApp.swift`、`MacPDFAnnotator/Sources/PDFWorkspace.swift`。

## Acceptance evidence

- Mac sizes and appearances: 最小、常用、宽屏/全屏；浅色和深色外观。
- HarmonyOS states and safe areas: MatePad Pro 13.2 横屏真机已检查顶部状态栏、底部小白条、PDF/白板模式，以及画笔/橡皮菜单的展开、菜单互切与收起中间帧。
- PDF backgrounds checked: 白纸正文、深色图片、彩色笔迹与页间空隙。
- Input regression: 一级画笔/橡皮按钮命中、二级菜单互切与重复开关通过；本次仅改变菜单容器过渡，未修改笔、手指、悬停或压感路径。
- Connectivity regression: Wi-Fi 会话保持已连接，USB 调试设备同时在线；菜单动效未改变工具栏布局或连接状态。
- Known deviations: Mac 系统菜单使用平台原生外观，不与平板像素级一致；PDF/白板网页重载瞬间仍会记录既有 `nativeGetState` 控制台竞态提示，但页面和连接会正常恢复。
