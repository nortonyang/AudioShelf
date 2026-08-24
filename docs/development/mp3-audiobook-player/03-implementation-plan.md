# 具体开发方案：AudioShelf 原生 macOS 有声书播放器

## 开发方案

| 步骤 | 工作内容 | 负责人 | 文件或区域 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 1 | 工程、应用入口、权限配置 | Codex（用户已直接要求开发） | `Package.swift`、`AudioShelf.xcodeproj`、App、entitlements | 工程/Plist 语法检查 | 已完成 |
| 2 | SwiftData 模型与自然排序 | Codex | Models、Core | CoreChecks + 源码审核 | 已完成实现 |
| 3 | 书签、metadata、文件导入 | Codex | Services | 非宏编译 + 源码审核 | 已完成实现 |
| 4 | AVPlayer 控制和进度持久化 | Codex | `PlayerController` | 非宏编译 + 源码审核 | 已完成实现 |
| 5 | 资料库、详情、章节、播放器 UI | Codex | Views | 非宏编译 + 工程审核 | 已完成实现 |
| 6 | 可选增强、说明与完工审核 | Codex | Player、Views、README、审核报告 | CoreChecks + 审核报告 | 已完成可执行范围 |
| 7 | 源文件移动后的章节重新定位 | Codex | `LibraryImporter`、`BookDetailView`、README | 源码解析 + 人工重新授权验收 | 已实现，待沙盒运行验收 |

## 完成度

| 项目 | 完成度 | 证据 | 备注 |
| --- | ---: | --- | --- |
| 规划门禁 | 100% | 00～04 文档 | 已完成 |
| MVP 代码 | 95% | `AudioShelf/`、`AudioShelfCore/`；非宏编译未发现独立错误 | 完整 Xcode 构建和运行验收未执行 |
| 可选功能 | 95% | `PlayerController`、`PlayerBar`、最近/历史视图 | 需真实音频运行验收 |
| 验证与审核 | 75% | CoreChecks 通过；pbxproj/entitlements 通过；`05-review-report.md` | SwiftData 宏和沙盒重启需完整 Xcode |

## 要修复的问题

| 问题 | 严重级别 | 关联用户故事 | 修复方案 | 状态 |
| --- | --- | --- | --- | --- |
| 当前 `xcodebuild` 未连接完整 Xcode | P2 | US-101、US-303 | 使用 SwiftPM 验证源码；Xcode 工程保留人工验收说明 | 已缓解 |
| 源 MP3 移动后无法恢复 | P3 | US-104、US-205 | 章节菜单重新选择 MP3，刷新文件书签与 metadata | 已实现，待人工验收 |

## 具体案例

| 案例 | 输入或上下文 | 期望行为 | 验证方式 |
| --- | --- | --- | --- |
| 数字章节 | `Chapter 1/2/10.mp3` | 顺序 1、2、10 | 单测 |
| 文件夹书籍 | 文件夹内含子目录 MP3 | 递归导入为一本书 | 人工 |
| 无封面 | metadata 无 artwork | 渐变默认封面 | 人工 |
| 独立进度 | A 书 100 秒、B 书 20 秒 | 各自恢复对应位置 | 人工 |
| 文件移动 | 导入后在 Finder 移走 | 弹出不可访问错误；重新定位后恢复播放 | 人工 |
| 睡眠定时 | 设为本章结束 | 章节结束后暂停，不自动下一章 | 人工 |

## 兼容与回滚策略

- 最低 macOS 14；不向旧系统引入 Core Data 双实现。
- 模型首版只做加字段友好的 SwiftData schema，不写破坏性迁移。
- 应用不修改音频文件；删除书籍仅删除本地索引，因此数据回滚风险低。
- 如果 bookmark 解析失败，保留记录并提示重新定位，不静默删除。

## Gemini 开发交接

见 `04-gemini-handoff.md`。当前环境未调用 Gemini；用户明确要求本次直接开发，因此由 Codex 按同一交接范围实现。

## Codex 5.5 审核清单

- 实现是否匹配已确认的用户故事。
- 是否引入无关文件或计划外重构。
- 测试或人工验证是否覆盖具体案例。
- 已知问题是否修复，或明确结转。
- 完成度是否有证据支撑。
