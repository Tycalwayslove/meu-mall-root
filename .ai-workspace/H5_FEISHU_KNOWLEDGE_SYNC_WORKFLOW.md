# H5 飞书知识库同步工作流

飞书知识库空间：`新款app开发资料`
空间 ID：`7647093770363260152`
默认父节点：`前端知识库`
默认父节点链接：<https://v05ctaei9gn.feishu.cn/wiki/ZbjXwxtBEiXDjSkqtbRcfEpSnhh>
默认父节点 token：`ZbjXwxtBEiXDjSkqtbRcfEpSnhh`
默认飞书 profile：`company-feishu`

历史个人飞书知识空间 ID：`7647868639680433127`。历史临时公司知识空间 ID：`7648929271045540842`。后续 MeuMall 商城开发相关文档和知识库默认在公司飞书账号的 `前端知识库` 节点下读写；如需回写个人飞书，由用户另行明确说明。

首批已同步页面：

| 页面 | 飞书链接 | 仓库事实源 |
| --- | --- | --- |
| 00 MeuMall 项目总览与协作入口 | <https://v05ctaei9gn.feishu.cn/wiki/IGtzwfR1yi3F9Zkim4Ocno1gnAd> | `.ai-workspace/PROJECT_MAP.md`、`.ai-workspace/product/product-decisions.md`、`.ai-workspace/product/page-inventory.md` |
| 00 知识库使用说明与同步规则 | <https://v05ctaei9gn.feishu.cn/wiki/GRzDwu5CwiH3vEkb51Dc41atnzf> | `.ai-workspace/H5_FEISHU_KNOWLEDGE_SYNC_WORKFLOW.md` |
| 01 H5 与原生 App 路由跳转对接说明 | <https://v05ctaei9gn.feishu.cn/wiki/OJk1wa43PiR9lTkYs2YcW8llnmf> | `.ai-workspace/integration-briefs/BRIEF-2026-0605-h5-native-route-map.md` |
| 02 H5 页面清单与开发进度 | <https://v05ctaei9gn.feishu.cn/wiki/WgaqwTRRUitnRNkCtNPcOcDnnre> | `.ai-workspace/product/page-inventory.md`、`hybird-meumall/src/app` |
| 03 H5 BFF、鉴权与后端接口对接说明 | <https://v05ctaei9gn.feishu.cn/wiki/GPhdwjQ87iQAQskeS6lc9bMOnte> | `.ai-workspace/contracts/api/h5-bff-http-auth-contract.md`、`.ai-workspace/contracts/api/promotion-bff-mock-contract.md` |
| 04 H5 发版、版本切换与回滚流程 | <https://v05ctaei9gn.feishu.cn/wiki/HyBpwTbNUigKsOkO2Qgc2rjBnie> | `.ai-workspace/H5_RELEASE_RUNBOOK.md`、`.ai-workspace/H5_FEISHU_RELEASE_NOTIFICATION_WORKFLOW.md` |
| 05 H5 需求开发与跨团队协作流程 | <https://v05ctaei9gn.feishu.cn/wiki/RaXBw8iZZiDjGCkUH0WcYWaPnpf> | `.ai-workspace/H5_DEMAND_INTEGRATION_WORKFLOW.md`、`.ai-workspace/H5_PAGE_DEVELOPMENT_WORKFLOW.md` |
| 99 飞书知识库页面模板 | <https://v05ctaei9gn.feishu.cn/wiki/U6cXwVjNxi5KQVkSmE6cHkWPnVq> | `.ai-workspace/templates/FEISHU_KNOWLEDGE_PAGE.md` |

## 目标

本工作流用于把 MeuMall H5 需求、跨端对接、接口契约、发布流程和关键决策同步到公司飞书知识库，解决跨团队对接中信息分散、口径不一致、反复解释和新成员无法快速理解的问题。

飞书知识库面向人阅读和讨论；仓库文档面向 AI 恢复上下文、代码审查、契约验证和长期维护。两者必须保持同源。

## 核心原则

- 仓库是事实源，飞书是协作入口。
- 先更新仓库，再同步飞书。
- 飞书文档必须标明来源仓库文件和最后同步时间。
- 待确认内容必须显式标记，不得写成已确认结论。
- 飞书会议讨论产生的新结论，必须回写仓库后才算长期事实。
- 不覆盖飞书中未同步回仓库的人工批注；遇到冲突先列出差异，等待确认。

