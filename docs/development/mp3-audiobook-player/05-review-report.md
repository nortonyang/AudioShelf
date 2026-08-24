# Codex 5.5 审核报告：AudioShelf 原生 macOS 有声书播放器

> 本报告记录最初的 SwiftData 版本；当前 Codable JSON 版本及可双击应用审核见 `../double-click-app/05-review-report.md`。

## 审核范围

- 规划与验收文档 `00-master-plan.md`～`04-gemini-handoff.md`。
- `AudioShelf/` 下 SwiftData、AVFoundation、书签与 SwiftUI 实现。
- `AudioShelfCore/`、`AudioShelfTests/` 和 CoreChecks。
- `AudioShelf.xcodeproj/project.pbxproj`、entitlements、Package.swift 和 README。

## 问题发现

| 严重级别 | 问题 | 证据 | 必要动作 |
| --- | --- | --- | --- |
| P2 | 当前机器只有 Command Line Tools，缺少 Xcode 的 `SwiftDataMacros`，无法完成 App target 构建与沙盒运行 | `xcodebuild` 不可用；替代 SDK 构建到 SwiftData 模型时报告插件缺失 | 在安装完整 Xcode 的 Mac 上执行 README 的 `xcodebuild` 和人工验收 |
| P3 | 文件夹整体移动后需要逐章恢复访问 | 已增加章节级“重新定位此章节…”并刷新 security-scoped bookmark | 后续可增加整本书批量重新授权 |

未发现 P0/P1 级源码问题。审核中已修复两个实现问题：切换到不可访问章节时旧音频可能继续播放；多目录文件导入中途失败可能留下待保存的部分模型。

## 验收标准检查

| 用户故事 | 结果 | 证据 |
| --- | --- | --- |
| US-101 原生工程 | 部分通过 | pbxproj 与 entitlements 均通过 `plutil`；App target 待完整 Xcode |
| US-102 本地持久化 | 部分通过 | 三个 SwiftData `@Model`、ModelContainer、播放器强制/周期保存路径齐全；待重启运行 |
| US-103 导入与自然排序 | 部分通过 | 文件/文件夹导入与分组实现齐全；CoreChecks 的 1/2/10 排序通过；待真实 MP3 |
| US-104 书签与 metadata | 部分通过 | 只读书签创建、解析、陈旧刷新、访问范围生命周期和 artwork 读取均存在；待沙盒重启 |
| US-201 资料库浏览 | 部分通过 | 搜索、三种排序、资料库/最近/历史视图已实现；待 UI 运行 |
| US-202 图书与章节 | 部分通过 | 封面、详情、章节自然顺序和任意章节播放入口已实现；待 UI 运行 |
| US-203 播放控制 | 部分通过 | AVPlayer 播放/暂停/切章/拖动/倍速路径完整；待音频运行 |
| US-204 独立进度 | 部分通过 | `lastChapterID` 与 `playbackPosition` 按 Audiobook 保存，切书/暂停/非活跃均持久化；待重启运行 |
| US-205 封面与错误 | 部分通过 | artwork 优先、默认封面、缺失文件与保存失败警告已实现；待样本验证 |
| US-301 跳转与睡眠 | 部分通过 | -15/+30 秒与四种睡眠定时实现；待运行验证边界 |
| US-302 最近与历史 | 部分通过 | `lastPlayedAt` 排序及 PlaybackRecord 更新实现；待持久化查询 |
| US-303 验证与交付 | 部分通过 | README、CoreChecks、工程/权限检查和本报告完成；完整 App 构建待外部环境 |

## 验证结果

- `swift run AudioShelfCoreChecks`：通过，覆盖中文/英文数字自然排序与时间格式。
- `plutil -lint AudioShelf.xcodeproj/project.pbxproj`：通过。
- `plutil -lint AudioShelf/AudioShelf.entitlements`：通过；三项权限值均为 `true`。
- Xcode sources 完整性检查：App target 包含 `AudioShelf/` 与 `AudioShelfCore/` 的全部 16 个 Swift 源文件。
- 使用 macOS 15.4 SDK 尝试 `swift build`：所有非 SwiftData 宏代码未报告独立编译错误；构建最终因当前 Command Line Tools 未提供 `SwiftDataMacros` 而失败。
- `xcodebuild`：未执行，当前 active developer directory 不是完整 Xcode。

## 完成度更新

| 项目 | 更新前 | 更新后 | 证据 |
| --- | ---: | ---: | --- |
| 规划 | 0% | 100% | 00～04 文档 |
| MVP 实现 | 0% | 95% | Models、Services、Views、Xcode 工程 |
| 可选增强 | 0% | 95% | 跳转、睡眠、最近、历史 |
| 自动验证 | 0% | 75% | CoreChecks、Plist、工程完整性、非宏编译审查 |

## 剩余工作

- 在安装完整 Xcode 15+ 的 macOS 14+ 环境选择开发团队并构建 `AudioShelf` scheme。
- 使用真实 MP3 完成 README 中的导入、封面、播放控制、独立进度、退出重启，以及移动文件后的章节重新定位人工验收。
- 如果 Xcode 使用 Swift 6 严格并发模式，保持项目现有 Swift 5 language mode，或单独规划 Swift 6 并发迁移。
