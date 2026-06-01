# 跨项目契约目录

本目录存放 MeuMall 跨项目契约入口。项目内更详细的 API 文档可以保留在各自 `docs/` 中，但不能与这里的根级契约冲突。

## 建议优先补齐

1. `manifest-contract.md`
2. `release-api-contract.md`
3. `native-bridge-contract.md`
4. `h5-server-api-contract.md`

## 契约变更要求

涉及跨项目调用时，工作项必须先声明契约影响。实现完成后，契约、测试和任务记录必须同步更新。
