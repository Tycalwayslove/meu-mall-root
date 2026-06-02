# H5 需求开发与跨端对接工作流

## 目标

本工作流用于后期以 `hybird-meumall` 为主要开发范围时，规范 H5 与后端、原生 App、管理后台、CI/发布之间的对接。它解决的问题不是“谁来写代码”，而是每次需求开始前先把依赖、契约、责任边界、联调方式和验收标准说清楚。

## 适用场景

只要 H5 需求涉及以下任一情况，必须使用本工作流：

- H5 需要新增或调整后端接口。
- H5 需要调用 Native Bridge 或依赖原生 App 页面跳转、登录、分享、支付、定位等能力。
- H5 页面展示依赖管理后台配置。
- H5 发布、灰度、回滚、manifest 或 SSR 部署链路受影响。
- 需求需要其他团队或其他项目配合。

只修改 H5 内部静态样式、纯展示文案或不影响契约的局部 UI，可只使用普通工作项。

## 工作产物

每个跨端 H5 需求至少产出以下文档：

```text
.ai-workspace/tasks/TASK-YYYY-MMDD-NNN-xxx.md
.ai-workspace/integration-briefs/BRIEF-YYYY-MMDD-NNN-xxx.md
.ai-workspace/contracts/api/xxx-api.md              # 如涉及后端接口
.ai-workspace/contracts/native-bridge/xxx-bridge.md # 如涉及原生能力
.ai-workspace/contracts/admin-config/xxx-config.md  # 如涉及后台配置
```

如果需求不涉及某类契约，在工作项和 brief 中明确写“无影响”，不要留空。

## 推荐使用方式

### 新需求启动

```text
请按 MeuMall H5 需求对接工作流接手这个需求：
<需求描述>

先不要实现代码。请先创建工作项、对接说明，并判断需要哪些 API、Native Bridge、Admin Config 契约。
```

### 进入实现

```text
请按 `.ai-workspace/tasks/TASK-xxx.md` 继续实现。
先检查任务是否 ready、brief 是否已确认、契约是否齐全。
如果条件不足，只补文档和风险，不要直接写业务代码。
```

### 生成对外说明

```text
请基于当前工作项和对接说明，生成给后端/原生 App/管理后台的对接输出包。
要求明确对方需要做什么、契约路径、联调方式和验收标准。
```

### 联调和验收

```text
请按当前工作项做联调验收。
必须检查 API/Bridge/Admin Config 契约是否一致，并把验证结果写回任务和 brief。
```

## 标准流程

### 1. 需求进入

AI 或开发者先读取根级工作区规则、产品页面盘点、业务模型和相关项目状态，然后回答三个问题：

- H5 要实现什么用户路径？
- 依赖哪些外部能力？
- 哪些内容必须由后端、原生 App、管理后台或 CI 完成？

此阶段只允许澄清和拆解，不直接实现。

### 2. 创建工作项

使用 `.ai-workspace/templates/TASK.md` 创建任务文件。工作项必须写清楚：

- H5 侧目标。
- 涉及页面和路由。
- 涉及项目。
- 范围和不包含。
- 责任边界。
- 契约影响。
- 验收标准。
- 验证命令。
- 发布影响。

如果跨项目契约还没定义，任务状态保持 `draft`，不能进入实现。

### 3. 创建对接说明

使用 `.ai-workspace/templates/INTEGRATION_BRIEF.md` 创建对接说明。它面向其他团队，必须能直接发给后端、原生 App 或后台同事确认。

对接说明必须包含：

- 背景问题。
- H5 页面行为。
- H5 需要对方做什么。
- 对方交付到什么程度算完成。
- Mock 和联调方式。
- H5 兜底策略。
- 验收口径。

对接说明不是 PRD，也不是接口文档；它是跨团队责任说明。

### 4. 建立或更新契约

按依赖类型选择模板：

