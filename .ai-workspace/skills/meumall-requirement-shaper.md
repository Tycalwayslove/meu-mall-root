# Skill：meumall-requirement-shaper

## 位置

```text
/Users/mac/.codex/skills/meumall-requirement-shaper
```

## 目标

将用户的自然语言需求转换为 MeuMall AI 工作流可消费的结构化需求描述。

它主要服务 H5 需求启动阶段：

- 把口语化需求转换成 AI 可执行需求。
- 判断影响 H5、后端、原生 App、管理后台、CI/发布的哪些部分。
- 输出工作项、对接说明和契约清单。
- 生成给后端、原生 App、管理后台的对外沟通语言。
- 判断需求当前应该是 `idea`、`draft` 还是 `ready`。

## 推荐调用方式

```text
使用 meumall-requirement-shaper：
<自然语言需求>

先不要实现代码。请先把需求转换成结构化描述，并判断需要哪些工作项、对接说明和契约。
```

如果需要直接落成仓库文档：

```text
使用 meumall-requirement-shaper：
<自然语言需求>

请进入 materialization mode，创建工作项、integration brief，并按影响范围创建契约草案。
```

## 输出要求

默认输出：

1. 我理解的原始需求。
2. AI 可执行需求描述。
3. 影响范围判断。
4. 需要创建的工作流产物。
5. 需要对后端、原生 App、管理后台确认的问题。
6. 建议状态。
7. 下一步。

## 关系

该 skill 与以下工作区文档配合使用：

- `.ai-workspace/H5_DEMAND_INTEGRATION_WORKFLOW.md`
- `.ai-workspace/templates/INTEGRATION_BRIEF.md`
- `.ai-workspace/templates/API_CONTRACT.md`
- `.ai-workspace/templates/NATIVE_BRIDGE_CONTRACT.md`
- `.ai-workspace/templates/ADMIN_CONFIG_CONTRACT.md`

