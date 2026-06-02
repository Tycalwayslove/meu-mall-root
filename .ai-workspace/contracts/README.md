# 跨项目契约目录

本目录存放 MeuMall 跨项目契约入口。项目内更详细的 API 文档可以保留在各自 `docs/` 中，但不能与这里的根级契约冲突。

## 已建立契约

1. `hybrid-h5-runtime-contract.md`
2. `h5-cache-contract.md`
3. `native-bridge-lifecycle-contract.md`
4. `homepage-config-contract.md`
5. `api/`：H5 与后端业务 API 契约目录。
6. `native-bridge/`：H5 与原生 App Bridge 具体能力契约目录。
7. `admin-config/`：H5 与管理后台配置契约目录。

## 建议继续补齐

1. `manifest-contract.md`
2. `release-api-contract.md`
3. `h5-server-api-contract.md`
4. 具体业务页面的 API、Bridge、Admin Config 契约。

## 契约变更要求

涉及跨项目调用时，工作项必须先声明契约影响。实现完成后，契约、测试和任务记录必须同步更新。

H5 跨端需求的契约变更必须同时关联对接说明。未被对方确认的契约只能作为 draft 或 mock 开发依据，不能作为已完成能力验收。