- 后端 API：`.ai-workspace/templates/API_CONTRACT.md`
- Native Bridge：`.ai-workspace/templates/NATIVE_BRIDGE_CONTRACT.md`
- 管理后台配置：`.ai-workspace/templates/ADMIN_CONFIG_CONTRACT.md`

契约必须先于实现形成稳定草案。没有契约时，H5 只能基于 mock 或本地假数据做原型，不能声称完成。

### 5. 对方确认

将 integration brief 和相关契约发给对应负责人确认。确认结果必须回写到 brief：

- 已确认。
- 待确认。
- 被拒绝。
- 有争议。
- 暂时用 mock。

如果对方未确认，但 H5 需要先开发，必须在任务中标记风险，并明确当前只完成 H5 mock 阶段。

### 6. H5 基于 Mock 开发

H5 可以先基于 mock、fixture、schema 或本地临时接口实现页面。此阶段必须满足：

- Mock 数据结构与契约一致。
- API client 或 Bridge adapter 的调用边界已预留。
- 失败、loading、empty、未登录等状态已实现。
- 不把临时 mock 当成正式接口事实。

### 7. 联调

联调前检查：

- 后端接口地址、环境、鉴权方式已确认。
- App Bridge 方法名、参数、返回值、最低 App 版本已确认。
- 后台配置 schema、默认值、上下线规则已确认。
- H5 fallback 行为已确认。

联调中发现的契约变更必须先更新契约文档，再改代码。

### 8. 验收

验收必须覆盖四类结果：

- 产品路径：用户能完成目标路径。
- 契约结果：接口、Bridge、配置结构与文档一致。
- 工程结果：H5 不越界实现后端、原生或后台职责。
- 发布结果：测试环境、域名、manifest、Nginx、Jenkins 或回滚路径已验证。

### 9. 归档和对外说明

需求完成后，工作项和 brief 必须记录：

- 最终实现摘要。
- 对接方实际交付内容。
- 验证命令和结果。
- 未完成事项和风险。
- 可对外讲述的技术价值点。

如果该需求形成了重要架构优化，补充到后续的项目演进或优化记录中。

## 责任边界

### H5 负责

- 页面路由、交互、状态管理和展示。
- H5 API client、Bridge adapter、fallback。
- Mock 数据和契约消费方校验。
- 对接说明和 H5 侧验收。
- H5 构建、部署和 smoke check 配合。

### 后端负责

- 正式业务接口。
- 数据结构、错误码、鉴权、分页、缓存策略。
- 接口测试环境和 mock/fixture。
- 后端接口变更说明。

### 原生 App 负责

- WebView 容器能力。
- Native Bridge 方法实现。
- 登录、分享、支付、跳转等原生能力。
- 最低 App 版本和能力检测结果。
- Bridge 不可用时的兼容说明。

### 管理后台负责

- 配置项录入、编辑、上下线、排序和校验。
- 配置 schema 与默认值。
- 配置发布或灰度能力。
- 配置回滚或禁用方式。

### CI/部署负责

- H5/Admin/Server 构建部署。
- Jenkins job、测试服务器、Nginx、HTTPS、smoke check。
- 发布失败时的回滚路径。

## AI 执行要求

AI 每次接手跨端 H5 需求时必须按顺序执行：

1. 读取根级工作区规则。
2. 读取本工作流。
3. 读取当前工作项。
4. 判断是否需要 integration brief。
5. 判断是否需要 API、Bridge、Admin Config 契约。
6. 如果缺少必需文档，先创建文档并保持任务为 `draft`。
7. 只有任务达到 `ready`，才开始正式实现。

禁止事项：

- 禁止只口头描述对接需求，不落文档。
- 禁止把后端、原生或后台职责写进 H5 实现。
- 禁止契约未确认就声称需求完成。
- 禁止只完成 H5 mock 就标记 `verified`。
- 禁止跨项目接口变更不更新契约。
