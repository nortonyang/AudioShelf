# AudioShelf 图标、公开文档与 GitHub 发布：规划与审核

## 目标

为 AudioShelf 生成原创 macOS 应用图标并接入构建产物，重写适合 GitHub 的 README，清理仓库中的隐私/运行环境痕迹，创建新的私有 GitHub 仓库并推送经验证的源码。

## 当前证据

- 原占位图标已替换为原创书本与音频波形图标，图标包含 16px～1024px 表示并已接入两条构建路径。
- README 已更新为与 Codable JSON 存储实现一致的说明，并增加明确的本地隐私边界。
- 开发审核文档中的运行进程号和真实导入样本细节已改为中性验证描述。
- `.build/`、`dist/`、`logs/`、IDE 用户状态、常见音频/PDF 和本地资料库文件均已忽略。
- 两轮隐私扫描未发现邮箱、密钥、Token、私钥、私有 IP、个人用户名或用户目录绝对路径。
- GitHub CLI 已安装，发布前仍需完成 GitHub 登录授权。

## 范围与非目标

- 使用 ImageGen 生成无文字、原创、适合小尺寸识别的 1024px 图标底图。
- 本地生成标准 macOS `.icns` 尺寸集，更新 Info.plist 和打包脚本。
- 重写 README，包含功能、截图/图标、构建、使用、测试、隐私与限制。
- 清理源码及文档中的个人信息、真实样本描述、运行 PID；忽略构建、日志、IDE 用户状态和本地数据。
- 初始化 Git，创建新的私有 GitHub 仓库 `AudioShelf`（若同名已存在则使用清晰的可用名称），提交并推送源码。
- 不上传 `.build/`、`dist/`、日志、用户音频、PDF、资料库 JSON、bookmark 或播放历史。
- 本次不做 Developer ID 签名、公证、GitHub Release 二进制分发或公开仓库切换。

## 阶段与原子用户故事

| 阶段 | 原子任务 | 用户故事 | 验收标准 | 状态 |
| --- | --- | --- | --- | --- |
| S1 图标 | AT-101 | US-101：作为用户，我希望 AudioShelf 有独特且清晰的应用图标。 | Dock/Finder 不再显示通用图标；`.icns` 包含标准尺寸；无文字、无商标。 | 已完成 |
| S2 文档 | AT-201 | US-201：作为开发者，我希望 README 能快速说明用途、构建、隐私和限制。 | README 无过时 SwiftData 叙述；命令可执行；隐私边界明确。 | 已完成 |
| S3 隐私 | AT-301 | US-301：作为仓库所有者，我希望公开源码不携带个人数据。 | 两轮敏感信息扫描通过；Git 索引不含构建物、日志或用户内容。 | 已完成 |
| S4 发布 | AT-401 | US-401：作为仓库所有者，我希望源码进入一个新的 GitHub 仓库。 | 本地提交成功；远端仓库为私有；默认分支推送成功；远端状态干净。 | 进行中 |

## 具体开发方案

| 步骤 | 工作内容 | 负责人 | 文件/区域 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 1 | ImageGen 生成并检查图标底图 | Codex（用户直接要求开发） | `Resources/AppIcon-source.png` | 图像检查 | 已完成 |
| 2 | 生成 `.icns` 并接入 App bundle | Codex | `Resources/AppIcon.icns`、Info.plist、build script | iconutil、plutil、构建、Finder/Dock | 已完成 |
| 3 | 重写 README 和清理隐私痕迹 | Codex | README、`.gitignore`、开发文档 | rg 扫描、tracked-files 审核 | 已完成 |
| 4 | 完整测试、Git 初始化和本地提交 | Codex | 全仓 | checks、build、codesign、git status | 进行中 |
| 5 | GitHub 登录、建私有仓库并推送 | Codex + 用户授权 | GitHub | gh repo view、git remote/status | 进行中 |

## 风险与缓解

| 风险 | 影响 | 缓解方案 |
| --- | --- | --- |
| 生成图标在小尺寸不清楚 | Dock/Finder 识别差 | 使用强轮廓、少元素、无文字；检查 16px～1024px 尺寸。 |
| 隐私文件误进入首个提交 | 隐私泄露 | 在 `git add` 前后二次扫描，并审核 `git ls-files`。 |
| GitHub 同名仓库已存在 | 创建失败 | 先查询远端，再选择 `AudioShelf-macOS` 等无歧义名称。 |
| GitHub 未登录 | 无法创建或推送 | 所有本地工作先完成；只在发布步骤请求一次登录授权。 |

## 验证命令

- `iconutil --convert iconset Resources/AppIcon.icns`（反向解包验证）
- `./scripts/run_checks.sh`
- `./scripts/build_app.sh`
- `codesign --verify --deep --strict --verbose=2 dist/AudioShelf.app`
- `rg` 敏感信息扫描与 `git ls-files` 审核
- `gh repo view`、`git remote -v`、`git status --short --branch`

## Gemini 开发交接

用户明确要求当前 Codex 完成设计、文档和发布，因此由 Codex 实施。GitHub 仓库必须默认创建为私有；不得上传任何用户音频、PDF、library.json、bookmark、播放历史、构建缓存或日志。

## Codex 审核记录

- 状态：本地实现与验证完成，等待 GitHub 发布。
- 审核重点：图标清晰度、README 准确性、隐私扫描完整性和远端仓库可见性。
- 验证结果：完整检查、Release 构建、Info.plist、1024px 图标表示、ICNS 反向解包、严格签名和沙盒权限检查均通过；隐私扫描无发现。
