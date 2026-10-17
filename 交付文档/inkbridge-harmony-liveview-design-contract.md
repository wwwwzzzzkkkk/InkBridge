# 笔迹桥 HarmonyOS PDF 批注实况窗设计合同

## Outcome

- User problem: PDF 传到平板后当前由 WPS 打开，离开笔迹桥后也没有持续、原生且可操作的投屏入口。
- Desired feeling: PDF 无感进入华为笔记；用户留在笔记里批注时，左上角系统实况窗清楚显示投屏状态，展开后可直接开始或停止投屏。
- Platforms and devices: HarmonyOS 6.1、Huawei MatePad Pro 13.2，横屏为主要状态。
- Affected modes and states: PDF 下载中、已交给华为笔记、未投屏、投屏中、投屏失败、批注文件已回传。

## Reference state

- Document/page/zoom: 任意由 Mac 发起往返的 PDF，华为笔记默认文档视图。
- Window or screen size: 2880×1920 横屏。
- Appearance: 系统浅/深色由 HarmonyOS 和华为笔记接管。
- Tool and connection state: USB 已连接；投屏未启动与已启动两种状态。
- Baseline screenshot: `/private/tmp/inkbridge-liveview-baseline.jpeg`，改动前无笔迹桥实况窗。
- Approved prototype: 用户已明确指定“平板自带笔记 + 鸿蒙自带胶囊 + 展开投屏开关”，不增加应用内自绘悬浮层。

## Layout contract

- Top chrome budget: 完全使用 HarmonyOS 实况窗胶囊的系统尺寸和左上角安全区，不硬编码位置或高度。
- Bottom chrome budget: 不新增底部控件。
- Safe-area behavior: 由 LiveViewKit 和系统状态栏负责；不得覆盖华为笔记的文档或工具栏命中区域。
- Content-under-glass behavior: 使用系统实况窗材质，不自绘透明层，不采样或模糊整份 PDF。
- Minimum supported window: 当前产品支持的平板全屏与系统多任务状态；具体胶囊排版由系统自适应。

## Component contract

- Hierarchy and groups: 收起胶囊显示“笔迹桥 + 投屏状态”；展开区显示当前 PDF、投屏状态、一个动态“开始投屏/停止投屏”按钮和“返回笔迹桥”按钮。
- Typography roles: 全部使用系统实况窗排版；文档名为次级信息，投屏状态为首要状态。
- Color roles: 不强设品牌底色，沿用系统实况窗对比度；状态同时用文字表达，不只依赖颜色。
- Material recipe: HarmonyOS LiveViewKit 原生胶囊/展开区。
- Normal/selected/disabled/loading/error states: 未投屏、投屏中、USB 不可用/启动失败；投屏按钮文案随状态更新。
- Keyboard, pointer, touch, and stylus behavior: 胶囊只响应系统点击；华为笔记内书写、缩放和批注行为保持原样。

## Implementation boundary

- Visual-only changes: 无应用内视觉层；仅提供系统实况窗数据。
- Behavior that must remain unchanged: PDF 往返、回传、USB/Wi-Fi 协议、全局投屏、单端发起、原生笔输入。
- Native APIs/frameworks: `@kit.LiveViewKit`、`WantAgent`、显式 `viewData` Want 和只读 URI 授权。
- Files expected to change: `Index.ets`、`EntryAbility.ets`、`RoundTripBridge.ets`、新增 LiveView 控制器、README/HANDOFF。

## Acceptance evidence

- Mac sizes and appearances: 不改 Mac UI；仅回归 Mac 投屏窗口和 PDF 回传保存。
- HarmonyOS states and safe areas: 已真机检查华为笔记 2880×1920 横屏与系统状态栏；胶囊收起/展开、未投屏/投屏中仍待 LiveView 权益生效后验收。
- PDF backgrounds checked: 已在华为笔记中检查深蓝封面、白色正文页和插图区域，PDF 正常导入且批注工具可见。
- Input regression: 华为笔记触控笔批注、单指滚动、双指缩放不被胶囊影响。
- Connectivity regression: USB 投屏启停；非 USB 时显示既有错误反馈；停止后胶囊状态回到未投屏。
- Known deviations: 当前调试 Profile 真机返回 `1003500005`，说明应用尚未获得 LiveView 权益；正式系统胶囊无法由普通通知等价替代。PDF 直达华为笔记已完成，胶囊代码已通过完整参数校验并等待调测设备或正式权益。
