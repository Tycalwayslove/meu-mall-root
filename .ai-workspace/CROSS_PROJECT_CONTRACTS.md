# 跨项目契约治理

## 目的

当前仓库只维护 `hybird-meumall` H5 C 端。H5 与 Java 后端、Java H5 版本管理、外部 App 运行环境发生交互时，必须先有 H5 侧消费契约或联调口径，再有实现。契约是 H5 消费外部能力时的事实源。

## 契约类型

- H5 与正式业务后端 API 契约。
- H5 与 Java H5 版本管理 API 契约。
- H5 与外部 App/WebView 运行环境的 H5 侧调用契约。
- H5 release manifest 契约。

以下历史契约不再作为新需求默认产物：

- H5 与旧 Python `server-meumall` API 契约。
- `server-meumall` 与 `admin-meumall` release API 契约。
- 旧 iOS `app-meumall` 实现契约。

## 契约存放

根级契约入口放在：

```text
.ai-workspace/contracts/
```

按契约类型分类：

```text
.ai-workspace/contracts/api/
.ai-workspace/contracts/native-bridge/   # 历史与外部运行环境契约，新需求默认不要求改 iOS
.ai-workspace/contracts/admin-config/    # 历史管理后台配置契约，当前管理后台已外部化到 Java
```

项目内细节可以继续放在各自 `docs/` 中，但必须与根级契约一致。

## 契约模板

每份契约至少包含：

```text
契约名称
提供方
消费方
适用环境
版本策略
请求格式
响应格式
错误格式
兼容性要求
测试方式
变更流程
回滚方式
```

## 变更流程

1. 在工作项中声明契约影响。
2. 当 H5 需要 Java 或外部运行环境配合时，创建或更新 H5 侧对接说明。
3. 更新根级契约或 H5 项目契约。
4. 记录外部接口负责人或联调结论。
5. 只实现 H5 消费方。
6. 增加或更新 H5 契约测试。
7. 记录验证结果。

## 兼容性规则

- 新增可选字段通常向后兼容。
- 删除字段、改字段类型、改错误格式通常不兼容。
- 不兼容变更必须有迁移计划。
- manifest schema 变更必须评估 H5 runtime、H5 发布脚本和 Java H5 版本管理接口，不再评估旧 server/app/admin 项目。

## H5 对接规则

- H5 调用 Java 后端接口前，必须有 API 契约或明确声明只使用临时 mock。
- H5 调用外部 App/WebView 能力前，只记录 H5 侧方法、参数、能力检测和 fallback；不得把 iOS 实现列为本仓库交付项。
- H5 消费 Java 管理台配置前，必须有配置 schema、默认值、上下线规则和异常兜底。
- 未经外部接口确认的契约不得作为已完成能力汇报，只能标记为待联调或待确认。
