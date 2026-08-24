# 原子任务与原子用户故事

## AT-101：确认无 Xcode 构建阻塞

用户故事 US-101：作为开发者，我希望识别 AudioShelf 与 DsHarness 构建方式的差异，以便选择可执行的迁移路径。

验收标准：Given 当前 Command Line Tools，When 构建 SwiftData App，Then 证据明确指向缺失 `SwiftDataMacros`。完成定义：阻塞及替代方案写入总计划。

## AT-201：Codable 数据模型

用户故事 US-201：作为用户，我希望书籍、章节、封面、书签、进度和历史仍被完整保存，以便重启后继续使用。

### 范围

- `Audiobook`、`Chapter`、`PlaybackRecord` 改为 Codable 引用模型。
- 删除业务未使用的章节反向引用，避免产生编码循环。

### 验收标准

- Given 带书签和封面的书籍，When JSON 编码再解码，Then 标识、数据、章节顺序和进度保持。
- Given 解码完成，When 播放章节，Then 播放器通过显式传入的书籍解析该章节。

### 完成定义

- 模型不再导入 SwiftData并可由 SwiftPM 编译。

## AT-202：LibraryStore

用户故事 US-202：作为用户，我希望资料库自动保存在本机，以便关闭并重新打开 `.app` 后仍可使用。

### 验收标准

- Given 资料库发生导入、删除或进度更新，When 保存，Then Application Support 中的 JSON 原子更新。
- Given JSON 无法解码，When 应用启动，Then 显示错误且不静默覆盖原文件。

### 完成定义

- Store 提供加载、保存、添加、删除、历史插入和变更通知。

## AT-203：业务路径迁移

用户故事 US-203：作为用户，我希望迁移持久化后所有现有操作保持可用，以便功能没有回退。

验收标准：Given LibraryStore，When 导入、播放、暂停、切章、重新定位或删除，Then 对应状态保存且界面刷新。

## AT-301：应用元数据

用户故事 US-301：作为 macOS 用户，我希望 Finder 将产物识别为 AudioShelf 应用，以便像普通应用一样打开。

验收标准：Given `dist/AudioShelf.app`，When `plutil` 和 `file` 检查，Then plist 合法且主程序为 Mach-O executable。

## AT-302：一键打包

用户故事 US-302：作为开发者，我希望运行一个脚本生成应用，以便无需 Xcode 重复构建。

验收标准：Given 当前 Command Line Tools，When 运行 `./scripts/build_app.sh`，Then release 编译、bundle 组装和 ad-hoc 签名全部成功。

## AT-303：双击启动

用户故事 US-303：作为用户，我希望双击 AudioShelf.app 后看到应用窗口，以便直接导入并播放 MP3。

验收标准：Given 已构建应用，When `open dist/AudioShelf.app`，Then AudioShelf 进程启动且不会立即退出。

## AT-401：完工审核

用户故事 US-401：作为维护者，我希望得到验证记录和已知限制，以便可靠接手。

完成定义：审核报告逐项记录构建、签名、启动和剩余人工音频验收。
