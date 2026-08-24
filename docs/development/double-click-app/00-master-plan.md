# 总开发阶段文档：AudioShelf 可双击应用迁移

## 目标

在仅安装 Apple Command Line Tools 的当前 Mac 上构建 `dist/AudioShelf.app`，用户可从 Finder 双击启动。应用继续支持资料库、章节、播放进度、历史和 security-scoped bookmark，并将这些数据持久化到 Application Support 下的 JSON 文件。

## 非目标

- 不改变播放器、导入、搜索、排序和睡眠定时的产品范围。
- 不增加第三方依赖、安装器、DMG、Developer ID 签名、公证或自动更新。
- 不迁移旧 SwiftData 数据库；当前环境从未成功构建并运行 SwiftData 版本，没有可验证的用户数据来源。
- 不删除 Xcode 工程；完整 Xcode 仍可作为另一种开发入口。

## 当前证据

- 当前只有 Command Line Tools，缺少 `SwiftDataMacros`，导致 `@Model` 无法编译。
- `DsHarness/scripts/build_app.sh` 使用 SwiftPM release 构建、手工组装 `.app` 和 ad-hoc 签名，已生成可启动应用。
- AudioShelf 只有源码和 `AudioShelf.xcodeproj`，没有 `dist/AudioShelf.app`。
- SwiftData 仅用于三类模型、查询、插入、删除和保存；现有数据字段均可由 Codable 表达。

## 假设

- 资料库规模适合单个 JSON 快照；通过原子写入避免半写文件。
- security-scoped bookmark 的 `Data` 可由 JSONEncoder 以 Base64 编码并恢复。
- ad-hoc 签名加现有 App Sandbox entitlements 可满足本机文件选择和后续授权访问。

## 风险

| 风险 | 影响 | 缓解方案 | 负责人 |
| --- | --- | --- | --- |
| JSON 损坏 | 资料库无法加载 | 原子写入；加载失败显示错误，不静默删除文件 | Codex |
| 嵌套引用变化不触发 SwiftUI | 进度或 metadata 不刷新 | `LibraryStore.save()` 统一发送变更通知 | Codex |
| 章节反向引用无法编码 | 循环引用或解码后无法定位书籍 | `Chapter.book` 不编码，加载后重新绑定 | Codex |
| 手工应用包权限不正确 | 文件选择或重启访问失败 | ad-hoc 签名时附加现有 entitlements，并做 codesign 校验 | Codex |
| Command Line Tools SDK 不匹配 | SwiftPM 构建失败 | 复用 DsHarness 的 MacOSX15 SDK 选择策略 | Codex |

## 阶段地图

| 阶段 | 目的 | 子任务 | 进入条件 | 退出条件 | 状态 |
| --- | --- | --- | --- | --- | --- |
| S1 | 固化迁移范围 | ST-101～ST-103 | 现状已核对 | 六类规划文档完成 | 已完成 |
| S2 | 替换持久化层 | ST-201～ST-203 | S1 完成 | App 源码不再依赖 SwiftData | 已完成 |
| S3 | 生成可双击应用 | ST-301～ST-303 | S2 完成 | `dist/AudioShelf.app` 可构建、签名和启动 | 已完成 |
| S4 | 审核与交付 | ST-401 | S3 完成 | 验收证据和剩余边界已记录 | 已完成 |

## 验证策略

- `swift run AudioShelfCoreChecks` 验证纯逻辑。
- `./scripts/build_app.sh` 必须成功并生成 Mach-O `.app`。
- `plutil`、`codesign --verify` 和 `file` 检查应用包。
- 使用 `open dist/AudioShelf.app` 启动，并确认进程存活。
- 静态检查源码中不再存在 `import SwiftData`、`@Model`、`@Query` 或 `ModelContext`。
