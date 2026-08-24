# Gemini 代码开发交接：AudioShelf 可双击应用

事实来源：`00-master-plan.md`～`03-implementation-plan.md`。

实现范围：AT-201～AT-303，将 SwiftData 替换为 Codable JSON Store，迁移现有服务/UI，并新增与 DsHarness 同类的 `.app` 打包脚本。

约束：不增加第三方依赖；不修改用户 MP3；保留 security-scoped bookmark；不扩大产品功能；仅替换持久化与交付路径。

验收标准：源码不再引用 SwiftData；核心检查通过；`dist/AudioShelf.app` 为已签名 Mach-O 应用；`open` 后进程存活。

预期区域：Models、Services、App、两个使用 ModelContext 的 Views、Package、pbxproj、Resources、scripts、README。

验证：运行 `scripts/run_checks.sh`、`scripts/build_app.sh`、plutil、codesign、file 和启动检查。

返回：变更文件、实现摘要、验证结果、阻塞点和偏离计划。
