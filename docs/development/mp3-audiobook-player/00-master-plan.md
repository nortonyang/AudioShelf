# 总开发阶段文档：AudioShelf 原生 macOS 有声书播放器

> 后续状态：为支持仅使用 Command Line Tools 构建可双击应用，持久化已从 SwiftData 迁移为 Codable JSON。当前方案见 `../double-click-app/`。

## 目标

交付一个以 Swift、SwiftUI、AVFoundation 和 SwiftData 编写的原生 macOS 应用。用户可以导入本地 MP3 或文件夹，将文件夹作为一本书、MP3 作为章节浏览和播放；每本书分别保存播放章节和时间点；应用重启后仍可通过 security-scoped bookmark 访问原文件。

## 非目标

- 不做在线书城、账号、云同步、DRM、有声书下载或音频转码。
- 不修改或复制用户的 MP3，不编辑其 metadata。
- 首版不支持 M4B、受保护音频、跨设备同步或复杂播放队列。
- 不依赖第三方包，避免增加首次构建和维护成本。

## 当前证据

- 工作区初始为空，需要建立完整工程。
- 本机只有 Apple Command Line Tools，`swift` 可用，但 `xcodebuild` 当前无法连接完整 Xcode。
- 用户指定 Swift + SwiftUI + AVFoundation，并优先 SwiftData/Core Data。
- 目标功能包含资料库、自然排序、封面、章节、持久播放位置和沙盒重启访问。

## 假设

- 最低系统为 macOS 14，以直接采用 SwiftData；通过编译验证确认 SDK 可用。
- 导入文件夹等同于创建一本书，递归发现其中 MP3；导入单个 MP3 等同于单章节书。
- 多选同目录 MP3 时合并为一本书；来自不同目录时按父目录分组。
- 音频保留在原位置；应用只持久化索引、metadata、播放状态和授权书签。

## 风险

| 风险 | 影响 | 缓解方案 | 负责人 |
| --- | --- | --- | --- |
| security-scoped bookmark 失效或变陈旧 | 重启后无法播放 | 解析时刷新陈旧书签；播放期间持续持有访问范围 | Codex |
| SwiftData 与异步 metadata 加载互相跨 actor | 编译警告或数据竞争 | 导入服务限定 MainActor，只传递值类型 metadata | Codex |
| 大资料库 metadata 扫描耗时 | 导入界面短暂等待 | 顺序加载并显示导入状态；MVP 不做过早并发 | Codex |
| 当前机器没有完整 Xcode | 不能用 `xcodebuild` 验证 `.xcodeproj` | 用 SwiftPM 验证纯逻辑与所有非宏代码，静态检查工程；完整 App 列为 Xcode 人工门禁 | Codex |
| 原文件被移动或删除 | 某章节不可播放 | 显示明确错误并允许逐章重新定位，不删除资料库记录 | Codex |

## 阶段地图

| 阶段 | 目的 | 子任务 | 进入条件 | 退出条件 | 状态 |
| --- | --- | --- | --- | --- | --- |
| S1 | 固化边界与验收标准 | ST-101～ST-103 | 需求已知 | 规划、任务、方案和交接文档齐全 | 已完成 |
| S2 | 建立可编译原生工程与数据层 | ST-201～ST-203 | S1 完成 | SwiftData 模型、书签、导入与 metadata 可编译 | 已实现，待完整 Xcode 复核 |
| S3 | 实现播放与资料库 UI | ST-301～ST-304 | S2 完成 | MVP 用户路径完整 | 已实现，待沙盒运行验收 |
| S4 | 增强与质量验证 | ST-401～ST-403 | S3 完成 | 可选功能完成、测试通过、审核完成 | 已完成可执行范围 |

## 验证策略

- `swift build` 验证同一套应用源码可编译。
- `swift test` 验证自然排序和时间格式等纯逻辑。
- 检查 `.xcodeproj`、Info.plist 构建设置和 entitlements 是否覆盖应用沙盒与只读用户文件权限。
- 人工验收清单覆盖导入、搜索、排序、播放控制、独立进度、重启恢复、默认封面和 metadata 封面。
- 最终审核对照原子用户故事逐项记录通过、部分通过或需在完整 Xcode 中人工验证。
