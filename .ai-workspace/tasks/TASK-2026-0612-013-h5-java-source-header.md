# TASK-2026-0612-013 H5 Java 后端来源 Header

## 状态

verified

## 目标

所有 H5 BFF 调 Java / mall 后端的请求都必须带 `source` 请求头，值为 `1`。Java 来源枚举为 `1-app`、`2-小程序`、`3-h5`；当前 H5 页面运行在 App WebView 内，因此按 App 来源传 `1`。

## 背景

Java 接口新增或要求读取请求头 `source`：

```java
/**
 * 订单来源 来源 1-app 2-小程序 3-h5
 */
private String source;
```

商品详情、首页、订单确认等 H5 BFF 请求都通过 `hybird-meumall/src/server/http/backend-client.ts` 统一出站到 Java 后端，因此该 header 应在 backend client 边界集中注入。

## 涉及项目

- `hybird-meumall`

## 范围

包含：

- Java / mall 后端请求统一注入 `source: "1"`。
- 调用方传入其它 `source` 值时，出站前统一覆盖为 `1`。
- Python 后端请求不携带 `source` header。
- 补充 backend client 回归测试。
- 更新 H5 HTTP 契约、API 规范和验证记录。

不包含：

- 修改 Java 后端接口。
- 修改 Python 后端接口。
- 新增浏览器端直接请求后端能力。

## 责任边界

`hybird-meumall`：

- 负责 BFF 到 Java / mall 后端请求的 header 注入。
- 保持浏览器端只请求 H5 BFF。

后端：

- 按 `source` header 读取来源枚举。

原生 App：

- 无新增参数依赖；当前 H5 承载于 App WebView，H5 BFF 固定传 App 来源。

## 契约影响

- 是否影响跨项目契约：是
- 契约文档路径：`.ai-workspace/contracts/api/h5-bff-http-auth-contract.md`
- 是否向后兼容：是，新增 header。
- 是否需要迁移：否。
- 是否需要灰度：随 H5 常规灰度。

## 验收标准

- [x] 所有 `backend: "java"` 请求出站 header 包含 `source: "1"`。
- [x] 调用方传入 `source: "2"` 等其它值时会被覆盖为 `source: "1"`。
- [x] `backend: "python"` 请求不携带 `source`。
- [x] 商品详情和首页真实 BFF 流程测试通过。
- [x] 契约和 API 文档记录来源枚举与当前取值。

## 验证命令

```bash
cd /Users/mac/person_code/meu-mall/hybird-meumall
pnpm exec vitest run src/server/http/backend-client.test.ts
pnpm exec vitest run src/server/http/backend-client.test.ts src/server/http/bff-context.test.ts src/features/product/product-real-flow.test.tsx src/features/home/home-real-api.test.ts
pnpm typecheck
pnpm lint
```

## 发布影响

- 是否需要发布：需要随 H5 常规发版。
- 发布项目：`hybird-meumall`
- 是否需要灰度：建议按 H5 常规灰度。
- 回滚目标：回滚到未统一注入 Java `source` header 的上一版 H5 SSR 产物。
- smoke check：查看 `[h5-bff-backend-call]` 中 Java 请求的 `requestHeaders.source` 为 `"1"`；Python 请求不出现 `source`。

## 风险和阻塞

- 若后端期望按浏览器 H5 来源传 `3`，需重新确认来源口径。目前用户已确认该 H5 放在 App 中，应传 `1`。

