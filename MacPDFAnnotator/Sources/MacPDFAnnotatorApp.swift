import AppKit
import SwiftUI

@MainActor
final class InkBridgeAppDelegate: NSObject, NSApplicationDelegate {
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }

  func applicationWillTerminate(_ notification: Notification) {
    LocalRelayLauncher.shared.stop()
  }
}

@main
struct MacPDFAnnotatorApp: App {
  @NSApplicationDelegateAdaptor(InkBridgeAppDelegate.self) private var appDelegate
  @StateObject private var workspace = PDFWorkspace()

  init() {
    LocalRelayLauncher.shared.startIfNeeded()
  }

  var body: some Scene {
    Window("笔迹桥", id: "main") {
      ContentView()
        .environmentObject(workspace)
        .frame(minWidth: 720, minHeight: 520)
        .onAppear { workspace.start() }
    }
    .windowToolbarStyle(.unified(showsTitle: false))
    .commands {
      CommandGroup(replacing: .newItem) {
        Button("打开 PDF…", action: workspace.openPDF)
          .keyboardShortcut("o", modifiers: .command)
        Menu("最近使用") {
          if workspace.recentPDFs.isEmpty {
            Button("暂无历史记录") {}
              .disabled(true)
          } else {
            ForEach(workspace.recentPDFs) { recent in
              Button(recent.name) { workspace.openRecent(recent) }
            }
          }
        }
        Divider()
        Button("发送 PDF 到平板批注…", action: workspace.startPDFRoundTrip)
      }

      CommandGroup(replacing: .saveItem) {
        Button("另存为 PDF…", action: workspace.saveAs)
          .keyboardShortcut("s", modifiers: [.command, .shift])
          .disabled(!workspace.hasDocument)
      }

      CommandGroup(replacing: .undoRedo) {
        Button("撤销", action: workspace.undo)
          .keyboardShortcut("z", modifiers: .command)
          .disabled(!workspace.canUndo)
        Button("重做", action: workspace.redo)
          .keyboardShortcut("z", modifiers: [.command, .shift])
          .disabled(!workspace.canRedo)
      }

      CommandGroup(after: .pasteboard) {
        Divider()
        Button("搜索 PDF…", action: workspace.presentSearch)
          .keyboardShortcut("f", modifiers: .command)
          .disabled(workspace.mode != .pdf || !workspace.hasDocument)
      }

      CommandGroup(after: .toolbar) {
        Divider()
        Button("放大", action: workspace.zoomIn)
          .keyboardShortcut("+", modifiers: .command)
          .disabled(workspace.mode == .pdf && !workspace.hasDocument)
        Button("缩小", action: workspace.zoomOut)
          .keyboardShortcut("-", modifiers: .command)
          .disabled(workspace.mode == .pdf && !workspace.hasDocument)
        Button(workspace.mode == .whiteboard ? "回到白板原点" : "适合窗口", action: workspace.zoomToFit)
          .keyboardShortcut("0", modifiers: .command)
          .disabled(workspace.mode == .pdf && !workspace.hasDocument)
        Divider()
        Button(workspace.isToolbarCollapsed ? "展开顶部栏" : "收起顶部栏") {
          workspace.isToolbarCollapsed.toggle()
        }
      }

      CommandMenu("连接") {
        Button("连接平板…") { workspace.isShowingPairing = true }
        Divider()
        ForEach(ConnectionPreference.allCases) { preference in
          Button {
            workspace.usbRelay.preference = preference
          } label: {
            if workspace.usbRelay.preference == preference {
              Label(preference.title, systemImage: "checkmark")
            } else {
              Text(preference.title)
            }
          }
        }
        Divider()
        Button(workspace.tabletMirror.isReceiving ? "停止平板投屏" : "开始平板投屏") {
          workspace.toggleTabletMirror()
        }
        .disabled(!workspace.usbRelay.isReady && !workspace.tabletMirror.isReceiving)
      }
    }
  }
}
