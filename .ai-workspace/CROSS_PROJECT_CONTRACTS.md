# 跨项目契约治理

## 目的

跨项目协作必须先有契约，再有实现。契约是提供方和消费方共同遵守的事实源。

## 契约类型

- H5 与 server API 契约。
- H5 与正式业务后端 API 契约。
- H5 与 Native Bridge 契约。
- H5 与管理后台配置契约。
- server 与 admin release API 契约。
- server、H5、app 共享的 manifest 契约。
- CI 与 server release 注册契约。

## 契约存放

根级契约入口放在：

```text
.ai-workspace/contracts/
```

按契约类型分类：

```text
.ai-workspace/contracts/api/
.ai-workspace/contracts/native-bridge/
.ai-workspace/contracts/admin-config/
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
2. 当 H5 需要其他项目配合时，创建或更新对接说明。
3. 更新根级契约或项目契约。
4. 对方确认契约和责任边界。
5. 实现提供方。
6. 实现消费方。
7. 增加或更新契约测试。
8. 记录验证结果。

## 兼容性规则

- 新增可选字段通常向后兼容。
- 删除字段、改字段类型、改错误格式通常不兼容。
- 不兼容变更必须有迁移计划。
- manifest schema 变更必须评估 H5、server、app、admin 和 CI。

## H5 对接规则

- H5 调用后端接口前，必须有 API 契约或明确声明只使用临时 mock。
- H5 调用原生能力前，必须有 Native Bridge 契约、能力检测和 fallback。
- H5 消费后台配置前，必须有配置 schema、默认值、上下线规则和异常兜底。
- 未经对方确认的契约不得作为已完成能力汇报，只能标记为待联调或待确认。