## 适用场景

只要 H5 需求涉及以下任一内容，建议同步飞书知识库：

- H5 与原生 App 的页面、路由、WebView、Bridge、登录态、支付、分享或返回规则。
- H5 与后端的接口、鉴权、BFF、错误码、缓存和联调规则。
- H5 与管理后台的配置项、素材、上下线、灰度和回滚规则。
- H5 发布、Jenkins、manifest、active 切换、回滚和线上验证流程。
- 需要给后端、原生 App、测试、产品或管理后台同事统一说明的流程。

## 推荐知识库结构

```text
MeuMall 项目协作知识库
├── 00 项目总览
│   ├── 项目介绍与端归属
│   ├── 当前业务边界
│   └── 常用环境与域名
├── 01 H5 与原生 App 对接
│   ├── H5 页面清单与开发进度
│   ├── H5 路由跳转总图
│   ├── WebView 容器策略说明
│   ├── A -> B 跳转交互明细
│   ├── Native Bridge 能力清单
│   └── 返回、关闭、切 Tab 规则
├── 02 H5 与后端接口对接
│   ├── 鉴权与 token 传递规则
│   ├── BFF 中间层说明
│   ├── Java/Python 服务调用规则
│   └── 接口契约清单
├── 03 管理后台与配置
│   ├── 首页配置项说明
│   ├── 活动配置项说明
│   ├── H5 版本配置说明
│   └── 配置上下线规则
├── 04 发布与回滚
│   ├── H5 版本号规则
│   ├── Jenkins 构建流程
│   ├── manifest 切 active 流程
│   ├── 回滚流程
│   └── 线上验证 checklist
├── 05 需求开发工作流
│   ├── H5 页面开发流程
│   ├── 跨端需求对接流程
│   ├── 工作项状态说明
│   └── 验收标准
└── 99 决策记录
    ├── 已确认产品事实
    ├── 已确认架构决策
    └── 待确认问题池
```

## 飞书文档标准结构

每篇飞书文档默认包含以下区块：

```text
1. 文档目的
2. 当前统一结论
3. 具体规则、表格或流程图
4. 各方责任边界
5. 待确认事项
6. 仓库事实源
7. 变更记录
```

对应模板见：

```text
.ai-workspace/templates/FEISHU_KNOWLEDGE_PAGE.md
```

## 仓库事实源映射

| 飞书文档类型 | 仓库事实源 |
| --- | --- |
| 项目总览 | `.ai-workspace/README.md`、`.ai-workspace/PROJECT_MAP.md`、相关子项目 `docs/00_PROJECT_OVERVIEW.md` |
| 页面清单 | `.ai-workspace/product/page-inventory.md`、H5 `src/app` 实际路由 |
| 产品决策 | `.ai-workspace/product/product-decisions.md`、`.ai-workspace/domain/meumall-business-model.md` |
| H5 页面开发流程 | `.ai-workspace/H5_PAGE_DEVELOPMENT_WORKFLOW.md`、H5 页面级开发规范 |
| 跨端对接流程 | `.ai-workspace/H5_DEMAND_INTEGRATION_WORKFLOW.md`、`integration-briefs/` |
| Native Bridge | `.ai-workspace/contracts/native-bridge/`、`hybird-meumall/docs/02_NATIVE_BRIDGE_SPEC.md` |
| API/BFF | `.ai-workspace/contracts/api/`、`hybird-meumall/docs/05_API_SPEC.md` |
| 发布回滚 | `.ai-workspace/RELEASE_GOVERNANCE.md`、`hybird-meumall/docs/03_RELEASE_SPEC.md`、`meumall-ci` 文档 |
| 架构决策 | 子项目 `docs/09_DECISIONS.md`、根级任务/对接说明 |

## 同步流程

### 1. 确认同步范围

同步前先明确：

- 要同步哪一类文档。
- 飞书知识库目标空间和目录。
- 是创建新文档，还是更新已有文档。
- 是否允许发布为团队可见。

### 2. 读取仓库事实源

AI 必须先读取：

```text
.ai-workspace/README.md
.ai-workspace/AI_OPERATING_MODEL.md
.ai-workspace/PROJECT_MAP.md
.ai-workspace/MEMORY_PROTOCOL.md
本工作流
相关契约、任务、对接说明和子项目文档
```

如果同步 H5 与原生 App 对接文档，还必须读取：

