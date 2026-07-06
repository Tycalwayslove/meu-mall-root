# H5 飞书发版通报与审核工作流

本文定义 MeuMall H5 发版后的飞书通报流程。目标是让发版消息有事实来源、有审核、有正式群通知，并能反向推动飞书排期和项目状态更新。

## 目标

每次 H5 发版后，不再依赖人工临时总结，而是由脚本从仓库和 release 记录生成发版通报草稿，先发送到审核人或审核群，审核通过后再发送到正式对接群。

## 当前结论

审核流程采用飞书审核版：

```text
生成发版通报草稿
  ↓
飞书机器人发送到审核人或审核群
  ↓
负责人在飞书中回复确认
  ↓
脚本检查审核回复并记录 approved
  ↓
飞书机器人发送到正式对接群
  ↓
后续同步飞书多维表格和知识库
```

第一阶段采用“company-feishu + 可追踪半自动审核”：

- 脚本负责生成通报、发送审核消息、检查审核群最近消息、发送正式群。
- 飞书消息发送者统一配置为 `company-feishu` 对应的 bot profile。
- 审核消息发送到包含你和 `company-feishu` 机器人的审核会话。
- 审核通过必须来自飞书审核消息或本地显式标记。
- 正式群发送必须单独执行 `send-approved`，避免误发。
- 暂不默认启用飞书事件订阅；后续如需机器人自动监听回复，再接入 `lark-event`。

## 通报类型

H5 飞书通报分为两类，不能混在一条消息里讲。

| 类型 | 使用时机 | 目的 |
| --- | --- | --- |
| 项目迭代总览 | 第一次向正式对接群同步，或阶段性重大复盘 | 告诉原生、后端、测试和管理台：项目到今天为止做了哪些体系、页面、发布和协作能力，后续还缺什么 |
| 单版本增量通报 | 每次 H5 发版后 | 只讲当前版本相对上个版本改了什么、影响哪里、验证结果和需要谁配合 |

首次正式同步必须先走“项目迭代总览”。总览发出后，后续版本通知默认使用单版本增量通报，避免每次都重复历史背景。

## 事实源

发版通报只能从事实源生成，禁止凭聊天记忆编写。

| 信息 | 来源 |
| --- | --- |
| 待审核 H5 版本号 | Jenkins 发版参数 `--version vX.Y.Z`，或 Java H5 版本管理列表中的目标 release；Jenkins 迁移后禁止再用 `hybird-meumall/package.json` 直接当作待审核版本 |
| 待审核 Git tag | Jenkins 发版参数 `--git-tag h5/vX.Y.Z`，或 Java H5 版本管理 `buildMeta.gitTag` |
| 待审核 Git commit | Java H5 版本管理目标 release 的 `buildMeta.gitCommit`；缺失时再用 `h5/vX.Y.Z` tag 反查 |
| 当前线上 active 版本 | Java H5 版本管理 active 接口：`GET {JAVA_H5_RELEASE_API_BASE_URL}/platform/h5Release/active` |
| 当前线上 active commit | Java H5 版本管理 list 接口中 `status=active` 且 `version=active.stableVersion` 的 `buildMeta.gitCommit`；active 接口只有 manifest 时必须再查 list 或用 `h5/{stableVersion}` tag 反查 |
| 版本 diff 范围 | `git log --oneline <activeCommit>..<targetCommit>` 和 `git diff --shortstat <activeCommit>..<targetCommit>` |
| 变更摘要 | `hybird-meumall/.ai/CHANGE_SUMMARY.md` |
| 验证记录 | `hybird-meumall/.ai/test-reports/` |
| release 注册记录 | `hybird-meumall/archives/releases/{version}/` |
| 旧 Python active manifest | 仅作为历史生产链路兜底：`https://hybird.aigcpop.com/api/h5/manifest/active?environment=prod`；Jenkins/Java H5 测试发版审核不得用它判断当前线上版本 |
| 页面和对接范围 | `.ai-workspace/product/page-inventory.md`、`.ai-workspace/integration-briefs/` |
| 排期计划 | 飞书多维表格，当前由 `.ai-workspace/H5_FEISHU_BASE_SCHEDULE_WORKFLOW.md` 约束 |

## 发审核前强制基准确认

单版本发版审核消息发送前，必须先确认“当前线上 active 版本”和“本次待审核版本”的版本号、Git tag、Git commit。这个步骤是硬门禁，不能用聊天上下文、上一次发版通知、`package.json version` 或最近 tag 代替。

