# 具体开发方案：AudioShelf 可双击应用迁移

## 开发方案

| 步骤 | 工作内容 | 负责人 | 文件或区域 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 1 | Codable 模型与 LibraryStore | Codex（用户直接要求开发） | Models、`LibraryStore.swift` | Swift release 构建 | 已完成 |
| 2 | 导入、播放和 UI 迁移 | Codex | Services、Views、App | SwiftData 引用检查 | 已完成 |
| 3 | Info.plist 与打包脚本 | Codex | Resources、scripts | build/plutil/codesign | 已完成 |
| 4 | 启动与审核 | Codex | dist、README、审核报告 | open/process check | 已完成 |

## 完成度

| 项目 | 完成度 | 证据 | 备注 |
| --- | ---: | --- | --- |
| 规划 | 100% | `00`～`04` | 已完成 |
| 数据迁移 | 100% | Codable Models、LibraryStore、StoreChecks | 已完成 |
| 应用打包 | 100% | `dist/AudioShelf.app`、build_app.sh | 已完成 |
| 启动验收 | 100% | codesign、Mach-O、启动验证 | 已完成 |

## 要修复的问题

| 问题 | 严重级别 | 关联用户故事 | 修复方案 | 状态 |
| --- | --- | --- | --- | --- |
| 缺少 SwiftDataMacros | P1 | US-101、US-302 | 以 Codable JSON 替代 SwiftData | 已修复 |
| 没有 `.app` 产物 | P1 | US-301、US-303 | 新增 build_app.sh 手工组装 | 已修复 |
| SDK/编译器默认组合不匹配 | P2 | US-302 | CLT 下优先 MacOSX15 SDK | 已修复 |

## 具体案例

| 案例 | 输入或上下文 | 期望行为 | 验证方式 |
| --- | --- | --- | --- |
| 首次启动 | 无 JSON | 空资料库正常显示 | 启动检查 |
| 重启恢复 | 已导入书籍和进度 | 重新打开后恢复 | 人工音频验收 |
| 文件移动 | 书签失效 | 提示并允许重新定位 | 现有路径审核 |
| 命令行打包 | 仅 Command Line Tools | 生成签名 `.app` | build_app.sh |

## 预期改动文件

- `AudioShelf/App/AudioShelfApp.swift`
- `AudioShelf/Models/*.swift`
- `AudioShelf/Services/LibraryStore.swift`、Importer、Player
- `AudioShelf/Views/LibraryView.swift`、`BookDetailView.swift`
- `Package.swift`、`AudioShelf.xcodeproj/project.pbxproj`
- `Resources/Info.plist`、`scripts/build_app.sh`、README

## 验证命令

- `./scripts/run_checks.sh`
- `./scripts/build_app.sh`
- `plutil -lint dist/AudioShelf.app/Contents/Info.plist`
- `codesign --verify --deep --strict dist/AudioShelf.app`
- `open dist/AudioShelf.app`

## 回滚与兼容策略

- 保留原模型字段名称，降低行为迁移风险。
- JSON schema 记录版本号，后续升级可显式迁移。
- 打包脚本仅替换明确的 `dist/AudioShelf.app`，不修改用户 MP3。
- Xcode 工程继续包含全部源码；不保留 SwiftData 双实现。

## Gemini 开发交接

见 `04-gemini-handoff.md`。用户直接要求当前 Codex 修改，因此由 Codex 按交接范围实现。

## Codex 5.5 审核清单

- 原有功能是否仍通过相同入口访问。
- JSON 是否原子写入且不会编码循环引用。
- 打包产物是否包含正确 plist、可执行文件和 entitlements。
- 当前 Mac 是否实际启动应用。
