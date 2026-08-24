# 具体开发方案：PDF 书本自动关联

## 开发方案

| 步骤 | 工作内容 | 负责人 | 文件或区域 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 1 | 规范化匹配与测试 | Codex（用户直接要求开发） | AudioShelfCore、CoreChecks | run_checks | 已完成 |
| 2 | 模型字段与 PDFService | Codex | Audiobook、Services | StoreChecks + build | 已完成 |
| 3 | 自动/批量关联 UI | Codex | Importer、LibraryView、BookDetailView | build + 人工 | 已完成实现 |
| 4 | 重建应用和审核 | Codex | dist、README、审核报告 | codesign/open | 已完成 |

## 完成度

| 项目 | 完成度 | 证据 | 备注 |
| --- | ---: | --- | --- |
| 规划 | 100% | `00`～`04` | 已完成 |
| 匹配与持久化 | 100% | CoreChecks、StoreChecks | 已完成 |
| UI 与交付 | 95% | release build、签名、启动验证 | 待 PDF 样本验收 |

## 要修复的问题

| 问题 | 严重级别 | 关联用户故事 | 修复方案 | 状态 |
| --- | --- | --- | --- | --- |
| 书籍无 PDF 字段 | P2 | US-202 | 增加可选文件名与 bookmark | 已修复 |
| 沙盒不能扫描 MP3 邻接目录 | P2 | US-302 | 增加多 PDF 文件选择器 | 已修复 |
| 无打开入口 | P2 | US-203、US-303 | PDFService + 详情按钮 | 已修复 |

## 具体案例

| 案例 | 输入或上下文 | 期望行为 | 验证方式 |
| --- | --- | --- | --- |
| 中文同名 | `三体.pdf` / `三体` | 匹配 | CoreChecks |
| 标点差异 | `The-Hobbit.pdf` / `The Hobbit` | 匹配 | CoreChecks |
| 不同书 | `三体2.pdf` / `三体` | 不匹配 | CoreChecks |
| 同名多书 | 两本标题相同 | 不自动关联 | 服务审核 |
| 重启 | 已有关联 | 文件名和书签恢复 | StoreChecks |

## 预期改动文件

- `AudioShelfCore/PDFMatching.swift`、CoreChecks、Tests
- `Audiobook.swift`、`PDFService.swift`、`LibraryImporter.swift`
- `LibraryView.swift`、`BookDetailView.swift`
- Xcode pbxproj、README 与本审核文档

## 验证命令

- `./scripts/run_checks.sh`
- `./scripts/build_app.sh`
- `codesign --verify --deep --strict dist/AudioShelf.app`
- `open dist/AudioShelf.app`

## 回滚或兼容策略

- PDF 字段均为 Optional，旧 JSON 可继续读取。
- 匹配只在唯一候选时写入；失败不影响音频书籍。
- PDF 保留原位且只读访问，移除关联不删除文件。

## Gemini 开发交接

见 `04-gemini-handoff.md`；用户直接要求当前 Codex 开发，因此由 Codex 接手。

## Codex 5.5 审核清单

- 是否只在唯一同名候选时关联。
- 是否保持旧 JSON 兼容和只读权限。
- 是否没有引入 PDF 内容解析或额外依赖。
- 是否重建并启动最终 `.app`。
