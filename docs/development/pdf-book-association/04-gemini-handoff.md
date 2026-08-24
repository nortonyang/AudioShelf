# Gemini 代码开发交接：PDF 书本自动关联

事实来源：本目录 `00`～`03`。

实现范围：规范化文件名匹配、Audiobook 可选 PDF 字段、PDF security-scoped bookmark、文件夹自动发现、已有资料库批量选择关联、详情页系统打开入口。

约束：不解析或复制 PDF；不引入第三方库；仅唯一同名候选自动关联；保持旧 JSON 兼容。

验收：CoreChecks/StoreChecks 通过；release 应用构建、签名和启动通过；无 PDF 的书不显示入口。

预期区域：Core、Models、Services、Library/Detail Views、pbxproj、README。

返回：变更文件、实现摘要、验证结果、阻塞点和偏离项。
