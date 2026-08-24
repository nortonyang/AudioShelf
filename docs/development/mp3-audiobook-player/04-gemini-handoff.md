# Gemini 代码开发交接：AudioShelf

> 当前执行环境没有实际调用 Gemini。本交接稿按流程保留；用户已明确要求 Codex 开发，故由 Codex 接手实现并在完成后审核。

事实来源：

- `docs/development/mp3-audiobook-player/00-master-plan.md`
- `docs/development/mp3-audiobook-player/01-stages-and-tasks.md`
- `docs/development/mp3-audiobook-player/02-atomic-stories.md`
- `docs/development/mp3-audiobook-player/03-implementation-plan.md`

实现范围：

- AT-101～AT-204 的完整 MVP。
- AT-301～AT-303 的 15/30 秒跳转、睡眠定时、最近播放、历史和交付验证。

约束：

- 不修改或复制用户音频。
- 不引入第三方依赖。
- 最低 macOS 14，使用 SwiftData。
- 所有 AppKit、SwiftData 和 AVPlayer UI 状态修改限定在 MainActor。
- 不扩大到在线服务、云同步、DRM 或音频格式转换。
- 使用用户选择的只读 security-scoped bookmark，播放期间保持访问范围。

验收标准：

- 文件夹作为书、MP3 作为章节；单文件可导入。
- 标题和文件名采用本地化自然排序。
- 每本书分别保存章节和秒数，重启可恢复。
- 播放/暂停、上一章/下一章、拖动、倍速、15/30 秒跳转和睡眠定时可用。
- artwork 优先，无 artwork 时使用默认封面。
- 资料库可搜索、排序、删除，含最近播放和历史。
- `swift build` 和 `swift test` 通过；README 写明 Xcode 与沙盒运行方式。

预期改动区域：

- `AudioShelf/`、`AudioShelfTests/`
- `Package.swift`、`AudioShelf.xcodeproj/`
- `README.md`

需要运行的验证：

- `swift build`
- `swift test`
- 在完整 Xcode 中构建 App target 并人工执行导入、重启、播放和书签验收。

返回内容：

- 变更文件列表。
- 实现摘要。
- 验证命令和结果。
- 阻塞点或偏离计划的地方。