Jenkins/Java 测试发版的标准取数顺序：

1. 读取当前外部 Jenkins 环境变量或 `H5_TEST_RELEASE_CONFIG` 指向的显式配置文件，例如 `H5_RELEASE_ENV`、`JAVA_H5_RELEASE_API_BASE_URL`、`JAVA_H5_RELEASE_REGISTER_API_BASE_URL`。
2. 查询 Java active：`GET {JAVA_H5_RELEASE_API_BASE_URL}/platform/h5Release/active`，得到当前 active 的 `stableVersion`、`rollbackVersion`、`assets.basePath`。
3. 查询 Java list：`GET {JAVA_H5_RELEASE_REGISTER_API_BASE_URL}/platform/h5Release/list`，找到：
   - `status=active` 且 `version=active.stableVersion` 的线上版本记录，读取 `buildMeta.gitCommit` 作为 `activeCommit`。
   - 本次待审核版本记录，读取 `buildMeta.gitCommit`、`buildMeta.gitTag`、`buildMeta.jenkinsBuildNumber`、`status` 作为 `targetCommit` 和发版元信息。
4. 如果 Java active 的 `data` 是 JSON 字符串，必须二次解析；如果 active 接口只有 manifest 不含 `buildMeta`，必须用 Java list 或 `h5/<stableVersion>` tag 反查 commit。
5. 生成改动统计必须使用 `activeCommit..targetCommit`，至少执行并记录：

```bash
git -C hybird-meumall log --oneline <activeCommit>..<targetCommit>
git -C hybird-meumall diff --shortstat <activeCommit>..<targetCommit>
```

6. 只有在审核消息里同时写清楚 `activeVersion / activeCommit / targetVersion / targetCommit / diff range` 后，才能发送到审核群。

如果本次待审核版本已经被 promote 成 active，不能再用“当前 active 等于目标版本”生成空 diff；必须改用 Java release 记录里的 `rollbackVersion` 或上一条 active/published release 的 `buildMeta.gitCommit` 作为基准，并在审核消息中说明“目标版本已 active，本次对比基准改用上一线上版本”。

禁止事项：

- 禁止在 Jenkins/Java 发版审核中使用旧 Python prod active manifest 判断当前线上版本；该接口可能仍返回历史版本，例如 `v1.0.14`。
- 禁止把 `hybird-meumall/package.json` 的 `version` 当作 Jenkins 生成的 H5 版本号；Jenkins 会按远程 tag 自动递增版本。
- 禁止只按 `h5/v*` 最近 tag 推断线上版本；线上 active 必须以 Java H5 版本管理为准。
- 禁止在无法确认 `activeCommit` 或 `targetCommit` 时发送审核消息；只能先发“取数失败/需补 token 或权限”的说明。

## 角色和群

| 对象 | 作用 | 配置字段 |
| --- | --- | --- |
| 审核人或审核群 | 接收待审核通报，回复确认 | `reviewUserId` 或 `reviewChatId` |
| 正式对接群 | 接收最终发版通报 | `targetChatId` |
| company-feishu | 发送审核消息和正式群消息 | `profile=company-feishu`、`sendAs=bot` |
| 操作人 | 执行生成、检查审核、正式发送命令 | 本地开发者或 Jenkins |

真实群 ID 和用户 open_id 不写入仓库，放在本地配置文件：

```text
.ai-workspace/feishu/h5-release-notification.local.json
```

仓库只保留模板：

```text
.ai-workspace/feishu/h5-release-notification.config.example.json
```

推荐本地配置：

```json
{
  "profile": "company-feishu",
  "sendAs": "bot",
  "approvalReadAs": "bot",
  "senderDisplayName": "company-feishu",
  "reviewMode": "bot_chat",
  "reviewChatId": "oc_xxx",
  "targetChatId": "oc_xxx",
  "releaseEnvironment": "test",
  "javaReleaseApiBaseUrl": "https://test.aigcpop.com:18088/apis",
  "javaReleaseRegisterApiBaseUrl": "https://test.aigcpop.com:18088/apis",
  "manifestUrl": ""
}
```

其中：

