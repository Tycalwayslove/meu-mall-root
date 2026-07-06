# 对接说明目录

本目录存放 H5 需求开发过程中面向 Java/API、外部运行环境、Java 配置平台和 CI/发布的对接说明。

## 使用规则

- 每个跨端 H5 需求创建一份 `BRIEF-YYYY-MMDD-NNN-xxx.md`。
- 对接说明必须关联一个工作项。
- 对接说明必须明确 H5 需要外部系统完成什么，以及完成到什么程度算可联调。
- 对接说明不是接口契约。接口、Bridge、Java 配置细节应写入 `.ai-workspace/contracts/` 下的对应契约。

## 模板

使用：

```text
.ai-workspace/templates/INTEGRATION_BRIEF.md
```
