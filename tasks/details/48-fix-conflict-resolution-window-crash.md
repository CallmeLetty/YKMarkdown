# 48-fix-conflict-resolution-window-crash

- Number: 48
- Slug: fix-conflict-resolution-window-crash

## Notes

- 崩溃报告显示主线程在 `DocumentWindowConfigurator.configure(window:coordinator:)` 写入 `weak var window` 时触发 `weak_register_no_lock` / ObjC abort，发生在 AppKit 窗口 detach/dealloc 期间。
- 将文档窗口配置器的窗口缓存改为 `ObjectIdentifier`，只在窗口身份或打开模式变化时更新 AppKit tabbing 设置，避免对正在销毁的 `NSWindow` 注册 weak 引用。
- 同步调整搜索窗口读取器：观察窗口和上报窗口都用身份值去重，关闭通知移除时不依赖保存 weak window，降低同类崩溃风险。
- 验证：`git diff --check` 通过；按项目规则未运行 `xcodebuild`、测试或 SwiftLint。