- `profile` 必须指向实际可发消息的 lark-cli profile，当前推荐 `company-feishu`。
- `sendAs` 是发送审核消息和正式群消息的身份，当前推荐 `bot`。
- `approvalReadAs` 是读取审核群消息的身份，当前推荐 `bot`；如果公司策略不允许 bot 读取群历史消息，可临时改为 `user` 并完成用户授权。
- `reviewChatId` 是你和 `company-feishu` 机器人所在的审核会话；可以是单独审核群，也可以是包含机器人的固定审核群。
- `targetChatId` 是正式发版通报要发送到的对接群。
- `releaseEnvironment`、`javaReleaseApiBaseUrl`、`javaReleaseRegisterApiBaseUrl` 是 Jenkins/Java 发版审核取数来源；必须指向 Java H5 版本管理系统。
- `manifestUrl` 只保留为历史兜底字段，新发版审核应留空或不配置，禁止指向旧 Python active manifest。
- `company-feishu` 机器人必须已经加入 `reviewChatId` 和 `targetChatId` 对应会话。

## 审核读取权限

脚本发送审核消息只需要消息发送权限，但自动识别审核回复需要读取审核群消息。当前脚本读取消息时会使用 `--no-reactions`，避免额外依赖消息表情读取权限。

自动审核识别至少需要飞书应用具备：

- `im:message:readonly`：读取消息。
- `im:chat:read`：读取群信息。

如果读取审核群消息时报 `230027 access denied`，通常表示以下情况之一：

- 应用缺少消息读取 scope。
- 应用可用范围不包含审核人或审核群成员。
- 租户策略限制机器人读取群历史消息。
- 使用 `approvalReadAs=user` 时，当前用户没有完成对应 scope 授权。

在权限补齐前，使用显式审核命令兜底：

```bash
pnpm run feishu:h5-overview-approve
pnpm run feishu:h5-release-approve
```

其中：

- `feishu:h5-overview-approve`：用于首次项目迭代总览。
- `feishu:h5-release-approve`：用于后续单版本发版通报。
- 这两个命令只标记审核通过，不会发送正式群消息。

## 消息结构

### 项目迭代总览审核消息

总览审核消息标题固定为：

```text
【待审核】MeuMall H5 项目迭代总览
```

必须包含：

- 当前 active 版本和线上入口。
- 到今天为止已经完成的项目协作机制。
- 到今天为止已经完成的 H5 工程架构和运行机制。
- 到今天为止已经完成或推进中的页面和业务能力。
- 跨端、发布、manifest、Jenkins、Nginx 等协作能力。
- 外部运行环境、Java/API 或配置平台、测试分别受到什么影响。
- 外部运行环境、Java/API 或配置平台、测试还需要补什么。
- 后续通知规则：以后每个版本只发增量变化。

审核说明必须明确提示审核人回复：

```text
同意 总览
```

或：

```text
approve overview
```

### 单版本审核消息

审核消息标题固定为：

```text
【待审核】MeuMall H5 发版通报
```

必须包含：

- 版本号。
- 环境。
- 发布状态。
- 版本 URL。
- active manifest 状态。
- 本次新增。
- 本次修复或调整。
- 影响范围。
- 验证结果。
- 风险和关注点。
- 审核操作说明。

审核说明必须明确提示审核人回复：

```text
同意 vX.Y.Z
```

或：

```text
approve vX.Y.Z
```

审核回复由你发出。`company-feishu` 不自行判断业务内容是否可发布；脚本只负责识别审核会话里是否出现对应版本的确认语。

### 正式群消息

单版本正式消息标题固定为：

```text
【MeuMall H5 发版通报】
```

正式群消息不展示审核操作说明，但要展示：

- 版本号。
- 状态。
- 线上地址。
- 本次改动。
- 影响范围。
- 验证结果。
- 需要原生、后端、测试关注的事项。
- 发送者为 `company-feishu`。

项目迭代总览正式消息标题固定为：

```text
【MeuMall H5 项目迭代总览】
```

正式群总览消息不展示审核操作说明，但要展示项目进展、影响范围、当前缺口和后续通知规则。

## CLI 命令

根目录统一入口：

```bash
pnpm run feishu:h5-release-notice -- <command>
```

## 与 H5 发版脚本的关系

H5 单版本发版脚本已经把“发送待审核通报”纳入标准流程：

```bash
pnpm run deploy:h5-version
```

默认行为：

```text
SEND_FEISHU_REVIEW=true
```

这意味着：H5 容器发布、Nginx 写入、smoke、release 注册完成后，脚本会自动执行：

```bash
pnpm run feishu:h5-release-notice -- request-review
```

它只会把待审核消息发送到审核群，不会发送正式对接群。正式对接群必须在审核确认后手动执行：

