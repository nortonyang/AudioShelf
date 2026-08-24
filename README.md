<p align="center">
  <img src="Resources/AppIcon-source.png" width="144" alt="AudioShelf 应用图标">
</p>

<h1 align="center">AudioShelf</h1>

<p align="center">一款原生、私密、本地优先的 macOS 有声书播放器。</p>

AudioShelf 使用 SwiftUI 与 AVFoundation 构建，将散落在本地文件夹中的 MP3 整理成有声书资料库，并可按文件名自动关联对应的 PDF 书本。音频和 PDF 始终保留在原位置，应用只保存索引、访问授权与播放进度。

## 功能

- 导入单个、多个 MP3，或直接选择文件夹递归导入。
- 将文件夹整理为书籍、将 MP3 整理为章节，并使用 Finder 风格自然排序。
- 按书名、作者和章节搜索，支持名称、导入时间、最近播放排序。
- 保存每本书的当前章节与播放位置，重启后继续收听。
- 播放、暂停、切章、拖动进度、15 秒快退、30 秒快进与 0.75×～2× 倍速。
- 支持 15/30/60 分钟与“本章结束”睡眠定时。
- 优先读取 MP3 内嵌标题、专辑、作者与封面。
- 自动匹配同名 PDF，也可为已有资料库批量关联 PDF 文件或文件夹。
- 源文件移动后，可通过章节右键菜单重新定位。
- 从资料库移除书籍时只删除索引，不删除原始音频或 PDF。

## 隐私

AudioShelf 采用本地优先设计：

- 不包含网络请求、账号系统、遥测、广告或云同步。
- 不上传、不复制、不修改，也不删除用户的音频和 PDF 源文件。
- 资料库索引、播放历史、进度和 security-scoped bookmark 仅保存在 macOS 应用沙盒中。
- 文件访问权限为用户选择文件的只读权限；应用无法任意扫描未授权目录。
- 仓库忽略构建产物、日志、IDE 用户状态，以及常见音频、PDF 和本地资料库文件，避免误提交个人内容。

默认资料库位置：

```text
~/Library/Containers/app.audioshelf.desktop/Data/Library/Application Support/AudioShelf/library.json
```

## 系统要求

- macOS 14 Sonoma 或更高版本。
- 仅构建可双击运行的应用：Apple Command Line Tools。
- 使用 Xcode 工程开发：建议 Xcode 15 或更高版本。

## 构建并运行

```bash
./scripts/run_checks.sh
./scripts/build_app.sh
open dist/AudioShelf.app
```

构建脚本会在 `dist/AudioShelf.app` 生成本机 ad-hoc 签名的应用。之后可在 Finder 中直接双击打开。

## 使用方法

1. 打开 AudioShelf，点击“导入”。
2. 选择 MP3 文件或包含有声书的文件夹。
3. 如果有对应书本，将同名 PDF 放在书籍文件夹内即可自动匹配；也可以使用 PDF 批量关联入口。
4. 点击书籍进入详情页，选择章节开始播放。

文件夹示例：

```text
示例书名/
  示例书名.pdf
  第1章.mp3
  第2章.mp3
  第10章.mp3
```

## 使用 Xcode 开发

1. 打开 `AudioShelf.xcodeproj`。
2. 选择 `AudioShelf` target 和 **My Mac**。
3. 在 **Signing & Capabilities** 中选择自己的开发团队，并按需修改 bundle identifier。
4. 按 `⌘R` 运行。

工程启用了 App Sandbox、User Selected File（Read Only）和 app-scoped bookmarks。重启后的文件访问依赖已保存的 security-scoped bookmark，请勿改为直接访问任意绝对路径。

## 验证

```bash
./scripts/run_checks.sh
./scripts/build_app.sh
swift run AudioShelfCoreChecks
```

安装完整 Xcode 后还可以运行：

```bash
swift test
```

## 项目结构

```text
AudioShelf/             SwiftUI 应用、Codable 模型、导入与播放服务
AudioShelfCore/         自然排序、时间格式与 PDF 匹配逻辑
AudioShelfTests/        Swift Testing 用例
Tests/                  无测试框架依赖的核心与存储检查
Resources/              Info.plist 与原创应用图标资源
scripts/                检查和 .app 打包脚本
docs/development/       需求、实现与验收记录
```

## 当前边界

- 当前仅索引 MP3，不支持 M4B、DRM、在线内容、云同步或音频转码。
- 超大文件夹的首次 metadata 读取可能需要一些时间。
- 文件夹整体移动后，需要为受影响章节逐个重新定位。

应用图标为本项目原创资产，不包含第三方商标。
