# H5 页面开发工作流

## 目标

本工作流用于每个 H5 页面进入正式开发前，把页面范围、路由、渲染策略、数据契约、mock、资产、状态和验收方式先固定下来，避免页面写到一半才发现 SSR/CSR、接口、原生边界或设计资产规则不一致。

## 适用范围

- 新增 H5 页面。
- 重写低保真页面为高保真页面。
- 页面依赖后端、BFF、Native Bridge、管理后台配置或 manifest 路由。
- 页面需要按 Figma 设计图实现。

## 标准流程

### 1. 页面盘点

先确认：

- 页面名称。
- H5 路由。
- 入口来源。
- 跳转目标。
- 端归属。
- 是否依赖登录态。
- 是否属于交易、用户私有、公共展示或配置型页面。

### 2. 设计来源

记录：

- Figma 文件 key。
- node id。
- 页面状态：默认态、空态、错误态、loading、不同等级或不同身份。
- 需要剥离的原生元素，例如底部 Tab、Home Indicator、原生状态栏。

Figma 临时图片 URL 不作为正式资产进入代码。首版可以使用占位组件，后续由本地资产或 CDN 资产替换。

### 3. 渲染策略

按以下规则选择：

| 场景 | 推荐策略 | 说明 |
| --- | --- | --- |
| 用户私有、收益、等级、权益、订单 | SSR dynamic | 服务端读取 Cookie token，避免 token 进入浏览器。 |
| 需要首屏快、但不敏感的配置页面 | SSR dynamic 或 ISR | 必须先确认缓存 TTL 和失效规则。 |
| 页面内 tab、筛选、排序、分页 | CSR 局部交互 | 首屏 SSR，局部状态客户端维护。 |
| 纯静态说明页 | SSG / static | 当前推广模块不适用。 |

默认原则：

- 登录态页面不使用 ISR。
- 交易和收益相关数据不缓存。
- 首屏关键数据优先 SSR。
- 浏览器端只请求 H5 BFF，不直接请求后端。

### 4. BFF 和 Mock

每个页面开发前必须明确：

- BFF route。
- server service。
- mock 数据位置。
- 数据类型。
- 错误码。
- loading / empty / error fallback。
- 后续替换真实后端的映射位置。

推荐结构：

```text
src/features/<domain>/
  api.ts
  types.ts
  mock/
  server/
  components/
  PAGE_DEVELOPMENT_GUIDE.md

src/app/api/bff/<domain>/
  <resource>/route.ts
```

### 5. 页面实现

实现顺序：

1. 类型和 mock。
2. server service。
3. BFF route。
4. 页面 shell 和布局组件。
5. loading / error / empty。
6. 客户端交互组件。
7. 测试。
8. 截图验收。

### 6. 验收

每个页面至少验证：

- 成功态。
- loading 态。
- error 态。
- empty 态。
- 未登录或 token 缺失。
- WebView 宽度适配。
- 文案不溢出。
- 资产缺失 fallback。
- `pnpm test`。
- `pnpm typecheck`。
- `pnpm build`。

### 7. 记录

实现完成后更新：

- 当前任务文件。
- 对接说明。
- 对应契约。
- `hybird-meumall/.ai/PROJECT_STATE.md`。
- `hybird-meumall/.ai/CHANGE_SUMMARY.md`。
- `hybird-meumall/docs/08_CHANGELOG.md`。
- 必要时更新 `hybird-meumall/docs/09_DECISIONS.md`。

## 禁止事项

- 禁止没有路由和数据契约就直接写页面。
- 禁止在页面组件中直接写后端 URL。
- 禁止浏览器端直接持有 Java / Python token 请求后端。
- 禁止把 Figma 临时图片 URL 当正式资产。
- 禁止 H5 重复绘制原生底部 Tab。
- 禁止只做成功态，不做 fallback。