```bash
pnpm run feishu:h5-release-approve
pnpm run feishu:h5-release-notice -- send-approved
```

特殊开关：

```bash
SEND_FEISHU_REVIEW=false pnpm run deploy:h5-version
FEISHU_REVIEW_DRY_RUN=true pnpm run deploy:h5-version
```

### 首次项目总览通报

#### 生成总览预览

```bash
pnpm run feishu:h5-release-notice -- overview-preview
```

作用：

- 读取当前 H5 版本、active manifest 和本地配置。
- 生成“项目迭代总览”审核稿。
- 写入本地生成目录。
- 不发送飞书消息。

#### 发送总览审核消息

```bash
pnpm run feishu:h5-release-notice -- request-overview-review
```

作用：

- 生成项目总览审核消息。
- 发送到 `reviewChatId` 或 `reviewUserId`。
- 记录飞书消息返回值和审核状态。

#### 检查总览审核回复

```bash
pnpm run feishu:h5-release-notice -- check-overview-approval
```

作用：

- 读取审核群最近消息。
- 搜索 `同意 总览`、`确认 总览`、`approve overview` 等关键词。
- 命中后将总览状态更新为 `approved`。

#### 本地显式标记总览审核通过

推荐短命令：

```bash
pnpm run feishu:h5-overview-approve
```

完整命令：

```bash
pnpm run feishu:h5-release-notice -- mark-overview-approved --approved-by "唐游超" --approval-note "飞书审核群已确认"
```

#### 发送总览到正式群

```bash
pnpm run feishu:h5-release-notice -- send-overview-approved
```

### 后续单版本增量通报

#### 生成预览

```bash
pnpm run feishu:h5-release-notice -- preview
```

作用：

- 读取当前 H5 版本和仓库事实源。
- 生成审核通报 Markdown。
- 写入本地生成目录。
- 不发送飞书消息。

#### 发送审核消息

```bash
pnpm run feishu:h5-release-notice -- request-review
```

作用：

- 生成审核消息。
- 发送到 `reviewChatId` 或 `reviewUserId`。
- 记录飞书消息返回值和审核状态。

#### 检查审核回复

```bash
pnpm run feishu:h5-release-notice -- check-approval
```

作用：

- 读取审核群最近消息。
- 搜索 `同意 vX.Y.Z`、`确认 vX.Y.Z`、`approve vX.Y.Z` 等关键词。
- 命中后将本地状态更新为 `approved`。

#### 本地显式标记审核通过

当审核发生在飞书私聊、电话、会议或暂时无法读取审核群消息时，可以用本地显式标记：

推荐短命令：

```bash
pnpm run feishu:h5-release-approve
```

完整命令：

```bash
pnpm run feishu:h5-release-notice -- mark-approved --approved-by "张三" --approval-note "飞书审核群已确认"
```

该命令必须写明审核人和审核说明。

#### 发送正式群

```bash
pnpm run feishu:h5-release-notice -- send-approved
```

作用：

- 检查本地审核状态必须为 `approved`。
- 发送正式发版通报到 `targetChatId`。
- 记录正式消息返回值。

## 推荐人工流程

### 1. 发布 candidate 或 active

按 `.ai-workspace/H5_RELEASE_RUNBOOK.md` 完成 H5 发版。

### 2. 生成通报预览

```bash
pnpm run feishu:h5-release-notice -- preview
```

确认内容是否准确。

### 3. 发送审核消息

```bash
pnpm run feishu:h5-release-notice -- request-review
```

### 4. 在飞书审核群回复

示例：

```text
同意 v1.0.12
```

### 5. 检查审核状态

```bash
pnpm run feishu:h5-release-notice -- check-approval
```

### 6. 发送正式群通报

```bash
pnpm run feishu:h5-release-notice -- send-approved
```

## 后续自动化扩展

第二阶段可以继续接入：

- `lark-event`：监听审核群消息，自动识别同意回复。
- 飞书多维表格：发送正式通报后自动更新版本状态、测试状态、阻塞项。
- 飞书知识库：把每次发版摘要追加到发版记录文档。
- Jenkins：发布成功后自动执行 `request-review`，审核通过后由人工执行 `send-approved`。

## 验收标准

- 未配置飞书目标时，脚本只能预览，不能误发消息。
- 没有审核通过记录时，`send-approved` 必须失败。
- 审核消息和正式消息使用同一份事实源生成，避免两套口径。
- 发送结果必须写入本地状态文件，方便追溯。
- 本地配置文件不得提交到 Git。
