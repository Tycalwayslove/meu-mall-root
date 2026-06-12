# TASK-2026-0611-006-H5 本地 token 兜底

## 状态

verified

## 目标

为本地 H5 开发环境增加 Java / Python token 兜底能力：当 `APP_ENV=local` 且 Cookie 缺失时，可以从本机 `.env.local` 读取临时 token 进行接口联调。

## 背景

真实接口联调需要 `mallToken` / `pythonToken`。本地开发时手动写浏览器 Cookie 不够方便，但正式架构仍必须保持 App 写 HttpOnly Cookie、BFF 转 Authorization 的安全模型。

## 涉及项目

- `hybird-meumall`

## 范围

包含：

- `cookie-auth` 支持 local-only env token fallback。
- `createBffRequestContext()` 支持注入 auth env，便于测试。
- 补充 Cookie 优先、local-only、生效环境的回归测试。
- 更新 `.env.example`、API 规范和 BFF 鉴权契约。

不包含：

- 不在 tracked profile 写入真实 token。
- 不改变测试/正式环境鉴权模型。
- 不把 token 暴露给浏览器端。

## 责任边界

H5：

- 本地开发可从 `.env.local` 读取 `H5_LOCAL_JAVA_TOKEN` 和 `H5_LOCAL_PYTHON_TOKEN`。
- Cookie 存在时永远优先使用 Cookie。
- 非 `APP_ENV=local` 时忽略本地 token fallback。

原生 App：

- 测试和正式环境仍负责写入 HttpOnly Cookie。

## 契约影响

- 是否影响跨项目契约：是，补充本地开发 fallback。
- 契约文档路径：`.ai-workspace/contracts/api/h5-bff-http-auth-contract.md`
- 是否向后兼容：是。
- 是否需要迁移：否。
- 是否需要灰度：否。

## 对接说明

- 对接说明路径：无新增。
- 需要确认角色：H5 开发、测试。
- 当前确认状态：本地开发 fallback 已实现，正式环境不启用。

## 对方责任

- 开发者只把真实 token 放入本机 `.env.local`。
- 测试和正式环境继续按 App Cookie 方式联调。

## Mock 和联调方式

本地 `.env.local` 示例：

```env
H5_LOCAL_JAVA_TOKEN=本地调试用 mallToken
H5_LOCAL_PYTHON_TOKEN=本地调试用 pythonToken
```

## 验收标准

- [x] `APP_ENV=local` 且 Cookie 缺失时使用 `H5_LOCAL_JAVA_TOKEN` / `H5_LOCAL_PYTHON_TOKEN`。
- [x] Cookie 存在时优先使用 Cookie。
- [x] `APP_ENV` 不是 `local` 时忽略本地 token fallback。
- [x] token 用法记录在 API 规范和契约中。
- [x] 目标测试、类型检查、lint 和根级工作流检查通过。

## 验证命令

```bash
cd hybird-meumall
pnpm test src/server/auth/cookie-auth.test.ts src/server/http/bff-context.test.ts src/server/http/backend-client.test.ts src/features/home/home-real-api.test.ts
pnpm typecheck
pnpm lint
cd ..
pnpm run check
```

## 发布影响

- 是否需要发布：需要随 H5 后续版本发布。
- 发布项目：`hybird-meumall`
- 是否影响 manifest：否。
- 是否需要灰度：否，本地开发能力。
- 回滚目标：移除 local token fallback。
- smoke check：本地 `.env.local` 配置 token 后访问 `/hybird/api/bff/home`。

## 风险和阻塞

- 真实 token 不能写入 `.env.example`、`config/env/h5.local.env` 或任何 tracked 文件。
- 如果线上误设 `APP_ENV=local`，会扩大本地 fallback 的作用范围；部署时必须保持测试/正式环境 `APP_ENV=test/prod`。

## 变更记录

| 日期 | 状态 | 说明 |
| --- | --- | --- |
| 2026-06-11 | verified | 已实现 local-only token fallback、补测试和文档。 |

## 验证记录

- `pnpm test src/server/auth/cookie-auth.test.ts src/server/http/bff-context.test.ts src/server/http/backend-client.test.ts src/features/home/home-real-api.test.ts`：通过，4 files / 19 tests。
- `pnpm typecheck`：通过。
- `pnpm lint`：通过，存在 4 条历史 `<img>` warning，无 error。
- 根目录 `pnpm run check`：通过。