```text
.ai-workspace/product/page-inventory.md
.ai-workspace/product/product-decisions.md
.ai-workspace/domain/meumall-business-model.md
.ai-workspace/contracts/h5-native-route-contract.md
.ai-workspace/contracts/native-bridge/
hybird-meumall/docs/02_NATIVE_BRIDGE_SPEC.md
app-meumall/docs/03_WEBVIEW_RUNTIME.md
```

### 3. 生成仓库版 Markdown

先在仓库生成或更新 Markdown，例如：

```text
.ai-workspace/integration-briefs/BRIEF-YYYY-MMDD-NNN-xxx.md
.ai-workspace/contracts/native-bridge/xxx.md
.ai-workspace/knowledge/xxx.md              # 如后续需要专门目录再创建
```

仓库版 Markdown 必须能独立阅读，并作为飞书同步的输入。

### 4. 生成飞书版文档内容

飞书版可以在仓库版基础上做轻量整理：

- 标题更适合团队阅读。
- 表格、流程、责任边界更靠前。
- 技术细节可折叠或放后面。
- 明确“当前结论”和“待确认事项”。

### 5. 同步到飞书

当用户提供飞书知识库空间或页面 URL 后，AI 使用飞书知识库和云文档工具执行：

- 创建知识库节点。
- 创建或更新文档。
- 必要时移动到指定目录。
- 在文档末尾追加变更记录。

同步飞书前必须再次确认目标空间，避免写错知识库。

### 6. 回写同步记录

同步完成后，把飞书文档链接写回仓库对应文档：

```text
飞书知识库链接：
最后同步时间：
同步人：
同步摘要：
```

如果飞书同步失败，也要记录失败原因和下一步。

## AI 同步指令模板

### 创建或更新 H5 原生路由对接文档

```text
请按 H5 飞书知识库同步工作流，
基于当前仓库事实源生成/更新「H5 与原生 App 路由跳转对接说明」。

要求：
1. 先读取页面清单、产品决策、Native Bridge 契约和 H5 实际路由。
2. 输出仓库版 Markdown。
3. 生成飞书版结构。
4. 标记已确认、待确认和代码待修正内容。
5. 不直接同步飞书，等我提供知识库地址后再执行。
```

### 同步到飞书知识库

```text
请按 H5 飞书知识库同步工作流，
将 [仓库文档路径] 同步到这个飞书知识库目录：
[飞书知识库 URL]

要求：
1. 先确认目标知识库和目录。
2. 创建或更新对应文档。
3. 追加变更记录。
4. 把飞书链接回写到仓库文档。
```

## 变更记录规范

每篇飞书文档末尾保留：

| 日期 | 来源 | 变更摘要 | 状态 |
| --- | --- | --- | --- |
| YYYY-MM-DD | 仓库文档/会议/联调 | [摘要] | 已同步/待确认 |

状态说明：

- `已同步`：仓库和飞书一致。
- `待确认`：会议或讨论中提出，尚未回写仓库事实源。
- `冲突待处理`：飞书和仓库结论不一致。
- `废弃`：历史规则，不再适用。

## 冲突处理

当飞书和仓库不一致时，按以下顺序处理：

1. 列出冲突字段。
2. 标明仓库当前结论和飞书当前结论。
3. 询问负责人确认。
4. 确认后同时更新仓库事实源和飞书文档。
5. 在变更记录中写明原因。

禁止 AI 自行选择其中一个版本并覆盖另一个版本。

## 首批建议同步文档

| 优先级 | 文档 | 目标 |
| --- | --- | --- |
| P0 | H5 页面清单与开发进度 | 让各方知道 H5/App 各自有哪些页面 |
| P0 | H5 与原生 App 路由跳转对接说明 | 统一路由、WebView、返回、切 Tab 规则 |
| P0 | WebView 容器策略与返回规则 | 解释为什么新开 WebView、何时关闭和切 Tab |
| P1 | Native Bridge 能力清单 | 统一 Bridge 方法、参数、fallback |
| P1 | H5 版本发布、切 active 与回滚流程 | 统一 Jenkins、manifest、线上验证口径 |

## 待确认

- 公司飞书知识库空间 URL。
- 是否由 AI 直接创建知识库目录，还是只创建文档给人工移动。
- 飞书文档权限范围：项目组可见、研发可见，还是全公司可见。
- 飞书文档是否需要固定负责人和审核人。
